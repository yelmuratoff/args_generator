import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `double`.
///
/// This class provides the logic for decoding `double` values from a map
/// of arguments and encoding `double` fields back into a map format.
class TypeHelperDouble extends TypeHelper {
  /// Determines if the given [type] matches the `double` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is `double`; otherwise, `false`.
  @override
  bool matchesType(DartType type) => type.isDartCoreDouble;

  /// Decodes a `double` value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the field to decode.
  /// - [defaultValue]: The default value for the field, if any.
  ///
  /// The method extracts the value associated with the field's name (converted
  /// to kebab-case) from the `args` map. It then tries to parse the value
  /// into a `double` using `double.tryParse`. If the field is non-nullable
  /// and the parsed value is `null`, a default value of `0.0` is returned.
  ///
  /// Returns:
  /// A string representing the code to decode the `double` value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    return '''
double.tryParse(args['$key'] ?? '0')${isNullable ? '' : ' ?? 0.0'}
''';
  }

  /// Encodes a `double` field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// value is converted to a string representation using `toString()`.
  /// The field's name is converted to kebab-case for use as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `double` value.
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
