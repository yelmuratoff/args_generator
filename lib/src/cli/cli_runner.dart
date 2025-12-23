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

        final parsed = await Future.sync(() => session.getParsedUnit(filePath));
        if (parsed is! ParsedUnitResult) {
          continue;
        }

        final isPartOf = parsed.unit.directives.any(
          (d) => d is PartOfDirective,
        );
        if (isPartOf) {
          continue;
        }

        final resolved = await Future.sync(
          () => session.getResolvedLibrary(filePath),
        );
        if (resolved is! ResolvedLibraryResult) {
          continue;
        }

        final libraryReader = LibraryReader(resolved.element);
        final annotated = libraryReader.annotatedWith(checker).toList();
        if (annotated.isEmpty) {
          continue;
        }

        if (verbose) {
          stdout.writeln('Collecting: ${_prettyPath(projectRoot, filePath)}');
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
      if (shouldDeleteStaleOutput(
        clean: clean,
        hasAnnotatedElements: false,
        outputExists: outputFile.existsSync(),
      )) {
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

    // Collect top-level classes/enums to prefix.
    final classToPrefix = <String, String>{};
    for (final uri in allImports) {
      final prefix = uriToPrefix[uri]!;
      final library = librariesByUri[uri];
      if (library == null) {
        continue;
      }
      await _collectTopLevelNames(library, prefix, classToPrefix);
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
      skipped++;
      return ArgsGeneratorRunSummary(
        writtenFiles: written,
        deletedFiles: deleted,
        skippedFiles: skipped,
        errors: errors,
      );
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

Future<void> _collectTopLevelNames(
  LibraryElement library,
  String prefix,
  Map<String, String> classToPrefix, {
  Set<LibraryElement>? visited,
}) async {
  visited ??= <LibraryElement>{};
  if (!visited.add(library)) {
    return;
  }

  for (final el in library.topLevelElements) {
    if (el is ClassElement || el is EnumElement) {
      final name = el.name;
      if (name != null && name.isNotEmpty) {
        classToPrefix[name] = prefix;
      }
    }
  }

  for (final exported in library.exportedLibraries) {
    final uri = exported.source.uri.toString();
    if (!uri.startsWith('dart:')) {
      await _collectTopLevelNames(
        exported,
        prefix,
        classToPrefix,
        visited: visited,
      );
    }
  }
}
