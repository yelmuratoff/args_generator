import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'package:args_generator/args_generator.dart';
import 'package:args_generator_annotations/args_annotations.dart';

/// A `Builder` that aggregates all classes annotated with `@GenerateArgs`
/// and generates argument-handling code for them.
class AggregatingArgsBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$package$': ['lib/generated/args/router.args.g.dart']
  };

  final Map<String, String> _uriToPrefix = {};
  final Map<String, String> _classToPrefix = {};
  final Set<String> _annotatedUris = {};
  final Map<String, LibraryElement?> _librariesCache = {};
  int _prefixCounter = 0;

  @override
  Future<void> build(BuildStep buildStep) async {
    final List<String> generatedParts = [];
    final typeChecker = TypeChecker.fromRuntime(GenerateArgs);
    final generator = PageArgsGenerator();
    final SplayTreeSet<String> allImports = SplayTreeSet();

    // Process all Dart files, skipping generated files (*.g.dart)
    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.endsWith('.g.dart')) continue;
      if (!await _fileContainsAnnotation(buildStep, input, 'GenerateArgs')) {
        continue;
      }

      final library = await _getOrLoadLibrary(buildStep, input);
      if (library == null) continue;

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
              if (code.isNotEmpty) generatedParts.add(code);
            } catch (e, st) {
              log.severe('Generation error for ${classEl.name}: $e\n$st');
            }
            break; // Process only the first annotation per class
          }
        }
      }

      if (foundAnnotated) {
        final uriStr = library.source.uri.toString();
        _annotatedUris.add(uriStr);
        if (!uriStr.startsWith('dart:')) allImports.add(uriStr);
        for (final imp in library.importedLibraries) {
          final impUri = imp.source.uri.toString();
          if (!impUri.startsWith('dart:')) allImports.add(impUri);
        }
      }
    }

    // Assign unique prefixes to each import
    for (final uri in allImports) {
      _uriToPrefix.putIfAbsent(uri, () => '_i${_prefixCounter++}');
    }

    // Collect top-level classes and enums from imports
    for (final uri in allImports) {
      if (uri.startsWith('dart:')) continue;
      final prefix = _uriToPrefix[uri]!;
      final library = await _getOrLoadLibraryByUri(buildStep, uri);
      if (library != null) await _collectTopLevelClasses(library, prefix);
    }

    // Replace class names with their respective prefixes
    var body = generatedParts.join('\n\n');
    _classToPrefix.forEach((name, prefix) {
      body = body.replaceAllMapped(RegExp('\\b$name\\b'), (_) => '$prefix.$name');
    });

    // Filter only necessary imports
    final usedImports = allImports.map((uri) {
      final prefix = _uriToPrefix[uri]!;
      return "import '$uri' as $prefix;";
    }).where((line) {
      final match = RegExp("import '(.*)' as (\\S+);").firstMatch(line);
      if (match == null) return false;
      final importUri = match.group(1)!;
      final importPrefix = match.group(2)!;
      return _annotatedUris.contains(importUri) || body.contains('$importPrefix.');
    }).toList();

    // Generate final output file
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

  /// Checks if a file likely contains the specified annotation to avoid unnecessary parsing.
  Future<bool> _fileContainsAnnotation(BuildStep buildStep, AssetId id, String annotationName) async {
    final content = await buildStep.readAsString(id);
    return content.contains(annotationName);
  }

  /// Collects all top-level classes and enums from the library and its exports.
  Future<void> _collectTopLevelClasses(LibraryElement library, String prefix, [Set<LibraryElement>? visited]) async {
    visited ??= {};
    if (!visited.add(library)) return;

    for (final el in library.topLevelElements) {
      if (el is ClassElement || el is EnumElement) {
        _classToPrefix[el.name!] = prefix;
      }
    }

    for (final exported in library.exportedLibraries) {
      if (!exported.source.uri.toString().startsWith('dart:')) {
        await _collectTopLevelClasses(exported, prefix, visited);
      }
    }
  }

  /// Loads a [LibraryElement] from a file with caching.
  Future<LibraryElement?> _getOrLoadLibrary(BuildStep buildStep, AssetId input) async {
    final uriStr = input.uri.toString();
    if (_librariesCache.containsKey(uriStr)) return _librariesCache[uriStr];
    try {
      return _librariesCache[uriStr] = await buildStep.resolver.libraryFor(input);
    } catch (_) {
      return _librariesCache[uriStr] = null;
    }
  }

  /// Loads a [LibraryElement] by URI with caching.
  Future<LibraryElement?> _getOrLoadLibraryByUri(BuildStep buildStep, String uriStr) async {
    if (_librariesCache.containsKey(uriStr)) return _librariesCache[uriStr];
    try {
      return _librariesCache[uriStr] = await buildStep.resolver.libraryFor(AssetId.resolve(Uri.parse(uriStr)));
    } catch (_) {
      return _librariesCache[uriStr] = null;
    }
  }
}

/// Factory method to create an instance of [AggregatingArgsBuilder].
Builder aggregatingArgsBuilder(BuilderOptions options) => AggregatingArgsBuilder();
