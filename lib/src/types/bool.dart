import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `bool`.
///
/// This class provides the logic for decoding boolean values from a map
/// of arguments and encoding boolean fields back into a map format.
class TypeHelperBool extends TypeHelper {
  /// Determines if the given [type] matches the `bool` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is `bool`; otherwise, `false`.
  @override
  bool matchesType(DartType type) => type.isDartCoreBool;

  /// Decodes a `bool` value from the provided arguments.
  ///
  /// - [field]: The field to decode.
  /// - [defaultValue]: The default value for the field, if any.
  ///
  /// Checks if the key (derived from the field name converted to kebab-case)
  /// exists in the `args` map. If the key exists, its value is compared to the
  /// string `'true'` (case-insensitive). If the key does not exist:
  /// - Returns `null` if the field is nullable.
  /// - Returns `false` if the field is non-nullable.
  ///
  /// Returns:
  /// A string representing the code to decode the `bool` value.
  @override
  String decode(ArgField field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    return '''
args.containsKey('$key')
  ? (args['$key']?.toLowerCase() == 'true')
  : ${isNullable ? 'null' : 'false'}
''';
  }

  /// Encodes a `bool` field into a map format.
  ///
  /// - [field]: The field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// name is converted to kebab-case for use as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `bool` value.
  @override
  String encode(ArgField field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name.toString()';
    }
    return '\'$key\': $name.toString()';
  }
}
