import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'package:args_generator/args_generator.dart';
import 'package:args_generator_annotations/args_annotations.dart';

class AggregatingArgsBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    r'$package$': ['lib/generated/args/router.args.g.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generatedParts = <String>[];

    final allImports = SplayTreeSet<String>();
    final typeChecker = TypeChecker.fromRuntime(GenerateArgs);
    final generator = PageArgsGenerator();

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.endsWith('.g.dart')) continue;

      LibraryElement library;
      try {
        library = await buildStep.resolver.libraryFor(input);
      } catch (e) {
        log.warning('Не удалось обработать ${input.path}: $e');
        continue;
      }

      bool foundAnnotated = false;
      final generationFutures = <Future>[];

      for (final element in library.topLevelElements.whereType<ClassElement>()) {
        for (final meta in element.metadata) {
          final constant = meta.computeConstantValue();
          if (constant != null && typeChecker.isExactlyType(constant.type!)) {
            foundAnnotated = true;
            generationFutures
                .add(_generateForElement(generator, element, ConstantReader(constant), buildStep, generatedParts));
            break;
          }
        }
      }

      if (foundAnnotated) {
        allImports.add(input.uri.toString());
        for (final importElement in library.importedLibraries) {
          final uri = importElement.source.uri.toString();
          if (uri != 'dart:core') {
            allImports.add(uri);
          }
        }
      }

      await Future.wait(generationFutures);
    }

    final importsText = allImports.map((uri) => "import '$uri';").join('\n');

    final output = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Aggregated generated arguments
// ignore_for_file: type=lint, unused_import

$importsText

${generatedParts.join('\n\n')}
''';

    final outputId = AssetId(buildStep.inputId.package, 'lib/generated/args/router.args.g.dart');
    await buildStep.writeAsString(outputId, output);
  }

  Future<void> _generateForElement(
    PageArgsGenerator generator,
    ClassElement element,
    ConstantReader reader,
    BuildStep buildStep,
    List<String> generatedParts,
  ) async {
    try {
      final generated = await generator.generateForAnnotatedElement(
        element,
        reader,
        buildStep,
      );
      if (generated.isNotEmpty) {
        generatedParts.add(generated);
      }
    } catch (e, stackTrace) {
      log.severe('Ошибка при генерации для ${element.name}: $e\n$stackTrace');
    }
  }
}

Builder aggregatingArgsBuilder(BuilderOptions options) => AggregatingArgsBuilder();
