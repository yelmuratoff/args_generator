import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Matches the `@GenerateArgs()` annotation.
const generateArgsChecker = TypeChecker.typeNamed(
  GenerateArgs,
  inPackage: 'args_generator_annotations',
);

/// One `*Args` class generated for a page declared in [libraryUri].
typedef GeneratedArgsClass = ({
  String libraryUri,
  String className,
  String code,
});

/// Builds the aggregated `*.args.g.dart` file for [classes].
///
/// [libraries] maps every annotated library and each library it imports to
/// its URI; names those libraries export are written with an import prefix.
/// [annotatedUris] are imported even when the body does not reference them.
String assembleAggregatedOutput({
  required Iterable<GeneratedArgsClass> classes,
  required Map<String, LibraryElement> libraries,
  required Set<String> annotatedUris,
}) {
  final sortedClasses = [...classes]
    ..sort((a, b) {
      final byLibrary = a.libraryUri.compareTo(b.libraryUri);
      return byLibrary != 0 ? byLibrary : a.className.compareTo(b.className);
    });
  final generatedClassNames = {for (final c in sortedClasses) c.className};
  final body = sortedClasses.map((c) => c.code).join('\n\n');

  final imports = SplayTreeSet<String>.of(libraries.keys);
  var prefixCounter = 0;
  final uriToPrefix = {for (final uri in imports) uri: '_i${prefixCounter++}'};

  final references = _collectReferences(body);
  final referencedNames = {for (final token in references) token.lexeme};

  final exportsCache = <LibraryElement, Set<String>>{};
  final nameToPrefix = <String, String>{};
  for (final uri in imports) {
    for (final name in _exportedNames(libraries[uri]!, exportsCache)) {
      if (referencedNames.contains(name) &&
          !generatedClassNames.contains(name)) {
        nameToPrefix[name] = uriToPrefix[uri]!;
      }
    }
  }

  final usedPrefixes = <String>{};
  final prefixedBody = StringBuffer();
  var cursor = 0;
  for (final token in references) {
    final prefix = nameToPrefix[token.lexeme];
    if (prefix == null) continue;
    usedPrefixes.add(prefix);
    prefixedBody
      ..write(body.substring(cursor, token.offset))
      ..write('$prefix.');
    cursor = token.offset;
  }
  prefixedBody.write(body.substring(cursor));

  final importLines = [
    for (final uri in imports)
      if (annotatedUris.contains(uri) ||
          usedPrefixes.contains(uriToPrefix[uri]))
        "import '$uri' as ${uriToPrefix[uri]};",
  ];

  return [
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
    '// ignore_for_file: type=lint, unused_import',
    '',
    ...importLines,
    '',
    prefixedBody.toString(),
    '',
  ].join('\n');
}

List<Token> _collectReferences(String body) {
  final unit = parseString(content: body, throwIfDiagnostics: false).unit;
  final collector = _ReferenceCollector();
  unit.accept(collector);
  return collector.references..sort((a, b) => a.offset.compareTo(b.offset));
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  final List<Token> references = [];

  @override
  void visitComment(Comment node) {}

  @override
  void visitNamedType(NamedType node) {
    references.add(node.importPrefix?.name ?? node.name);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final isReference = switch (node.parent) {
      Label() || ConstructorName() => false,
      PrefixedIdentifier(:final identifier) => !identical(identifier, node),
      PropertyAccess(:final propertyName) => !identical(propertyName, node),
      MethodInvocation(:final methodName, :final realTarget) =>
        !identical(methodName, node) || realTarget == null,
      _ => true,
    };
    if (isReference) references.add(node.token);
  }
}

Set<String> _exportedNames(
  LibraryElement library,
  Map<LibraryElement, Set<String>> cache,
) {
  final cached = cache[library];
  if (cached != null) return cached;

  final names = <String>{};
  cache[library] = names;
  for (final element in <Element>[...library.classes, ...library.enums]) {
    final name = element.name;
    if (name != null && name.isNotEmpty) names.add(name);
  }
  for (final exported in library.exportedLibraries) {
    if (!exported.uri.isScheme('dart')) {
      names.addAll(_exportedNames(exported, cache));
    }
  }
  return names;
}
