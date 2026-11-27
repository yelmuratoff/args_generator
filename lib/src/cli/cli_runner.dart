import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args_generator/src/aggregated_output.dart';
import 'package:args_generator/src/generator.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

/// Reports a run that cannot start because of its input, such as an include
/// path that does not exist or a Dart SDK that cannot be found.
final class ArgsGeneratorException implements Exception {
  const ArgsGeneratorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _FileProcessResult {
  const _FileProcessResult({
    required this.classes,
    required this.annotatedUri,
    required this.librariesByUri,
  });

  final List<GeneratedArgsClass> classes;
  final String annotatedUri;
  final Map<String, LibraryElement> librariesByUri;
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
  /// Generates the aggregated output for the annotated pages under
  /// [includePaths].
  ///
  /// When any library fails to generate, the output file is neither written
  /// nor deleted and the failures are counted in
  /// [ArgsGeneratorRunSummary.errors]. [sdkPath] overrides the Dart SDK the
  /// analyzer resolves against.
  ///
  /// Throws [ArgsGeneratorException] if none of [includePaths] exists or
  /// [sdkPath] is not a Dart SDK.
  Future<ArgsGeneratorRunSummary> run({
    required Directory projectRoot,
    required List<String> includePaths,
    required String outputPath,
    required bool verbose,
    required bool clean,
    String? sdkPath,
  }) async {
    final totalStopwatch = Stopwatch()..start();

    final absoluteIncludePaths = includePaths
        .map((p) => _toAbsolute(projectRoot, p))
        .where((p) => Directory(p).existsSync() || File(p).existsSync())
        .toList(growable: false);

    if (absoluteIncludePaths.isEmpty) {
      throw ArgsGeneratorException(
        'No valid paths provided. Tried: ${includePaths.join(', ')}',
      );
    }
    if (sdkPath != null && !_isDartSdk(sdkPath)) {
      throw ArgsGeneratorException('Not a Dart SDK: $sdkPath');
    }

    if (verbose) {
      stdout.writeln('Initializing analysis context...');
    }

    final initStopwatch = Stopwatch()..start();
    final collection = AnalysisContextCollection(
      includedPaths: absoluteIncludePaths,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
      sdkPath: sdkPath,
    );
    initStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Context initialized in ${initStopwatch.elapsedMilliseconds}ms',
      );
    }

    final outputFile = File(_toAbsolute(projectRoot, outputPath));
    final emitter = PageArgsEmitter();

    final classes = <GeneratedArgsClass>[];
    final librariesByUri = <String, LibraryElement>{};
    final annotatedUris = <String>{};
    var errors = 0;

    if (verbose) {
      stdout.writeln('Analyzing source files...');
    }

    final analysisStopwatch = Stopwatch()..start();
    var totalFiles = 0;
    var candidateCount = 0;

    for (final context in collection.contexts) {
      final session = context.currentSession;
      final dartFiles = [
        for (final path in context.contextRoot.analyzedFiles())
          if (path.endsWith('.dart') && !_isDefinitelyGenerated(path)) path,
      ];
      final candidateFiles = [
        for (final path in dartFiles)
          if (File(path).readAsStringSync().contains('GenerateArgs')) path,
      ];
      totalFiles += dartFiles.length;
      candidateCount += candidateFiles.length;

      for (final filePath in candidateFiles) {
        try {
          final result = await _processFile(
            session: session,
            filePath: filePath,
            emitter: emitter,
            projectRoot: projectRoot,
            verbose: verbose,
          );
          if (result == null) continue;
          classes.addAll(result.classes);
          annotatedUris.add(result.annotatedUri);
          librariesByUri.addAll(result.librariesByUri);
        } on InvalidGenerationSourceError catch (e) {
          errors++;
          _reportFailure(projectRoot, filePath, e);
        } on Exception catch (e) {
          errors++;
          _reportFailure(projectRoot, filePath, e);
        }
      }
    }

    analysisStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Scanned $totalFiles files, found $candidateCount candidates in '
        '${analysisStopwatch.elapsedMilliseconds}ms',
      );
    }

    if (errors > 0) {
      stderr.writeln(
        'args_generator: left $outputPath unchanged because $errors '
        '${errors == 1 ? 'library' : 'libraries'} failed to generate.',
      );
      return ArgsGeneratorRunSummary(
        writtenFiles: 0,
        deletedFiles: 0,
        skippedFiles: 0,
        errors: errors,
      );
    }

    if (classes.isEmpty) {
      if (verbose) {
        stdout.writeln('No annotated classes found.');
      }
      var deleted = 0;
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
      _reportTotal(verbose, totalStopwatch);
      return ArgsGeneratorRunSummary(
        writtenFiles: 0,
        deletedFiles: deleted,
        skippedFiles: 0,
        errors: 0,
      );
    }

    if (verbose) {
      stdout.writeln('Generating code and resolving imports...');
    }

    final codegenStopwatch = Stopwatch()..start();
    final output = assembleAggregatedOutput(
      classes: classes,
      libraries: librariesByUri,
      annotatedUris: annotatedUris,
    );
    codegenStopwatch.stop();

    if (verbose) {
      stdout.writeln(
        '  Code generation completed in '
        '${codegenStopwatch.elapsedMilliseconds}ms',
      );
    }

    final existing = outputFile.existsSync()
        ? outputFile.readAsStringSync()
        : null;
    if (existing == output) {
      if (verbose) {
        stdout.writeln('Output file is up to date.');
      }
      _reportTotal(verbose, totalStopwatch);
      return const ArgsGeneratorRunSummary(
        writtenFiles: 0,
        deletedFiles: 0,
        skippedFiles: 1,
        errors: 0,
      );
    }

    if (verbose) {
      stdout.writeln('Writing output to: $outputPath');
    }
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(output);
    _reportTotal(verbose, totalStopwatch);

    return const ArgsGeneratorRunSummary(
      writtenFiles: 1,
      deletedFiles: 0,
      skippedFiles: 0,
      errors: 0,
    );
  }
}

