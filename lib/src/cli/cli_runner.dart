import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';
import 'package:args_generator/src/generator.dart';
import 'package:args_generator_annotations/args_annotations.dart';
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

    var written = 0;
    var deleted = 0;
    var skipped = 0;
    var errors = 0;

    final emitter = PageArgsEmitter();
    final checker = TypeChecker.fromRuntime(GenerateArgs);

    for (final context in collection.contexts) {
      final session = context.currentSession;
      final analyzedFiles = context.contextRoot
          .analyzedFiles()
          .where((p) => p.endsWith('.dart'))
          .where((p) => !_isDefinitelyGenerated(p))
          .toList(growable: false);

      for (final filePath in analyzedFiles) {
        final parsed = session.getParsedUnit(filePath);
        if (parsed is! ParsedUnitResult) {
          continue;
        }

        final isPartOf =
            parsed.unit.directives.any((d) => d is PartOfDirective);
        if (isPartOf) {
          continue;
        }

        final resolved = await session.getResolvedLibrary(filePath);
        if (resolved is! ResolvedLibraryResult) {
          continue;
        }

        final libraryReader = LibraryReader(resolved.element);
        final annotated = libraryReader.annotatedWith(checker).toList();
        final outputPath = argsOutputForLibrary(filePath);

        if (annotated.isEmpty) {
          if (clean) {
            final outFile = File(outputPath);
            if (outFile.existsSync()) {
              outFile.deleteSync();
              deleted++;
              if (verbose) {
                stdout.writeln(
                  'Deleted stale: ${_prettyPath(projectRoot, outputPath)}',
                );
              }
            }
          }
          continue;
        }

        if (verbose) {
          stdout
              .writeln('Generating for: ${_prettyPath(projectRoot, filePath)}');
        }

        try {
          final generated = StringBuffer();
          for (final item in annotated) {
            final element = item.element;
            if (element is! ClassElement) {
              continue;
            }

            final code = emitter.generateForClass(element);
            if (code.trim().isEmpty) {
              continue;
            }
            generated.writeln(code.trimRight());
            generated.writeln();
          }

          final libraryBasename = _basename(filePath);
          final output = wrapAsPartForCli(
            partOfUri: libraryBasename,
            body: generated.toString().trimRight(),
          );

          final outFile = File(outputPath);
          final existing =
              outFile.existsSync() ? outFile.readAsStringSync() : null;

          if (existing == output) {
            skipped++;
            continue;
          }

          outFile.parent.createSync(recursive: true);
          outFile.writeAsStringSync(output);
          written++;
        } catch (e) {
          errors++;
          stderr.writeln(
            'args_generator: error while generating for '
            '${_prettyPath(projectRoot, filePath)}: $e',
          );
        }
      }
    }

    return ArgsGeneratorRunSummary(
      writtenFiles: written,
      deletedFiles: deleted,
      skippedFiles: skipped,
      errors: errors,
    );
  }
}

@visibleForTesting
String wrapAsPartForCli({required String partOfUri, required String body}) {
  final trimmedBody = body.trimRight();
  return [
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
    '// ignore_for_file: type=lint',
    '',
    "part of '$partOfUri';",
    '',
    trimmedBody,
    '',
  ].join('\n');
}

bool _isDefinitelyGenerated(String filePath) {
  final name = _basename(filePath);
  return name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name.endsWith('.gr.dart') ||
      name.endsWith('.mocks.dart');
}

@visibleForTesting
String argsOutputForLibrary(String libraryFilePath) {
  if (!libraryFilePath.endsWith('.dart')) {
    throw ArgumentError('Not a dart file: $libraryFilePath');
  }
  final base = libraryFilePath.substring(
    0,
    libraryFilePath.length - '.dart'.length,
  );
  return '$base.args.g.dart';
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
