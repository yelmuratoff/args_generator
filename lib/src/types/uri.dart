import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `Uri`.
///
/// This class provides the logic for decoding `Uri` values from a map
/// of arguments and encoding `Uri` fields back into a map format.
class TypeHelperUri extends TypeHelper {
  /// Determines if the given [type] matches the `Uri` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is assignable to `Uri`; otherwise, `false`.
  @override
  bool matchesType(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;

      return element.name == 'Uri';
    }
    return false;
  }

  /// Decodes a `Uri` value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the field to decode.
  /// - [defaultValue]: An optional default value for the field (not used here).
  ///
  /// The method checks for the field's name (converted to kebab-case) in the
  /// `args` map. If found, it tries to parse the value into a `Uri` using
  /// `Uri.tryParse`. If the field is non-nullable and the parsed value is `null`,
  /// a default empty `Uri()` is returned.
  ///
  /// Returns:
  /// A string representing the code to decode the `Uri` value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final arg = "args['$key']";
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;

    if (isNullable) {
      return defaultValue != null
          ? "Uri.tryParse($arg ?? $defaultValue)"
          : "$arg != null ? Uri.tryParse($arg!) : null";
    }
    return "Uri.parse($arg.toString())";
  }

  /// Encodes a `Uri` field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// `toString()` method is used to serialize the `Uri` value. The field's name
  /// is converted to kebab-case for use as the key in the map.
  ///
  /// Returns:
  /// A string representing the code to encode the `Uri` value.
  @override
  String encode(ParameterElement field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name.toString()';
    }
    return '\'$key\': $name.toString()';
  }
}