/// The Dart SDK the analyzer should resolve against, or `null` when the
/// running executable sits inside one.
///
/// A natively compiled CLI (`dart compile exe`, `dart install`) runs outside
/// the SDK, so the SDK is looked up from `FLUTTER_ROOT`, then from the `dart`
/// executable on `PATH`.
///
/// Throws [ArgsGeneratorException] if no SDK is found.
String? detectSdkPath({
  String? resolvedExecutable,
  Map<String, String>? environment,
}) {
  final executable = resolvedExecutable ?? Platform.resolvedExecutable;
  final env = environment ?? Platform.environment;

  if (_isDartSdk(File(executable).parent.parent.path)) return null;

  final flutterRoot = env['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final flutterSdk = _flutterDartSdk(flutterRoot);
    if (_isDartSdk(flutterSdk)) return flutterSdk;
  }

  final pathSeparator = Platform.isWindows ? ';' : ':';
  final dartNames = Platform.isWindows ? ['dart.exe', 'dart.bat'] : ['dart'];
  for (final directory in (env['PATH'] ?? '').split(pathSeparator)) {
    if (directory.isEmpty) continue;
    for (final dartName in dartNames) {
      final dart = File('$directory${Platform.pathSeparator}$dartName');
      if (!dart.existsSync()) continue;
      final binDirectory = File(dart.resolveSymbolicLinksSync()).parent;
      if (_isDartSdk(binDirectory.parent.path)) {
        return binDirectory.parent.path;
      }
      final flutterSdk = _flutterDartSdk(binDirectory.parent.path);
      if (_isDartSdk(flutterSdk)) return flutterSdk;
    }
  }

  throw const ArgsGeneratorException(
    'Could not find the Dart SDK. Pass --sdk-path or set FLUTTER_ROOT.',
  );
}

String _flutterDartSdk(String flutterRoot) {
  final sep = Platform.pathSeparator;
  return '$flutterRoot${sep}bin${sep}cache${sep}dart-sdk';
}

bool _isDartSdk(String path) {
  final sep = Platform.pathSeparator;
  return File('$path${sep}version').existsSync() &&
      Directory('$path${sep}lib${sep}_internal').existsSync();
}

void _reportFailure(Directory projectRoot, String filePath, Object error) {
  stderr.writeln(
    'args_generator: error while processing '
    '${_prettyPath(projectRoot, filePath)}: $error',
  );
}

void _reportTotal(bool verbose, Stopwatch totalStopwatch) {
  if (verbose) {
    stdout.writeln('  Total time: ${totalStopwatch.elapsedMilliseconds}ms');
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

Future<_FileProcessResult?> _processFile({
  required AnalysisSession session,
  required String filePath,
  required PageArgsEmitter emitter,
  required Directory projectRoot,
  required bool verbose,
}) async {
  final parsed = session.getParsedUnit(filePath);
  if (parsed is! ParsedUnitResult) {
    return null;
  }

  final isPartOf = parsed.unit.directives.any((d) => d is PartOfDirective);
  if (isPartOf) {
    return null;
  }

  final hasAnnotationInAst = parsed.unit.declarations.any((decl) {
    if (decl is! ClassDeclaration) return false;
    return decl.metadata.any(
      (annotation) => annotation.name.name == 'GenerateArgs',
    );
  });
  if (!hasAnnotationInAst) {
    return null;
  }

  if (verbose) {
    stdout.writeln('Processing: ${_prettyPath(projectRoot, filePath)}');
  }

  final resolveStopwatch = Stopwatch()..start();
  final resolved = await session.getResolvedUnit(filePath);
  resolveStopwatch.stop();
  if (verbose) {
    stdout.writeln('  Resolved in ${resolveStopwatch.elapsedMilliseconds}ms');
  }

  if (resolved is! ResolvedUnitResult) {
    return null;
  }

  final libraryElement = resolved.libraryElement;
  final uri = libraryElement.uri.toString();
  final classes = <GeneratedArgsClass>[
    for (final item in LibraryReader(
      libraryElement,
    ).annotatedWith(generateArgsChecker))
      if (item.element case final ClassElement element)
        (
          libraryUri: uri,
          className: PageArgsEmitter.argsClassNameOf(element),
          code: emitter.generateForClass(element),
        ),
  ];
  if (classes.isEmpty) {
    return null;
  }

  final librariesByUri = <String, LibraryElement>{uri: libraryElement};
  for (final fragment in libraryElement.fragments) {
    for (final imported in fragment.importedLibraries) {
      if (!imported.uri.isScheme('dart')) {
        librariesByUri[imported.uri.toString()] = imported;
      }
    }
  }

  return _FileProcessResult(
    classes: classes,
    annotatedUri: uri,
    librariesByUri: librariesByUri,
  );
}
