import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:build/build.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';
import 'package:collection/collection.dart';
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
  final PageArgsEmitter _emitter = const PageArgsEmitter();

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

    return _emitter.generateForClass(element);
  }
}

/// BuildStep-free generator logic used by the CLI runner.
class PageArgsEmitter {
  const PageArgsEmitter();

  /// The name of the class generated for [classElement].
  static String argsClassNameOf(ClassElement classElement) =>
      '${classElement.displayName}Args';

  String generateForClass(ClassElement classElement) {
    final className = classElement.displayName;
    final hasRouteWrapper = classElement.methods.any((interface) {
      return interface.name == 'wrappedRoute';
    });
    final argsClassName = argsClassNameOf(classElement);

    final constructor = classElement.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'The class $className must have an unnamed constructor.',
        element: classElement,
      );
    }

    final fields = classElement.fields
        .where((field) => !field.isStatic && field.isFinal)
        .toList();
    final parameters = constructor.formalParameters;

    final constructorParams = <String>[];
    for (final param in parameters) {
      final isRequired = param.isRequired;
      final defaultValue = param.defaultValueCode;
      for (final helper in TypeHelper.values) {
        if (helper.matchesType(param.type)) {
          constructorParams.add(
            '${isRequired ? 'required ' : ''}this.${param.displayName}${defaultValue != null ? ' = $defaultValue' : ''}',
          );
        }
      }
    }

    final fieldDeclarations = <String>[];
    for (final param in parameters) {
      for (final helper in TypeHelper.values) {
        if (helper.matchesType(param.type)) {
          fieldDeclarations.add(
            'final ${param.type.getDisplayString()} ${param.displayName};',
          );
        }
      }
    }

    final tryParseBody = <String>[];
    for (final param in parameters) {
      final decodedValue = _decodeField(
        ArgField(name: param.displayName, type: param.type),
        param.defaultValueCode,
      );
      if (decodedValue != null) {
        tryParseBody.add('${param.displayName}: $decodedValue');
      }
    }

    final toArgumentsBody = <String>[];
    for (final param in parameters) {
      final encodedValue = _encodeField(
        ArgField(name: param.displayName, type: param.type),
      );
      if (encodedValue != null) {
        toArgumentsBody.add(encodedValue);
      }
    }

    final argSpecs = <String>[];
    for (final param in parameters) {
      final argSpec = _argSpec(
        name: param.displayName,
        type: param.type,
        isRequired: param.isRequired,
        defaultValue: param.defaultValueCode,
      );
      if (argSpec != null) {
        argSpecs.add('$argSpec,');
      }
    }

    final uniqueEnumFields = fields
        .map((field) => field.type.element)
        .whereType<EnumElement>()
        .toSet();

    final enumMapDeclarations = uniqueEnumFields
        .map((enumElement) {
          final enumType = enumElement.displayName;
          final enumValues = enumElement.constants
              .map((e) => "  $enumType.${e.displayName}: '${e.displayName}'")
              .join(',\n');

          return 'static const _\$${enumType}EnumMap = {\n$enumValues\n};';
        })
        .join('\n\n');

    final wrapper = hasRouteWrapper ? '.wrappedRoute(context)' : '';

    return '''
class $argsClassName implements PageArgs {
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
      ${fields.map((f) => '${f.displayName}: args.${f.displayName},').join('\n      ')}
    )$wrapper;
  }

  /// Converts the fields of this class into a [Map] of arguments.
  @override
  Map<String, String> toArguments() => {
        ${toArgumentsBody.join(',\n        ')}
      };

  /// Describes every argument [tryParse] reads.
  static const List<PageArgSpec> argSpecs = [
    ${argSpecs.join('\n    ')}
  ];

  /// Binds [tryParse], [builder] and [argSpecs] for routers and tools.
  static const schema = PageArgsSchema<$argsClassName, BuildContext, Widget>(
    tryParse: tryParse,
    builder: builder,
    argSpecs: argSpecs,
  );

  $enumMapDeclarations
}
''';
  }

  String? _decodeField(ArgField field, String? defaultValue) {
    for (final helper in TypeHelper.values) {
      if (helper.matchesType(field.type)) {
        return helper.decode(field, defaultValue);
      }
    }
    return null;
  }

  String? _argSpec({
    required String name,
    required DartType type,
    required bool isRequired,
    required String? defaultValue,
  }) {
    final kind = TypeHelper.values
        .firstWhereOrNull((helper) => helper.matchesType(type))
        ?.kind;
    if (kind == null) return null;

    final needsValue =
        isRequired &&
        !type.isNullableType &&
        defaultValue == null &&
        kind != PageArgKind.flag;
    final arguments = [
      "'${name.convertToKebabCase()}'",
      'PageArgKind.${kind.name}',
      if (needsValue) 'isRequired: true',
      if (defaultValue != null) 'defaultValue: $defaultValue',
      if (kind == PageArgKind.choice && type is InterfaceType)
        'options: ${type.element.displayName}.values',
    ];
    return 'PageArgSpec(${arguments.join(', ')})';
  }

  String? _encodeField(ArgField field) {
    for (final helper in TypeHelper.values) {
      if (helper.matchesType(field.type)) {
        return helper.encode(field);
      }
    }
    return null;
  }
}
