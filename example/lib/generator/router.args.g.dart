// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:flutter/material.dart' as _i1;
import 'package:page_args_generator_example/main.dart' as _i2;
import 'package:page_args_generator_example/second_page.dart' as _i4;

class TestPageArgs {
  const TestPageArgs({
    required this.bigIntValue,
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
    this.defType = _i2.TestEnum.value3,
    this.defaultInt = 0,
    this.defaultNum = 0,
    this.defaultString = '',
    this.defaultIterable = const [],
  });

  final BigInt bigIntValue;
  final bool boolValue;
  final DateTime dateTimeValue;
  final double doubleValue;
  final _i2.TestEnum typeValue;
  final int intValue;
  final num numValue;
  final String stringValue;
  final Uri uriValue;
  final List<String> iterableValue;
  final BigInt? optionalBigInt;
  final bool? optionalBool;
  final DateTime? optionalDateTime;
  final double? optionalDouble;
  final _i2.TestEnum? optionalType;
  final int? optionalInt;
  final num? optionalNum;
  final String? optionalString;
  final Uri? optionalUri;
  final List<String>? optionalIterable;
  final bool? defaultBool;
  final double? defaultDouble;
  final _i2.TestEnum? defType;
  final int? defaultInt;
  final num? defaultNum;
  final String? defaultString;
  final List<String>? defaultIterable;

  /// Tries to parse the arguments from a [Map] and returns an instance of [TestPageArgs].
  /// Returns `null` if parsing fails.
  static TestPageArgs? tryParse(Map<String, String> args) {
    try {
      return TestPageArgs(
        bigIntValue: BigInt.parse(args['big-int-value'].toString()),
        boolValue: args.containsKey('bool-value') ? (args['bool-value']?.toLowerCase() == 'true') : false,
        dateTimeValue: DateTime.parse(args['date-time-value'].toString()),
        doubleValue: double.parse(args['double-value'].toString()),
        typeValue: args.containsKey('type-value') ? _i2.TestEnum.values.where((e) => e.toString().split('.').last == args['type-value']).first : _i2.TestEnum.values.first,
        intValue: int.parse(args['int-value'].toString()),
        numValue: num.parse(args['num-value'].toString()),
        stringValue: args['string-value'] ?? '',
        uriValue: Uri.parse(args['uri-value'].toString()),
        iterableValue: args.containsKey('iterable-value') ? args['iterable-value']!.split(',').map((e) => e).toList() : [],
        optionalBigInt: args['optional-big-int'] != null ? BigInt.tryParse(args['optional-big-int']!) : null,
        optionalBool: args.containsKey('optional-bool') ? (args['optional-bool']?.toLowerCase() == 'true') : null,
        optionalDateTime: args['optional-date-time'] != null ? DateTime.tryParse(args['optional-date-time']!) : null,
        optionalDouble: args['optional-double'] != null ? double.tryParse(args['optional-double']!) : null,
        optionalType: args.containsKey('optional-type') ? _i2.TestEnum.values.where((e) => e.toString().split('.').last == args['optional-type']).firstOrNull : null,
        optionalInt: args['optional-int'] != null ? int.tryParse(args['optional-int']!) : null,
        optionalNum: args['optional-num'] != null ? num.tryParse(args['optional-num']!) : null,
        optionalString: args['optional-string'],
        optionalUri: args['optional-uri'] != null ? Uri.tryParse(args['optional-uri']!) : null,
        optionalIterable: args.containsKey('optional-iterable') ? args['optional-iterable']!.split(',').map((e) => e).toList() : null,
        defaultBool: args.containsKey('default-bool') ? (args['default-bool']?.toLowerCase() == 'true') : null,
        defaultDouble: double.tryParse(args['default-double'] ?? '0.0'),
        defType: args.containsKey('def-type') ? _i2.TestEnum.values.where((e) => e.toString().split('.').last == args['def-type']).firstOrNull ?? _i2.TestEnum.value3 : _i2.TestEnum.value3,
        defaultInt: int.tryParse(args['default-int'] ?? '0'),
        defaultNum: num.tryParse(args['default-num'] ?? '0'),
        defaultString: args['default-string'] ?? '',
        defaultIterable: args.containsKey('default-iterable') ? args['default-iterable']!.split(',').map((e) => e).toList() : null
      );
    } catch (e) {
      return null;
    }
  }

