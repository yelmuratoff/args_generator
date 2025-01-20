// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_page.dart';

// **************************************************************************
// PageArgsGenerator
// **************************************************************************

class TestPageArgs {
  const TestPageArgs(
      {required this.bigIntValue,
      required this.boolValue,
      required this.dateTimeValue,
      required this.doubleValue,
      required this.typeValue,
      required this.intValue,
      required this.numValue,
      required this.stringValue,
      required this.uriValue,
      required this.iterableValue,
      this.optionalBigInt,
      this.optionalBool,
      this.optionalDateTime,
      this.optionalDouble,
      this.optionalType,
      this.optionalInt,
      this.optionalNum,
      this.optionalString,
      this.optionalUri,
      this.optionalIterable,
      this.defaultBool = false,
      this.defaultDouble = 0.0,
      this.defType = TestEnum.value1,
      this.defaultInt = 0,
      this.defaultNum = 0,
      this.defaultString = '',
      this.defaultIterable = const []});

  final BigInt bigIntValue;
  final bool boolValue;
  final DateTime dateTimeValue;
  final double doubleValue;
  final TestEnum typeValue;
  final int intValue;
  final num numValue;
  final String stringValue;
  final Uri uriValue;
  final List<String> iterableValue;
  final BigInt? optionalBigInt;
  final bool? optionalBool;
  final DateTime? optionalDateTime;
  final double? optionalDouble;
  final TestEnum? optionalType;
  final int? optionalInt;
  final num? optionalNum;
  final String? optionalString;
  final Uri? optionalUri;
  final List<String>? optionalIterable;
  final bool? defaultBool;
  final double? defaultDouble;
  final TestEnum? defType;
  final int? defaultInt;
  final num? defaultNum;
  final String? defaultString;
  final List<String>? defaultIterable;

  /// Tries to parse the arguments from a [Map] and returns an instance of [TestPageArgs].
  /// Returns `null` if parsing fails.
  static TestPageArgs? tryParse(Map<String, String> args) {
    try {
      return TestPageArgs(
        bigIntValue:
            BigInt.tryParse(args['big-int-value'] ?? '0') ?? BigInt.zero,
        boolValue: args.containsKey('bool-value')
            ? (args['bool-value']?.toLowerCase() == 'true')
            : false,
        dateTimeValue: DateTime.tryParse(args['date-time-value'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        doubleValue: double.tryParse(args['double-value'] ?? '0') ?? 0.0,
        typeValue: args.containsKey('type-value')
            ? TestEnum.values
                .where(
                    (e) => e.toString().split('.').last == args['type-value'])
                .first
            : TestEnum.values.first,
        intValue: int.tryParse(args['int-value'] ?? '0') ?? 0,
        numValue: num.tryParse(args['num-value'] ?? '0') ?? 0,
        stringValue: args['string-value'] ?? '',
        uriValue: Uri.tryParse(args['uri-value'] ?? '') ?? Uri(),
        iterableValue: args.containsKey('iterable-value')
            ? args['iterable-value']!.split(',').map((e) => e).toList()
            : [],
        optionalBigInt: BigInt.tryParse(args['optional-big-int'] ?? '0'),
        optionalBool: args.containsKey('optional-bool')
            ? (args['optional-bool']?.toLowerCase() == 'true')
            : null,
        optionalDateTime: DateTime.tryParse(args['optional-date-time'] ?? ''),
        optionalDouble: double.tryParse(args['optional-double'] ?? '0'),
        optionalType: args.containsKey('optional-type')
            ? TestEnum.values
                .where((e) =>
                    e.toString().split('.').last == args['optional-type'])
                .firstOrNull
            : null,
        optionalInt: int.tryParse(args['optional-int'] ?? '0'),
        optionalNum: num.tryParse(args['optional-num'] ?? '0'),
        optionalString: args['optional-string'],
        optionalUri: Uri.tryParse(args['optional-uri'] ?? ''),
        optionalIterable: args.containsKey('optional-iterable')
            ? args['optional-iterable']!.split(',').map((e) => e).toList()
            : null,
        defaultBool: args.containsKey('default-bool')
            ? (args['default-bool']?.toLowerCase() == 'true')
            : null,
        defaultDouble: double.tryParse(args['default-double'] ?? '0'),
        defType: args.containsKey('def-type')
            ? TestEnum.values
                .where((e) => e.toString().split('.').last == args['def-type'])
                .firstOrNull
            : null,
        defaultInt: int.tryParse(args['default-int'] ?? '0'),
        defaultNum: num.tryParse(args['default-num'] ?? '0'),
        defaultString: args['default-string'] ?? '',
        defaultIterable: args.containsKey('default-iterable')
            ? args['default-iterable']!.split(',').map((e) => e).toList()
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {
        'big-int-value': bigIntValue.toString(),
        'bool-value': boolValue.toString(),
        'date-time-value': dateTimeValue.toIso8601String(),
        'double-value': doubleValue.toString(),
        if (_$TestEnumEnumMap[typeValue] != null)
          'type-value': _$TestEnumEnumMap[typeValue]!,
        'int-value': intValue.toString(),
        'num-value': numValue.toString(),
        'string-value': stringValue,
        'uri-value': uriValue.toString(),
        'iterable-value': iterableValue.map((e) => e.toString()).join(","),
        if (optionalBigInt != null)
          'optional-big-int': optionalBigInt.toString(),
        if (optionalBool != null) 'optional-bool': optionalBool.toString(),
        if (optionalDateTime != null)
          'optional-date-time': optionalDateTime!.toIso8601String(),
        if (optionalDouble != null)
          'optional-double': optionalDouble.toString(),
        if (_$TestEnumEnumMap[optionalType] != null)
          'optional-type': _$TestEnumEnumMap[optionalType]!,
        if (optionalInt != null) 'optional-int': optionalInt.toString(),
        if (optionalNum != null) 'optional-num': optionalNum.toString(),
        if (optionalString != null) 'optional-string': optionalString!,
        if (optionalUri != null) 'optional-uri': optionalUri.toString(),
        if (optionalIterable != null)
          'optional-iterable':
              optionalIterable!.map((e) => e.toString()).join(","),
        if (defaultBool != null) 'default-bool': defaultBool.toString(),
        if (defaultDouble != null) 'default-double': defaultDouble.toString(),
        if (_$TestEnumEnumMap[defType] != null)
          'def-type': _$TestEnumEnumMap[defType]!,
        if (defaultInt != null) 'default-int': defaultInt.toString(),
        if (defaultNum != null) 'default-num': defaultNum.toString(),
        if (defaultString != null) 'default-string': defaultString!,
        if (defaultIterable != null)
          'default-iterable':
              defaultIterable!.map((e) => e.toString()).join(",")
      };

  static const _$TestEnumEnumMap = {
    TestEnum.value1: 'value1',
    TestEnum.value2: 'value2',
    TestEnum.value3: 'value3'
  };
}
