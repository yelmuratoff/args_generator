import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `DateTime`.
///
/// This class provides the logic for decoding `DateTime` values from a map
/// of arguments and encoding `DateTime` fields back into a map format.
class TypeHelperDateTime extends TypeHelper {
  /// Determines if the given [type] matches the `DateTime` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is assignable to `DateTime`; otherwise, `false`.
  @override
  bool matchesType(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;

      return element.name == 'DateTime';
    }
    return false;
  }

  /// Decodes a `DateTime` value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the field to decode.
  /// - [defaultValue]: The default value for the field, if any.
  ///
  /// The method extracts the value associated with the field's name (converted
  /// to kebab-case) from the `args` map. It then tries to parse the value
  /// into a `DateTime` using `DateTime.tryParse`. If the field is non-nullable
  /// and the parsed value is `null`, a default value of
  /// `DateTime.fromMillisecondsSinceEpoch(0)` is returned.
  ///
  /// Returns:
  /// A string representing the code to decode the `DateTime` value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;

    if (isNullable) {
      if (defaultValue != null) {
        return "DateTime.tryParse(args['$key'] ?? $defaultValue)";
      }
      return "args['$key'] != null ? DateTime.tryParse(args['$key']!) : null";
    }
    return "DateTime.parse(args['$key'].toString(),)";
  }

  /// Encodes a `DateTime` field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// value is serialized using the `toIso8601String()` method to maintain a
  /// standardized format. The field's name is converted to kebab-case for use
  /// as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `DateTime` value.
  @override
  String encode(ParameterElement field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name!.toIso8601String()';
    }

    return '\'$key\': $name.toIso8601String()';
  }
}
