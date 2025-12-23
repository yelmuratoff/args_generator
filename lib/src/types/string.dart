import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `String`.
///
/// This class provides the logic for decoding `String` values from a map
/// of arguments and encoding `String` fields back into a map format.
class TypeHelperString extends TypeHelper {
  /// Determines if the given [type] matches the `String` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is `String`; otherwise, `false`.
  @override
  bool matchesType(DartType type) => type.isDartCoreString;

  /// Decodes a `String` value from the provided arguments.
  ///
  /// - [field]: The field to decode.
  /// - [defaultValue]: An optional default value for the field.
  ///
  /// The method extracts the value associated with the field's name (converted
  /// to kebab-case) from the `args` map. If the field is nullable and the value
  /// is not present, `null` or the provided default value is returned. If the
  /// field is non-nullable and the value is missing, a default empty string is used.
  ///
  /// Returns:
  /// A string representing the code to decode the `String` value.
  @override
  String decode(ArgField field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;

    if (isNullable) {
      return defaultValue != null
          ? "args['$key'] ?? $defaultValue"
          : "args['$key']";
    }
    return "args['$key'] ?? ''";
  }

  /// Encodes a `String` field into a map format.
  ///
  /// - [field]: The field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// name is converted to kebab-case for use as the key in the map.
  ///
  /// Returns:
  /// A string representing the code to encode the `String` value.
  @override
  String encode(ArgField field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null && $name!.isNotEmpty) \'$key\': $name!';
    }
    return 'if ($name.isNotEmpty) \'$key\': $name';
  }
}