   /// A builder method for creating the associated widget from arguments.
  static _i1.Widget builder(
    _i1.BuildContext context, {
    required Map<String, String> arguments,
    _i1.Widget? notFoundScreen,
  }) {
    final args = TestPageArgs.tryParse(arguments);

    if (args == null) {
      return notFoundScreen ?? const _i1.SizedBox.shrink();
    }

    return _i2.TestPage(
      bigIntValue: args.bigIntValue,
      boolValue: args.boolValue,
      dateTimeValue: args.dateTimeValue,
      doubleValue: args.doubleValue,
      typeValue: args.typeValue,
      intValue: args.intValue,
      numValue: args.numValue,
      stringValue: args.stringValue,
      uriValue: args.uriValue,
      iterableValue: args.iterableValue,
      optionalBigInt: args.optionalBigInt,
      optionalBool: args.optionalBool,
      optionalDateTime: args.optionalDateTime,
      optionalDouble: args.optionalDouble,
      optionalType: args.optionalType,
      optionalInt: args.optionalInt,
      optionalNum: args.optionalNum,
      optionalString: args.optionalString,
      optionalUri: args.optionalUri,
      optionalIterable: args.optionalIterable,
      defaultBool: args.defaultBool,
      defaultDouble: args.defaultDouble,
      defType: args.defType,
      defaultInt: args.defaultInt,
      defaultNum: args.defaultNum,
      defaultString: args.defaultString,
      defaultIterable: args.defaultIterable,
    ).wrappedRoute(context);
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {
        'big-int-value': bigIntValue.toString(),
        'bool-value': boolValue.toString(),
        'date-time-value': dateTimeValue.toIso8601String(),
        'double-value': doubleValue.toString(),
        if (_$TestEnumEnumMap[typeValue] != null) 'type-value': _$TestEnumEnumMap[typeValue]!,
        'int-value': intValue.toString(),
        'num-value': numValue.toString(),
        if (stringValue.isNotEmpty) 'string-value': stringValue,
        'uri-value': uriValue.toString(),
        if (iterableValue.isNotEmpty) 'iterable-value': iterableValue.map((e) => e.toString()).join(","),
        if (optionalBigInt != null) 'optional-big-int': optionalBigInt.toString(),
        if (optionalBool != null) 'optional-bool': optionalBool.toString(),
        if (optionalDateTime != null) 'optional-date-time': optionalDateTime!.toIso8601String(),
        if (optionalDouble != null) 'optional-double': optionalDouble.toString(),
        if (_$TestEnumEnumMap[optionalType] != null) 'optional-type': _$TestEnumEnumMap[optionalType]!,
        if (optionalInt != null) 'optional-int': optionalInt.toString(),
        if (optionalNum != null) 'optional-num': optionalNum.toString(),
        if (optionalString != null && optionalString!.isNotEmpty) 'optional-string': optionalString!,
        if (optionalUri != null) 'optional-uri': optionalUri.toString(),
        if (optionalIterable != null && optionalIterable!.isNotEmpty) 'optional-iterable': optionalIterable!.map((e) => e.toString()).join(","),
        if (defaultBool != null) 'default-bool': defaultBool.toString(),
        if (defaultDouble != null) 'default-double': defaultDouble.toString(),
        if (_$TestEnumEnumMap[defType] != null) 'def-type': _$TestEnumEnumMap[defType]!,
        if (defaultInt != null) 'default-int': defaultInt.toString(),
        if (defaultNum != null) 'default-num': defaultNum.toString(),
        if (defaultString != null && defaultString!.isNotEmpty) 'default-string': defaultString!,
        if (defaultIterable != null && defaultIterable!.isNotEmpty) 'default-iterable': defaultIterable!.map((e) => e.toString()).join(",")
      };

  static const _$TestEnumEnumMap = {
  _i2.TestEnum.value1: 'value1',
  _i2.TestEnum.value2: 'value2',
  _i2.TestEnum.value3: 'value3'
};
}


class SecondPageArgs {
  const SecondPageArgs({
    required this.bigIntValue,
    required this.boolValue,
    required this.dateTimeValue,
    required this.doubleValue,
    required this.intValue,
    required this.numValue,
    required this.stringValue,
    required this.uriValue,
    required this.iterableValue,
    this.optionalBigInt,
    this.optionalBool,
    this.optionalDateTime,
    this.optionalDouble,
    this.optionalInt,
    this.optionalNum,
    this.optionalString,
    this.optionalUri,
    this.optionalIterable,
    this.defaultBool = false,
    this.defaultDouble = 0.0,
    this.defaultInt = 0,
    this.defaultNum = 0,
    this.defaultString = '',
    this.defaultIterable = const [],
  });

