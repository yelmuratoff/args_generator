// ignore_for_file: deprecated_member_use
// NOTE: The CLI currently reuses generation logic built on top of the old
// analyzer element model (via `source_gen`). A full migration requires an
// Element2-based emitter.

import 'dart:io';
import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args_generator/src/generator.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

class ArgsGeneratorRunSummary {
  const ArgsGeneratorRunSummary({
    required this.writtenFiles,
    required this.deletedFiles,
    required this.skippedFiles,
    required this.errors,
  });

  final int writtenFiles;
  final int deletedFiles;
  final int skippedFiles;
  final int errors;
}

class ArgsGeneratorCliRunner {
  Future<ArgsGeneratorRunSummary> run({
    required Directory projectRoot,
    required List<String> includePaths,
    required String outputPath,
    required bool verbose,
    required bool clean,
  }) async {
    final absoluteIncludePaths = includePaths
        .map((p) => _toAbsolute(projectRoot, p))
        .where((p) => Directory(p).existsSync() || File(p).existsSync())
        .toList(growable: false);

    if (absoluteIncludePaths.isEmpty) {
      throw ArgumentError(
        'No valid paths provided. Tried: ${includePaths.join(', ')}',
      );
    }

    if (verbose) {
      stdout.writeln('Initializing analysis context...');
    }

    final collection = AnalysisContextCollection(
      includedPaths: absoluteIncludePaths,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final outputAbsPath = _toAbsolute(projectRoot, outputPath);
    final outputFile = File(outputAbsPath);

    var written = 0;
    var deleted = 0;
    var skipped = 0;
    var errors = 0;

    final emitter = PageArgsEmitter();
    final checker = TypeChecker.fromRuntime(GenerateArgs);

    final generatedParts = <String>[];
    final allImports = SplayTreeSet<String>();
    final librariesByUri = <String, LibraryElement>{};
    final annotatedUris = <String>{};

    if (verbose) {
      stdout.writeln('Analyzing source files...');
    }

    for (final context in collection.contexts) {
      final session = context.currentSession;
      final analyzedFiles = context.contextRoot
          .analyzedFiles()
          .where((p) => p.endsWith('.dart'))
          .where((p) => !_isDefinitelyGenerated(p))
          .toList(growable: false);

      for (final filePath in analyzedFiles) {
        // Fast prefilter to avoid resolving every file.
        final content = File(filePath).readAsStringSync();
        if (!content.contains('GenerateArgs')) {
          continue;
        }

        final parsed = session.getParsedUnit(filePath);
        if (parsed is! ParsedUnitResult) {
          continue;
        }

        final isPartOf = parsed.unit.directives.any(
          (d) => d is PartOfDirective,
        );
        if (isPartOf) {
          continue;
        }

        final resolved = await session.getResolvedLibrary(filePath);
        if (resolved is! ResolvedLibraryResult) {
          continue;
        }

        final libraryReader = LibraryReader(resolved.element);
        final annotated = libraryReader.annotatedWith(checker).toList();
        if (annotated.isEmpty) {
          continue;
        }

        if (verbose) {
          stdout.writeln('Processing: ${_prettyPath(projectRoot, filePath)}');
        }

        try {
          for (final item in annotated) {
            final element = item.element;
            if (element is! ClassElement) {
              continue;
            }
            final code = emitter.generateForClass(element);
            if (code.trim().isNotEmpty) {
              generatedParts.add(code);
            }
          }

          final uriStr = resolved.element.source.uri.toString();
          annotatedUris.add(uriStr);

          if (!uriStr.startsWith('dart:')) {
            allImports.add(uriStr);
            librariesByUri[uriStr] = resolved.element;
          }

          for (final imp in resolved.element.importedLibraries) {
            final impUri = imp.source.uri.toString();
            if (!impUri.startsWith('dart:')) {
              allImports.add(impUri);
              librariesByUri[impUri] = imp;
            }
          }
        } catch (e) {
          errors++;
          stderr.writeln(
            'args_generator: error while collecting for '
            '${_prettyPath(projectRoot, filePath)}: $e',
          );
        }
      }
    }

    if (generatedParts.isEmpty) {
      if (verbose) {
        stdout.writeln('No annotated classes found.');
      }
      if (shouldDeleteStaleOutput(
        clean: clean,
        hasAnnotatedElements: false,
        outputExists: outputFile.existsSync(),
      )) {
        if (verbose) {
          stdout.writeln('Deleting stale output file: $outputPath');
        }
        outputFile.deleteSync();
        deleted++;
      }
      return ArgsGeneratorRunSummary(
        writtenFiles: written,
        deletedFiles: deleted,
        skippedFiles: skipped,
        errors: errors,
      );
    }

    if (verbose) {
      stdout.writeln('Generating code and resolving imports...');
    }

    // Assign unique prefixes.
    final uriToPrefix = <String, String>{};
    var prefixCounter = 0;
    for (final uri in allImports) {
      var prefix = '_i${prefixCounter++}';
      while (uriToPrefix.containsValue(prefix)) {
        prefix = '_i${prefixCounter++}';
      }
      uriToPrefix[uri] = prefix;
    }

    // Extract all used names from generated code to optimize export traversal
    final usedNames = <String>{};
    final tokenRegex = RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*\b');
    for (final part in generatedParts) {
      usedNames.addAll(tokenRegex.allMatches(part).map((m) => m.group(0)!));
    }

    if (verbose) {
      stdout.writeln('Resolving top-level names for prefixing...');
    }

    // Collect top-level classes/enums to prefix.
    final classToPrefix = <String, String>{};
    final libraryExportsCache = <LibraryElement, Set<String>>{};

    for (final uri in allImports) {
      final prefix = uriToPrefix[uri]!;
      final library = librariesByUri[uri];
      if (library == null) {
        continue;
      }

      final exportedNames = _getAllExportedNames(library, libraryExportsCache);
      for (final name in exportedNames) {
        if (usedNames.contains(name)) {
          classToPrefix[name] = prefix;
        }
      }
    }

    // Replace class names with their respective prefixes.
    var body = generatedParts.join('\n\n');
    classToPrefix.forEach((name, prefix) {
      body = body.replaceAllMapped(
        RegExp('\\b$name\\b'),
        (_) => '$prefix.$name',
      );
    });

    final imports = allImports
        .map((uri) {
          final prefix = uriToPrefix[uri]!;
          return "import '$uri' as $prefix;";
        })
        .where((line) {
          final match = RegExp("import '(.*)' as (\\S+);").firstMatch(line);
          if (match == null) return false;
          final importUri = match.group(1)!;
          final importPrefix = match.group(2)!;
          return annotatedUris.contains(importUri) ||
              body.contains('$importPrefix.');
        })
        .toList(growable: false);

    // Keep all imports (fast + deterministic). The generated body uses prefixes.
    final output = [
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      '// ignore_for_file: type=lint, unused_import',
      '',
      ...imports,
      '',
      body,
      '',
    ].join('\n');

    final existing = outputFile.existsSync()
        ? outputFile.readAsStringSync()
        : null;
    if (existing == output) {
      if (verbose) {
        stdout.writeln('Output file is up to date.');
      }
      skipped++;
      return ArgsGeneratorRunSummary(
        writtenFiles: written,
        deletedFiles: deleted,
        skippedFiles: skipped,
        errors: errors,
      );
    }

    if (verbose) {
      stdout.writeln('Writing output to: $outputPath');
    }

    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(output);
    written++;

    return ArgsGeneratorRunSummary(
      writtenFiles: written,
      deletedFiles: deleted,
      skippedFiles: skipped,
      errors: errors,
    );
  }
}

bool _isDefinitelyGenerated(String filePath) {
  final name = _basename(filePath);
  return name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name.endsWith('.gr.dart') ||
      name.endsWith('.mocks.dart') ||
      name.endsWith('.args.g.dart');
}

@visibleForTesting
bool shouldDeleteStaleOutput({
  required bool clean,
  required bool hasAnnotatedElements,
  required bool outputExists,
}) {
  return clean && !hasAnnotatedElements && outputExists;
}

String _toAbsolute(Directory root, String inputPath) {
  final normalized = inputPath.trim();
  if (normalized.isEmpty) return root.path;
  final asFile = File(normalized);
  if (asFile.isAbsolute) return normalized;
  return '${root.path}${Platform.pathSeparator}$normalized';
}

String _prettyPath(Directory root, String absolutePath) {
  final rootPath = root.path;
  if (absolutePath.startsWith(rootPath)) {
    final rel = absolutePath.substring(rootPath.length);
    if (rel.startsWith(Platform.pathSeparator)) {
      return rel.substring(1);
    }
    return rel;
  }
  return absolutePath;
}

String _basename(String filePath) {
  final sep = Platform.pathSeparator;
  final idx = filePath.lastIndexOf(sep);
  return idx == -1 ? filePath : filePath.substring(idx + 1);
}

Set<String> _getAllExportedNames(
  LibraryElement lib,
  Map<LibraryElement, Set<String>> cache,
) {
  if (cache.containsKey(lib)) {
    return cache[lib]!;
  }

  final names = <String>{};
  cache[lib] = names; // Initialize with empty to handle cycles

  for (final el in lib.topLevelElements) {
    if (el is ClassElement || el is EnumElement) {
      final name = el.name;
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
  }

  for (final exported in lib.exportedLibraries) {
    final uri = exported.source.uri.toString();
    if (!uri.startsWith('dart:')) {
      names.addAll(_getAllExportedNames(exported, cache));
    }
  }

  return names;
}
