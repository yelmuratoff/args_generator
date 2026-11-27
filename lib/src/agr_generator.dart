import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'package:args_generator/args_generator.dart';
import 'package:args_generator/src/aggregated_output.dart';

/// A `Builder` that aggregates all classes annotated with `@GenerateArgs`
/// and generates argument-handling code for them.
class AggregatingArgsBuilder implements Builder {
  AggregatingArgsBuilder({required this.outputPath});

  final String outputPath;

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$package$': [outputPath],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generator = PageArgsGenerator();
    final classes = <GeneratedArgsClass>[];
    final librariesByUri = <String, LibraryElement>{};
    final annotatedUris = <String>{};

    log.info('Starting args_generator analysis...');

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.endsWith('.g.dart')) continue;
      final content = await buildStep.readAsString(input);
      if (!content.contains('GenerateArgs')) continue;

      final LibraryElement library;
      final List<GeneratedArgsClass> libraryClasses;
      try {
        library = await buildStep.resolver.libraryFor(input);
        libraryClasses = await _generateLibrary(library, generator, buildStep);
      } on NonLibraryAssetException {
        continue;
      } on InvalidGenerationSourceError catch (e) {
        log.severe('args_generator: ${input.path}: $e');
        continue;
      } on SyntaxErrorInAssetException catch (e) {
        log.severe('args_generator: ${input.path}: $e');
        continue;
      } on UnresolvedAnnotationException catch (e) {
        log.severe('args_generator: ${input.path}: $e');
        continue;
      }

      if (libraryClasses.isEmpty) continue;
      final uri = library.uri.toString();
      classes.addAll(libraryClasses);
      annotatedUris.add(uri);
      librariesByUri[uri] = library;
      for (final fragment in library.fragments) {
        for (final imported in fragment.importedLibraries) {
          if (!imported.uri.isScheme('dart')) {
            librariesByUri[imported.uri.toString()] = imported;
          }
        }
      }
    }

    if (classes.isEmpty) return;

    log.info('Generating code and resolving imports...');

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, outputPath),
      assembleAggregatedOutput(
        classes: classes,
        libraries: librariesByUri,
        annotatedUris: annotatedUris,
      ),
    );
  }
}

Future<List<GeneratedArgsClass>> _generateLibrary(
  LibraryElement library,
  PageArgsGenerator generator,
  BuildStep buildStep,
) async {
  final uri = library.uri.toString();
  return [
    for (final annotated in LibraryReader(
      library,
    ).annotatedWith(generateArgsChecker))
      if (annotated.element case final ClassElement element)
        (
          libraryUri: uri,
          className: PageArgsEmitter.argsClassNameOf(element),
          code: await generator.generateForAnnotatedElement(
            element,
            annotated.annotation,
            buildStep,
          ),
        ),
  ];
}

/// Factory method to create an instance of [AggregatingArgsBuilder].
Builder aggregatingArgsBuilder(BuilderOptions options) {
  return AggregatingArgsBuilder(
    outputPath:
        options.config['output'] as String? ??
        'lib/generated/args/router.args.g.dart',
  );
}
