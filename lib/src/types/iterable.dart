import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/type_helper.dart';
import 'package:args_generator/src/utils/helpers.dart';

/// A [TypeHelper] implementation for handling fields of type `Iterable`.
///
/// This class provides the logic for decoding `Iterable` values from a map
/// of arguments and encoding `Iterable` fields back into a map format.
class TypeHelperIterable extends TypeHelper {
  /// Determines if the given [type] matches the `Iterable` type.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is assignable to `Iterable`; otherwise, `false`.
  @override
  bool matchesType(DartType type) {
    if (type is InterfaceType) {
      final element = type.element;

      return element.name == 'List' || element.name == 'Iterable';
    }
    return false;
  }

  /// Decodes an `Iterable` value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the field to decode.
  /// - [defaultValue]: The default value for the field, if any (not used here).
  ///
  /// The method checks if the field's name (converted to kebab-case) exists in
  /// the `args` map. If it exists, the value is split by commas and converted
  /// into a list of strings. If the field is nullable and the key does not exist,
  /// `null` is returned. If the field is non-nullable, an empty list is returned
  /// as the default value.
  ///
  /// Returns:
  /// A string representing the code to decode the `Iterable` value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;

    return '''
args.containsKey('$key')
  ? args['$key']!
      .split(',')
      .map((e) => e)
      .toList()
  : ${isNullable ? 'null' : '[]'}
''';
  }

  /// Encodes an `Iterable` field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the field to encode.
  ///
  /// If the field is nullable, the generated code includes a conditional check
  /// to ensure the field is not `null` before adding it to the map. The field's
  /// values are converted to strings and joined by commas for serialization.
  /// The field's name is converted to kebab-case for use as the key.
  ///
  /// Returns:
  /// A string representing the code to encode the `Iterable` value.
  @override
  String encode(ParameterElement field) {
    final key = field.name.convertToKebabCase();
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final name = field.name;

    if (isNullable) {
      return 'if ($name != null) \'$key\': $name!.map((e) => e.toString()).join(",")';
    }
    return '\'$key\': $name.map((e) => e.toString()).join(",")';
  }
}
