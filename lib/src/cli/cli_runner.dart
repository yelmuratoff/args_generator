// ignore_for_file: deprecated_member_use
// NOTE: The CLI currently reuses generation logic built on top of the old
// analyzer element model (via `source_gen`). A full migration requires an
// Element2-based emitter.

import 'dart:io';
import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args_generator/src/generator.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

/// Cached regex patterns for performance.
final RegExp _tokenRegex = RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*\b');
final RegExp _importPattern = RegExp(r"import '(.*)' as (\S+);");

/// Maximum number of files to process in parallel.
const int _maxConcurrency = 4;

/// Result of processing a single file.
class _FileProcessResult {
  const _FileProcessResult({
    required this.generatedCode,
    required this.annotatedUri,
    required this.imports,
    required this.librariesByUri,
    this.error,
  });

  final List<String> generatedCode;
  final String? annotatedUri;
  final Set<String> imports;
  final Map<String, LibraryElement> librariesByUri;
  final String? error;

  bool get hasError => error != null;
}

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
    final totalStopwatch = Stopwatch()..start();

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

    final initStopwatch = Stopwatch()..start();
    final collection = AnalysisContextCollection(
      includedPaths: absoluteIncludePaths,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    initStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Context initialized in ${initStopwatch.elapsedMilliseconds}ms',
      );
    }

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

    final analysisStopwatch = Stopwatch()..start();
    var totalFiles = 0;
    var candidateCount = 0;

    for (final context in collection.contexts) {
      final session = context.currentSession;
      final analyzedFiles = context.contextRoot
          .analyzedFiles()
          .where((p) => p.endsWith('.dart'))
          .where((p) => !_isDefinitelyGenerated(p))
          .toList(growable: false);

      totalFiles += analyzedFiles.length;

      // Pre-filter files that might contain annotation (async reads in batches).
      final candidateFiles = <String>[];
      for (var i = 0; i < analyzedFiles.length; i += _maxConcurrency) {
        final batch = analyzedFiles.skip(i).take(_maxConcurrency);
        final readResults = await Future.wait(
          batch.map((filePath) async {
            final content = await File(filePath).readAsString();
            if (content.contains('GenerateArgs')) {
              return filePath;
            }
            return null;
          }),
        );
        for (final path in readResults) {
          if (path != null) candidateFiles.add(path);
        }
      }

      candidateCount += candidateFiles.length;

      // Process files in parallel batches.
      for (var i = 0; i < candidateFiles.length; i += _maxConcurrency) {
        final batch = candidateFiles.skip(i).take(_maxConcurrency);
        final batchResults = await Future.wait(
          batch.map(
            (filePath) => _processFile(
              session: session,
              filePath: filePath,
              emitter: emitter,
              checker: checker,
              projectRoot: projectRoot,
              verbose: verbose,
            ),
          ),
        );

        for (final result in batchResults) {
          if (result == null) continue;

          if (result.hasError) {
            errors++;
            stderr.writeln(result.error);
            continue;
          }

          generatedParts.addAll(result.generatedCode);
          if (result.annotatedUri != null) {
            annotatedUris.add(result.annotatedUri!);
          }
          allImports.addAll(result.imports);
          librariesByUri.addAll(result.librariesByUri);
        }
      }
    }

    analysisStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Scanned $totalFiles files, found $candidateCount candidates in ${analysisStopwatch.elapsedMilliseconds}ms',
      );
    }

    if (generatedParts.isEmpty) {
      totalStopwatch.stop();
      if (verbose) {
        stdout.writeln('No annotated classes found.');
        stdout.writeln('  Total time: ${totalStopwatch.elapsedMilliseconds}ms');
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

    final codegenStopwatch = Stopwatch()..start();

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
    for (final part in generatedParts) {
      usedNames.addAll(_tokenRegex.allMatches(part).map((m) => m.group(0)!));
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

    // Replace class names with their respective prefixes (single pass).
    var body = generatedParts.join('\n\n');
    if (classToPrefix.isNotEmpty) {
      final pattern = RegExp(r'\b(' + classToPrefix.keys.join('|') + r')\b');
      body = body.replaceAllMapped(
        pattern,
        (m) => '${classToPrefix[m.group(1)!]!}.${m.group(1)!}',
      );
    }

    final imports = allImports
        .map((uri) {
          final prefix = uriToPrefix[uri]!;
          return "import '$uri' as $prefix;";
        })
        .where((line) {
          final match = _importPattern.firstMatch(line);
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

    codegenStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Code generation completed in ${codegenStopwatch.elapsedMilliseconds}ms',
      );
      stdout.writeln('Writing output to: $outputPath');
    }

    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(output);
    written++;

    totalStopwatch.stop();

    if (verbose) {
      stdout.writeln('  Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    }

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

/// Processes a single file and returns the result or null if skipped.
Future<_FileProcessResult?> _processFile({
  required AnalysisSession session,
  required String filePath,
  required PageArgsEmitter emitter,
  required TypeChecker checker,
  required Directory projectRoot,
  required bool verbose,
}) async {
  try {
    final parsed = session.getParsedUnit(filePath);
    if (parsed is! ParsedUnitResult) {
      return null;
    }

    final isPartOf = parsed.unit.directives.any((d) => d is PartOfDirective);
    if (isPartOf) {
      return null;
    }

    // Early exit: check AST for @GenerateArgs annotation before expensive resolution
    final hasAnnotationInAst = parsed.unit.declarations.any((decl) {
      if (decl is! ClassDeclaration) return false;
      return decl.metadata.any((annotation) {
        final name = annotation.name.name;
        return name == 'GenerateArgs';
      });
    });
    if (!hasAnnotationInAst) {
      return null;
    }

    if (verbose) {
      stdout.writeln('Processing: ${_prettyPath(projectRoot, filePath)}');
    }

    final resolveStopwatch = Stopwatch()..start();
    // Use getResolvedUnit instead of getResolvedLibrary - faster for single file
    final resolved = await session.getResolvedUnit(filePath);
    resolveStopwatch.stop();
    if (verbose) {
      stdout.writeln('  Resolved in ${resolveStopwatch.elapsedMilliseconds}ms');
    }

    if (resolved is! ResolvedUnitResult) {
      return null;
    }

    final libraryElement = resolved.libraryElement;
    final libraryReader = LibraryReader(libraryElement);
    final annotated = libraryReader.annotatedWith(checker).toList();
    if (annotated.isEmpty) {
      return null;
    }

    final generatedCode = <String>[];
    final imports = <String>{};
    final librariesByUri = <String, LibraryElement>{};

    for (final item in annotated) {
      final element = item.element;
      if (element is! ClassElement) {
        continue;
      }
      final code = emitter.generateForClass(element);
      if (code.trim().isNotEmpty) {
        generatedCode.add(code);
      }
    }

    final uriStr = libraryElement.source.uri.toString();
    String? annotatedUri;

    if (!uriStr.startsWith('dart:')) {
      annotatedUri = uriStr;
      imports.add(uriStr);
      librariesByUri[uriStr] = libraryElement;
    }

    for (final imp in libraryElement.importedLibraries) {
      final impUri = imp.source.uri.toString();
      if (!impUri.startsWith('dart:')) {
        imports.add(impUri);
        librariesByUri[impUri] = imp;
      }
    }

    return _FileProcessResult(
      generatedCode: generatedCode,
      annotatedUri: annotatedUri,
      imports: imports,
      librariesByUri: librariesByUri,
    );
  } catch (e) {
    final prettyPath = _prettyPath(projectRoot, filePath);
    return _FileProcessResult(
      generatedCode: const [],
      annotatedUri: null,
      imports: const {},
      librariesByUri: const {},
      error: 'args_generator: error while processing $prettyPath: $e',
    );
  }
}
