import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element2.dart';

/// Extension on [DartType] to provide additional utility methods
/// for analyzing and working with Dart types.
extension DartTypeExtension on DartType {
  /// Checks if this type is assignable to another [DartType].
  ///
  /// - [other]: The type to check against.
  ///
  /// Returns:
  /// `true` if this type is assignable to [other]; otherwise, `false`.
  bool isAssignableTo(DartType other) {
    final me = this;

    if (me is InterfaceType) {
      final library = me.element3.library2;
      return library.typeSystem.isAssignableTo(this, other);
    }
    return true;
  }

  /// Checks if this type is an enum.
  ///
  /// Returns:
  /// `true` if this type is an enum; otherwise, `false`.
  bool get isEnum {
    final myType = this;
    return myType is InterfaceType && myType.element3 is EnumElement2;
  }

  /// Checks if this type is nullable.
  ///
  /// A type is considered nullable if it is either a `DynamicType` or has
  /// a [NullabilitySuffix] of `question`.
  ///
  /// Returns:
  /// `true` if this type is nullable; otherwise, `false`.
  bool get isNullableType =>
      this is DynamicType || nullabilitySuffix == NullabilitySuffix.question;

  /// Checks if this type behaves like `dynamic`.
  ///
  /// A type is considered to behave like `dynamic` if it is either `dynamic`
  /// itself or `Object?`.
  ///
  /// Returns:
  /// `true` if this type is like `dynamic`; otherwise, `false`.
  bool get isLikeDynamic =>
      (isDartCoreObject && isNullableType) || this is DynamicType;

  /// Retrieves all [DartType] implementations, including those that this type
  /// implements, mixes-in, and extends, starting with this type itself.
  ///
  /// Returns:
  /// An iterable of [DartType] objects representing all type implementations.
  Iterable<DartType> get typeImplementations sync* {
    yield this;

    final myType = this;

    if (myType is InterfaceType) {
      // Yield types from implemented interfaces.
      yield* myType.interfaces.expand((e) => e.typeImplementations);

      // Yield types from mixins.
      yield* myType.mixins.expand((e) => e.typeImplementations);

      // Yield types from the superclass chain.
      if (myType.superclass != null) {
        yield* myType.superclass!.typeImplementations;
      }
    }
  }
}

/// Cached regex pattern for kebab-case conversion.
final RegExp _kebabCasePattern = RegExp(r'(?<=[a-z])(?=[A-Z])');

/// Extension on [String] to provide additional string manipulation utilities.
extension StringX on String {
  /// Converts a camelCase or PascalCase string into kebab-case.
  ///
  /// Example:
  /// ```dart
  /// 'myCamelCaseString'.convertToKebabCase(); // Returns 'my-camel-case-string'
  /// 'PascalCase'.convertToKebabCase(); // Returns 'pascal-case'
  /// ```
  ///
  /// Returns:
  /// A kebab-case version of the string.
  String convertToKebabCase() {
    return split(_kebabCasePattern).join('-').toLowerCase();
  }
}
