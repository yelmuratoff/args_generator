import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:build/build.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:source_gen/source_gen.dart';

/// Creates a [Builder] for the `args_generator`.
///
/// The builder utilizes the [SharedPartBuilder] to perform code generation
/// for classes annotated with the `@GenerateArgs` annotation. It relies on
/// the [PageArgsGenerator] class to define the logic for generating the
/// necessary code.
///
/// - [options]: Configuration options for the builder.
///
/// Returns:
/// A [Builder] that integrates with the `build_runner` for source code generation.
Builder pageArgsGenerator(BuilderOptions options) {
  return PartBuilder([PageArgsGenerator()], '.args.g.dart');
}

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
    final hasRouteWrapper = classElement.methods.any((interface) {
      return interface.name == 'wrappedRoute';
    });
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

    final constructorParams = [];
    for (final param in parameters) {
      final isRequired = param.isRequired;
      final defaultValue = param.defaultValueCode;
      for (final helper in TypeHelper.values) {
        if (helper.matchesType(param.type)) {
          constructorParams.add(
            '${isRequired ? 'required ' : ''}this.${param.name}${defaultValue != null ? ' = $defaultValue' : ''}',
          );
        }
      }
    }

    // Generate field declarations for the arguments class.
    final fieldDeclarations = [];
    for (final param in parameters) {
      for (final helper in TypeHelper.values) {
        if (helper.matchesType(param.type)) {
          fieldDeclarations.add(
            'final ${param.type.getDisplayString()} ${param.name};',
          );
        }
      }
    }

    // Generate the body of the `tryParse` method.
    final tryParseBody = [];
    for (final param in parameters) {
      final decodedValue = _decodeField(param);
      if (decodedValue != null) {
        tryParseBody.add('${param.name}: $decodedValue');
      }
    }

    // Generate the body of the `toArguments` method.
    final toArgumentsBody = [];
    for (final param in parameters) {
      final encodedValue = _encodeField(param);
      if (encodedValue != null) {
        toArgumentsBody.add(encodedValue);
      }
    }

    // Generate enum maps for any enum fields.
    final uniqueEnumFields = fields
        .where((field) => field.type.element is EnumElement)
        .map((field) => field.type.element as EnumElement)
        .toSet();

    final enumMapDeclarations = uniqueEnumFields
        .map((enumElement) {
          final enumType = enumElement.name;
          final enumValues = enumElement.fields
              .where((e) => e.isEnumConstant)
              .map((e) => "  $enumType.${e.name}: '${e.name}'")
              .join(',\n');

          return 'static const _\$${enumType}EnumMap = {\n$enumValues\n};';
        })
        .join('\n\n');

    final wrapper = hasRouteWrapper ? '.wrappedRoute(context)' : '';

    // Generate the arguments class.
    return '''
class $argsClassName {
  const $argsClassName({
    ${constructorParams.join(',\n    ')},
  });

  ${fieldDeclarations.join('\n  ')}

  /// Tries to parse the arguments from a [Map] and returns an instance of [$argsClassName].
  /// Returns `null` if parsing fails.
  static $argsClassName? tryParse(Map<String, String> args) {
    try {
      return $argsClassName(
        ${tryParseBody.join(',\n        ')}
      );
    } catch (e) {
      return null;
    }
  }

   /// A builder method for creating the associated widget from arguments.
  static Widget builder(
    BuildContext context, {
    required Map<String, String> arguments,
    Widget? notFoundScreen,
  }) {
    final args = $argsClassName.tryParse(arguments);

    if (args == null) {
      return notFoundScreen ?? const SizedBox.shrink();
    }

    return $className(
      ${fields.map((f) => '${f.name}: args.${f.name},').join('\n      ')}
    )$wrapper;
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {
        ${toArgumentsBody.join(',\n        ')}
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
  String? _decodeField(ParameterElement param) {
    final fieldType = param.type;
    final defaultValue = param.defaultValueCode;

    for (final helper in TypeHelper.values) {
      if (helper.matchesType(fieldType)) {
        return helper.decode(param, defaultValue);
      }
    }
    return null;
  }

  /// Encodes a field into the arguments map.
  ///
  /// - [field]: The field to encode.
  ///
  /// Returns:
  /// A string representing the encoding logic for the field.
  String? _encodeField(ParameterElement field) {
    final fieldType = field.type;

    for (final helper in TypeHelper.values) {
      if (helper.matchesType(fieldType)) {
        return helper.encode(field);
      }
    }
    return null;
  }
}