  final BigInt bigIntValue;
  final bool boolValue;
  final DateTime dateTimeValue;
  final double doubleValue;
  final int intValue;
  final num numValue;
  final String stringValue;
  final Uri uriValue;
  final List<String> iterableValue;
  final BigInt? optionalBigInt;
  final bool? optionalBool;
  final DateTime? optionalDateTime;
  final double? optionalDouble;
  final int? optionalInt;
  final num? optionalNum;
  final String? optionalString;
  final Uri? optionalUri;
  final List<String>? optionalIterable;
  final bool? defaultBool;
  final double? defaultDouble;
  final int? defaultInt;
  final num? defaultNum;
  final String? defaultString;
  final List<String>? defaultIterable;

  /// Tries to parse the arguments from a [Map] and returns an instance of [SecondPageArgs].
  /// Returns `null` if parsing fails.
  static SecondPageArgs? tryParse(Map<String, String> args) {
    try {
      return SecondPageArgs(
        bigIntValue: BigInt.parse(args['big-int-value'].toString()),
        boolValue: args.containsKey('bool-value') ? (args['bool-value']?.toLowerCase() == 'true') : false,
        dateTimeValue: DateTime.parse(args['date-time-value'].toString()),
        doubleValue: double.parse(args['double-value'].toString()),
        intValue: int.parse(args['int-value'].toString()),
        numValue: num.parse(args['num-value'].toString()),
        stringValue: args['string-value'] ?? '',
        uriValue: Uri.parse(args['uri-value'].toString()),
        iterableValue: args.containsKey('iterable-value') ? args['iterable-value']!.split(',').map((e) => e).toList() : [],
        optionalBigInt: args['optional-big-int'] != null ? BigInt.tryParse(args['optional-big-int']!) : null,
        optionalBool: args.containsKey('optional-bool') ? (args['optional-bool']?.toLowerCase() == 'true') : null,
        optionalDateTime: args['optional-date-time'] != null ? DateTime.tryParse(args['optional-date-time']!) : null,
        optionalDouble: args['optional-double'] != null ? double.tryParse(args['optional-double']!) : null,
        optionalInt: args['optional-int'] != null ? int.tryParse(args['optional-int']!) : null,
        optionalNum: args['optional-num'] != null ? num.tryParse(args['optional-num']!) : null,
        optionalString: args['optional-string'],
        optionalUri: args['optional-uri'] != null ? Uri.tryParse(args['optional-uri']!) : null,
        optionalIterable: args.containsKey('optional-iterable') ? args['optional-iterable']!.split(',').map((e) => e).toList() : null,
        defaultBool: args.containsKey('default-bool') ? (args['default-bool']?.toLowerCase() == 'true') : null,
        defaultDouble: double.tryParse(args['default-double'] ?? '0.0'),
        defaultInt: int.tryParse(args['default-int'] ?? '0'),
        defaultNum: num.tryParse(args['default-num'] ?? '0'),
        defaultString: args['default-string'] ?? '',
        defaultIterable: args.containsKey('default-iterable') ? args['default-iterable']!.split(',').map((e) => e).toList() : null
      );
    } catch (e) {
      return null;
    }
  }

