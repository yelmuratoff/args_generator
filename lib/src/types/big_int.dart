import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `BigInt`.
///
/// This class provides the logic for decoding `BigInt` values from a map
/// of arguments and encoding `BigInt` fields back into a map format.
class TypeHelperBigInt extends TypeHelper {
  /// Determines if the given [type] matches the `BigInt` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is assignable to `BigInt`; otherwise, `false`.
  @override
  bool matchesType(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;

      return element.name == 'BigInt';
    }
    return false;
  }

  /// Decodes a `BigInt` value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the field to decode.
  /// - [defaultValue]: The default value for the field, if any.
  ///
  /// Converts the value in the `args` map (with the field name converted
  /// to kebab-case) into a `BigInt` using `BigInt.tryParse`. If the field is
  /// non-nullable and the parsed value is `null`, `BigInt.zero` is used as a fallback.
  ///
  /// Returns:
  /// A string representing the code to decode the `BigInt` value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final arg = "args['$key']";
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;

    return isNullable
        ? (defaultValue != null
              ? "BigInt.tryParse($arg ?? $defaultValue)"
              : "$arg != null ? BigInt.tryParse($arg!) : null")
        : "BigInt.parse($arg.toString())";
  }

  /// Encodes a `BigInt` field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// name is converted to kebab-case for use as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `BigInt` value.
  @override
  String encode(ParameterElement field) {
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;
    final key = name.convertToKebabCase();

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name.toString()';
    }
    return '\'$key\': $name.toString()';
  }
}
