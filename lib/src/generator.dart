import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:args_generator/args_generator.dart';
import 'package:args_generator/src/types/type_helper.dart';

/// A generator that creates argument classes for pages annotated with `@GenerateArgs`.
///
/// This generator works by analyzing classes annotated with `@GenerateArgs`
/// and generating a companion arguments class to facilitate passing data
/// between routes in a Flutter application.
class PageArgsGenerator extends GeneratorForAnnotation<GenerateArgs> {
  /// Generates the arguments class for an annotated element.
  ///
  /// - [element]: The annotated element.
  /// - [annotation]: The annotation instance.
  /// - [buildStep]: The current build step.
  ///
  /// Returns:
  /// The generated Dart code as a string.
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Ensure the annotation is applied to a class.
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'GenerateArgs can only be applied to classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.name;
    final argsClassName = '${className}Args';

    // Validate the existence of an unnamed constructor.
    final constructor = classElement.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'The class $className must have an unnamed constructor.',
        element: element,
      );
    }

    // Collect final instance fields and constructor parameters.
    final fields = classElement.fields
        .where((field) => !field.isStatic && field.isFinal)
        .toList();
    final parameters = constructor.parameters;

    // Generate constructor parameters for the arguments class.
    final constructorParams = parameters.map((param) {
      final isRequired = param.isRequired;
      final defaultValue = param.defaultValueCode;
      return '${isRequired ? 'required ' : ''}this.${param.name}${defaultValue != null ? ' = $defaultValue' : ''}';
    }).join(', ');

    // Generate field declarations for the arguments class.
    final fieldDeclarations = fields.map((field) {
      return 'final ${field.type.getDisplayString()} ${field.name};';
    }).join('\n  ');

    // Generate the body of the `tryParse` method.
    final tryParseBody = parameters.map((param) {
      final field = fields.firstWhereOrNull((f) => f.name == param.name);
      if (field == null) return '';
      final decodedValue = _decodeField(field, param);
      return '${param.name}: $decodedValue,';
    }).join('\n        ');

    // Generate the body of the `toArguments` method.
    final toArgumentsBody = fields.map((field) {
      return _encodeField(field);
    }).join(',\n        ');

    // Generate enum maps for any enum fields.
    final uniqueEnumFields = fields
        .where((field) => field.type.element is EnumElement)
        .map((field) => field.type.element as EnumElement)
        .toSet();

    final enumMapDeclarations = uniqueEnumFields.map((enumElement) {
      final enumType = enumElement.name;
      final enumValues = enumElement.fields
          .where((e) => e.isEnumConstant)
          .map((e) => "  $enumType.${e.name}: '${e.name}'")
          .join(',\n');

      return 'static const _\$${enumType}EnumMap = {\n$enumValues\n};';
    }).join('\n\n');

    // Generate the arguments class.
    return '''
class $argsClassName {
  const $argsClassName({
    $constructorParams
  });

  $fieldDeclarations

  /// Tries to parse the arguments from a [Map] and returns an instance of [$argsClassName].
  /// Returns `null` if parsing fails.
  static $argsClassName? tryParse(Map<String, String> args) {
    try {
      return $argsClassName(
        $tryParseBody
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {
        $toArgumentsBody
      };

  $enumMapDeclarations
}
''';
  }

  /// Decodes a field from the arguments map.
  ///
  /// - [field]: The field to decode.
  /// - [param]: The corresponding parameter.
  ///
  /// Returns:
  /// A string representing the decoding logic for the field.
  String _decodeField(FieldElement field, ParameterElement param) {
    final fieldType = field.type;
    final defaultValue = param.defaultValueCode;

    for (final helper in TypeHelper.values) {
      if (helper.matchesType(fieldType)) {
        return helper.decode(field, defaultValue);
      }
    }

    throw InvalidGenerationSourceError(
      'The field type `${fieldType.getDisplayString()}` is not supported.',
      element: field,
    );
  }

  /// Encodes a field into the arguments map.
  ///
  /// - [field]: The field to encode.
  ///
  /// Returns:
  /// A string representing the encoding logic for the field.
  String _encodeField(FieldElement field) {
    final fieldType = field.type;

    for (final helper in TypeHelper.values) {
      if (helper.matchesType(fieldType)) {
        return helper.encode(field);
      }
    }

    throw InvalidGenerationSourceError(
      'The field type `${field.type.getDisplayString()}` is not supported for encoding.',
      element: field,
    );
  }
}