   /// A builder method for creating the associated widget from arguments.
  static _i1.Widget builder(
    _i1.BuildContext context, {
    required Map<String, String> arguments,
    _i1.Widget? notFoundScreen,
  }) {
    final args = SecondPageArgs.tryParse(arguments);

    if (args == null) {
      return notFoundScreen ?? const _i1.SizedBox.shrink();
    }

    return _i4.SecondPage(
      bigIntValue: args.bigIntValue,
      boolValue: args.boolValue,
      dateTimeValue: args.dateTimeValue,
      doubleValue: args.doubleValue,
      intValue: args.intValue,
      numValue: args.numValue,
      stringValue: args.stringValue,
      uriValue: args.uriValue,
      iterableValue: args.iterableValue,
      optionalBigInt: args.optionalBigInt,
      optionalBool: args.optionalBool,
      optionalDateTime: args.optionalDateTime,
      optionalDouble: args.optionalDouble,
      optionalInt: args.optionalInt,
      optionalNum: args.optionalNum,
      optionalString: args.optionalString,
      optionalUri: args.optionalUri,
      optionalIterable: args.optionalIterable,
      defaultBool: args.defaultBool,
      defaultDouble: args.defaultDouble,
      defaultInt: args.defaultInt,
      defaultNum: args.defaultNum,
      defaultString: args.defaultString,
      defaultIterable: args.defaultIterable,
    ).wrappedRoute(context);
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {
        'big-int-value': bigIntValue.toString(),
        'bool-value': boolValue.toString(),
        'date-time-value': dateTimeValue.toIso8601String(),
        'double-value': doubleValue.toString(),
        'int-value': intValue.toString(),
        'num-value': numValue.toString(),
        if (stringValue.isNotEmpty) 'string-value': stringValue,
        'uri-value': uriValue.toString(),
        if (iterableValue.isNotEmpty) 'iterable-value': iterableValue.map((e) => e.toString()).join(","),
        if (optionalBigInt != null) 'optional-big-int': optionalBigInt.toString(),
        if (optionalBool != null) 'optional-bool': optionalBool.toString(),
        if (optionalDateTime != null) 'optional-date-time': optionalDateTime!.toIso8601String(),
        if (optionalDouble != null) 'optional-double': optionalDouble.toString(),
        if (optionalInt != null) 'optional-int': optionalInt.toString(),
        if (optionalNum != null) 'optional-num': optionalNum.toString(),
        if (optionalString != null && optionalString!.isNotEmpty) 'optional-string': optionalString!,
        if (optionalUri != null) 'optional-uri': optionalUri.toString(),
        if (optionalIterable != null && optionalIterable!.isNotEmpty) 'optional-iterable': optionalIterable!.map((e) => e.toString()).join(","),
        if (defaultBool != null) 'default-bool': defaultBool.toString(),
        if (defaultDouble != null) 'default-double': defaultDouble.toString(),
        if (defaultInt != null) 'default-int': defaultInt.toString(),
        if (defaultNum != null) 'default-num': defaultNum.toString(),
        if (defaultString != null && defaultString!.isNotEmpty) 'default-string': defaultString!,
        if (defaultIterable != null && defaultIterable!.isNotEmpty) 'default-iterable': defaultIterable!.map((e) => e.toString()).join(",")
      };

  
}

