import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args_generator/src/types/big_int.dart';
import 'package:args_generator/src/types/bool.dart';
import 'package:args_generator/src/types/date_time.dart';
import 'package:args_generator/src/types/double.dart';
import 'package:args_generator/src/types/enum.dart';
import 'package:args_generator/src/types/int.dart';
import 'package:args_generator/src/types/iterable.dart';
import 'package:args_generator/src/types/num.dart';
import 'package:args_generator/src/types/string.dart';
import 'package:args_generator/src/types/uri.dart';

export 'big_int.dart';
export 'bool.dart';
export 'date_time.dart';
export 'double.dart';
export 'enum.dart';
export 'int.dart';
export 'num.dart';
export 'string.dart';
export 'uri.dart';

/// Abstract class defining the contract for type helpers.
///
/// Type helpers are responsible for matching specific Dart types and providing
/// logic for decoding and encoding field values of those types.
abstract class TypeHelper {
  /// Checks whether this helper can handle the given [type].
  ///
  /// - [type]: The [DartType] to check.
  ///
  /// Returns:
  /// `true` if this helper can handle the given [type]; otherwise, `false`.
  bool matchesType(DartType type);

  /// Decodes a field of the handled type from a given map of arguments.
  ///
  /// - [field]: The [FieldElement] representing the field to decode.
  /// - [defaultValue]: An optional default value to use if the field value is missing.
  ///
  /// Returns:
  /// A string representing the code for decoding the field value.
  String decode(ParameterElement field, String? defaultValue);

  /// Encodes a field of the handled type into a map format.
  ///
  /// - [field]: The [FieldElement] representing the field to encode.
  ///
  /// Returns:
  /// A string representing the code for encoding the field value.
  String encode(ParameterElement field);

  /// Provides a list of all available type helpers.
  ///
  /// This static getter returns instances of all implemented type helpers,
  /// each capable of handling specific Dart types such as `int`, `String`,
  /// `DateTime`, and others.
  ///
  /// Returns:
  /// A list of [TypeHelper] instances.
  static List<TypeHelper> get values => <TypeHelper>[
    TypeHelperBigInt(),
    TypeHelperBool(),
    TypeHelperDateTime(),
    TypeHelperDouble(),
    TypeHelperEnum(),
    TypeHelperInt(),
    TypeHelperNum(),
    TypeHelperString(),
    TypeHelperUri(),
    TypeHelperIterable(),
  ];
}
