import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `int`.
///
/// This class provides the logic for decoding `int` values from a map
/// of arguments and encoding `int` fields back into a map format.
class TypeHelperInt extends TypeHelper {
  /// Determines if the given [type] matches the `int` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is `int`; otherwise, `false`.
  @override
  bool matchesType(DartType type) => type.isDartCoreInt;

  /// Decodes an `int` value from the provided arguments.
  ///
  /// - [field]: The [FieldElement] representing the field to decode.
  /// - [defaultValue]: The default value for the field, if any (not used here).
  ///
  /// This method extracts the value associated with the field's name (converted
  /// to kebab-case) from the `args` map. It then tries to parse the value into
  /// an `int` using `int.tryParse`. If the field is non-nullable and the parsed
  /// value is `null`, a default value of `0` is returned.
  ///
  /// Returns:
  /// A string representing the code to decode the `int` value.
  @override
  String decode(FieldElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    return '''
int.tryParse(args['$key'] ?? '0')${isNullable ? '' : ' ?? 0'}
''';
  }

  /// Encodes an `int` field into a map format.
  ///
  /// - [field]: The [FieldElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// value is converted to a string representation using `toString()`.
  /// The field's name is converted to kebab-case for use as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `int` value.
  @override
  String encode(FieldElement field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name.toString()';
    }
    return '\'$key\': $name.toString()';
  }
}