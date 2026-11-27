import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:build/build.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';
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

    final parameters = constructor.formalParameters;
    final helpers = <FormalParameterElement, TypeHelper>{};
    for (final param in parameters) {
      final helper = TypeHelper.forType(param.type);
      if (helper != null) {
        helpers[param] = helper;
      } else if (param.isRequired) {
        throw InvalidGenerationSourceError(
          'The parameter `${param.displayName}` of $className has the '
          'unsupported type `${param.type.getDisplayString()}`. Make it '
          'optional or use one of: int, double, num, BigInt, bool, String, '
          'DateTime, Uri, an enum, List<String> or Iterable<String>.',
          element: param,
        );
      }
    }
    final supported = helpers.keys.toList(growable: false);

    final constructorParams = [
      for (final param in supported)
        '${param.isRequired ? 'required ' : ''}this.${param.displayName}'
            '${_defaultOf(param) != null ? ' = ${_defaultOf(param)}' : ''}',
    ];

    final fieldDeclarations = [
      for (final param in supported)
        'final ${param.type.getDisplayString()} ${param.displayName};',
    ];

    final tryParseBody = [
      for (final param in supported)
        '${param.displayName}: ${_decodeField(param, helpers[param]!)}',
    ];

    final toArgumentsBody = [
      for (final param in supported)
        helpers[param]!.encode(
          ArgField(name: param.displayName, type: param.type),
        ),
    ];

    final argSpecs = [
      for (final param in supported) '${_argSpec(param, helpers[param]!)},',
    ];

    final builderArguments = _builderArguments(
      classElement,
      parameters,
      helpers,
    );

    final uniqueEnumFields = supported
        .map((param) => param.type.element)
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
    final argsConstructor = constructorParams.isEmpty
        ? 'const $argsClassName();'
        : 'const $argsClassName({\n    ${constructorParams.join(',\n    ')},\n  });';

    return '''
class $argsClassName implements PageArgs {
  $argsConstructor

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
      ${builderArguments.map((argument) => '$argument,').join('\n      ')}
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

  String? _defaultOf(FormalParameterElement param) {
    final code = param.defaultValueCode;
    final type = param.type;
    if (code != null && code.startsWith('.') && type is InterfaceType) {
      return '${type.element.displayName}$code';
    }
    return code;
  }

  String _decodeField(FormalParameterElement param, TypeHelper helper) {
    final decoded = helper.decode(
      ArgField(name: param.displayName, type: param.type),
    );
    final defaultValue = _defaultOf(param);
    if (defaultValue == null) return decoded;
    final key = param.displayName.convertToKebabCase();
    return "args.containsKey('$key') ? ($decoded) : $defaultValue";
  }

  List<String> _builderArguments(
    ClassElement classElement,
    List<FormalParameterElement> parameters,
    Map<FormalParameterElement, TypeHelper> helpers,
  ) {
    final arguments = <String>[];
    FormalParameterElement? skippedPositional;
    for (final param in parameters) {
      final name = param.displayName;
      final isSupported = helpers.containsKey(param);
      if (param.isNamed) {
        if (isSupported) arguments.add('$name: args.$name');
        continue;
      }
      if (!isSupported) {
        skippedPositional ??= param;
        continue;
      }
      if (skippedPositional != null) {
        throw InvalidGenerationSourceError(
          'The positional parameter `$name` of ${classElement.displayName} '
          'follows `${skippedPositional.displayName}`, whose type is not '
          'supported, so the page cannot be built from arguments.',
          element: param,
        );
      }
      arguments.add('args.$name');
    }
    return arguments;
  }

  String _argSpec(FormalParameterElement param, TypeHelper helper) {
    final name = param.displayName;
    final type = param.type;
    final kind = helper.kind;
    final isRequired = param.isRequired;
    final defaultValue = _defaultOf(param);

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
}
