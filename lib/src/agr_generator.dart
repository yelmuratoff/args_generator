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
  final buildExtensions = const {
    r'$package$': ['lib/generated/args/router.args.g.dart']
  };

  // Словарь "URI -> префикс"
  final _uriToPrefix = <String, String>{};

  // Словарь "Имя класса/enum -> префикс"
  final _classToPrefix = <String, String>{};

  // URIs, где реально найдены аннотированные классы
  final _annotatedUris = <String>{};

  int _prefixCounter = 0;

  @override
  Future<void> build(BuildStep buildStep) async {
    final generatedParts = <String>[];
    final typeChecker = TypeChecker.fromRuntime(GenerateArgs);
    final generator = PageArgsGenerator();

    // Сюда собираем все импорты, которые нужно учитывать при генерации
    final allImports = SplayTreeSet<String>();

    // 1. Проходим по всем .dart-файлам (кроме *.g.dart), ищем классы с @GenerateArgs
    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.endsWith('.g.dart')) continue;

      LibraryElement library;
      try {
        library = await buildStep.resolver.libraryFor(input);
      } catch (_) {
        continue;
      }

      bool foundAnnotated = false;
      for (final classEl in library.topLevelElements.whereType<ClassElement>()) {
        for (final meta in classEl.metadata) {
          final constValue = meta.computeConstantValue();
          if (constValue != null && typeChecker.isExactlyType(constValue.type!)) {
            foundAnnotated = true;
            try {
              final code = await generator.generateForAnnotatedElement(
                classEl,
                ConstantReader(constValue),
                buildStep,
              );
              if (code.isNotEmpty) {
                generatedParts.add(code);
              }
            } catch (e, st) {
              log.severe('Ошибка генерации для ${classEl.name}: $e\n$st');
            }
            // достаточно первой аннотации на класс
            break;
          }
        }
      }

      if (foundAnnotated) {
        final uriStr = library.source.uri.toString();
        _annotatedUris.add(uriStr);
        // сам файл
        allImports.add(uriStr);
        // плюс все его импорты (не "dart:core")
        for (final imp in library.importedLibraries) {
          final impUri = imp.source.uri.toString();
          if (impUri != 'dart:core') allImports.add(impUri);
        }
      }
    }

    // 2. Назначаем уникальный префикс каждому URI
    for (final uri in allImports) {
      _uriToPrefix[uri] ??= '_i${_prefixCounter++}';
    }

    // 3. Для каждого URI рекурсивно собираем top-level классы/enum'ы (учитывая export)
    for (final uri in allImports) {
      final prefix = _uriToPrefix[uri]!;
      try {
        final library = await buildStep.resolver.libraryFor(AssetId.resolve(Uri.parse(uri)));
        await _collectAllTopLevelClasses(library, prefix);
      } catch (_) {
        // если не получилось загрузить, пропустим
      }
    }

    // 4. Склеиваем весь сгенерированный код
    var body = generatedParts.join('\n\n');

    // 5. Префиксируем упоминания классов/enum'ов
    _classToPrefix.forEach((name, prefix) {
      body = body.replaceAllMapped(RegExp('\\b$name\\b'), (_) => '$prefix.$name');
    });

    // 6. Оставляем только те импорты, чьи префиксы реально используются в final-коде
    final usedImports = allImports.map((uri) {
      final prefix = _uriToPrefix[uri]!;
      return "import '$uri' as $prefix;";
    }).where((line) {
      final match = RegExp("import '(.*)' as (\\S+);").firstMatch(line);
      if (match == null) return false;
      final importUri = match.group(1)!;
      final importPrefix = match.group(2)!;

      // Если файл был с аннотациями, оставим импорт, ведь мы могли обращаться к нему.
      if (_annotatedUris.contains(importUri)) {
        return true;
      }
      // Иначе проверим, упоминается ли префикс в тексте
      return body.contains('$importPrefix.');
    }).toList();

    // 7. Формируем финальный файл
    final output = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

${usedImports.join('\n')}

$body
''';

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/generated/args/router.args.g.dart'),
      output,
    );
  }

  /// Рекурсивно собираем top-level классы/enum'ы из [library] и её export'ов,
  /// чтобы правильно добавлять префиксы для каждого такого элемента.
  Future<void> _collectAllTopLevelClasses(
    LibraryElement library,
    String prefix, [
    Set<LibraryElement>? visited,
  ]) async {
    visited ??= <LibraryElement>{};
    if (!visited.add(library)) return; // уже посещено

    for (final el in library.topLevelElements) {
      if (el is ClassElement || el is EnumElement) {
        if (el.name != null) {
          _classToPrefix[el.name!] = prefix;
        }
      }
    }

    // Рекурсивно просматриваем экспортируемые библиотеки
    for (final exported in library.exportedLibraries) {
      await _collectAllTopLevelClasses(exported, prefix, visited);
    }
  }
}

Builder aggregatingArgsBuilder(BuilderOptions options) => AggregatingArgsBuilder();
