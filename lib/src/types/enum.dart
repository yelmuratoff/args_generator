import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/utils/helpers.dart';
import 'package:args_generator/src/types/type_helper.dart';

/// Constant defining the helper method name for converting enums from strings.
const String enumExtensionHelperName = r'_$fromName';

/// Generates the name of the map used for enum serialization.
///
/// - [type]: The enum type for which the map name is generated.
///
/// Returns:
/// A string representing the name of the enum map.
String enumMapName(InterfaceType type) => '_\$${type.element.name}EnumMap';

/// A [TypeHelper] implementation for handling enum fields.
///
/// This class provides logic for decoding enums from a map of arguments and
/// encoding enums back into a map format, using the enum's string representation.
class TypeHelperEnum extends TypeHelper {
  /// Determines if the given [type] is an enum.
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if the [type] is an enum; otherwise, `false`.
  @override
  bool matchesType(DartType type) => type.isEnum;

  /// Decodes an enum value from the provided arguments.
  ///
  /// - [field]: The [ParameterElement] representing the enum field to decode.
  /// - [defaultValue]: The default value for the field, if any (not used here).
  ///
  /// This method checks if the field's name (converted to kebab-case) exists
  /// in the `args` map. If the key exists, it looks for a matching enum value
  /// by comparing the string representation (last segment after the `.`).
  ///
  /// If the enum field is nullable and the value is not found, `null` is returned.
  /// If non-nullable, the first value of the enum is used as the fallback.
  ///
  /// Returns:
  /// A string representing the code to decode the enum value.
  @override
  String decode(ParameterElement field, String? defaultValue) {
    final key = field.name.convertToKebabCase();
    final enumName = field.type.getDisplayString(withNullability: true);
    final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
    final valuesExpr =
        '${clear(enumName)}.values.where((e) => e.toString().split(\'.\').last == args[\'$key\'])';

    final valueExpr = isNullable
        ? (defaultValue != null
            ? '$valuesExpr.firstOrNull ?? $defaultValue'
            : '$valuesExpr.firstOrNull')
        : '$valuesExpr.first';
    final fallbackExpr = isNullable
        ? (defaultValue ?? 'null')
        : (defaultValue ?? '$enumName.values.first');

    return '''
args.containsKey('$key')
  ? $valueExpr
  : $fallbackExpr
''';
  }

  /// Encodes an enum field into a map format.
  ///
  /// - [field]: The [ParameterElement] representing the enum field to encode.
  ///
  /// Uses a generated enum map to encode the enum value into its string
  /// representation. The field's name is converted to kebab-case for use
  /// as the key in the map. If the enum value is not `null`, it is added
  /// to the resulting map.
  ///
  /// Returns:
  /// A string representing the code to encode the enum value.
  @override
  String encode(ParameterElement field) {
    final key = field.name.convertToKebabCase();
    final name = field.name;
    return '''
if (${enumMapName(field.type as InterfaceType)}[$name] != null)
  '$key': ${enumMapName(field.type as InterfaceType)}[$name]!
''';
  }

  /// Cleans the provided [text] by removing whitespace, digits, and non-word characters.
  ///
  /// - [text]: The string to clean.
  ///
  /// Returns:
  /// The cleaned string with unnecessary characters removed.
  String clear(String text) {
    return text.replaceAll(RegExp(r'[\s\d\W]+'), '');
  }
}
