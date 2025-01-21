import 'package:args_generator/args_generator.dart';
import 'package:flutter/material.dart';

part 'test_page.args.g.dart';

class BasePage {
  const BasePage({this.key});
  final Key? key;
}

@GenerateArgs()
class TestPage extends BasePage {
  const TestPage({
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
    this.defType = TestEnum.value1,
    this.defaultInt = 0,
    this.defaultNum = 0,
    this.defaultString = '',
    this.defaultIterable = const [],
    super.key,
  });

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
}

enum TestEnum { value1, value2, value3 }
