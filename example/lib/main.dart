import 'package:args_generator_annotations/args_annotations.dart';
import 'package:flutter/material.dart';
import 'package:page_args_generator_example/route_wrapper.dart';

enum TestEnum { value1, value2, value3 }

void main() {
  runApp(
    MaterialApp(
      home: TestPage(
        bigIntValue: BigInt.from(100),
        boolValue: true,
        dateTimeValue: DateTime.now(),
        doubleValue: 3.14,
        typeValue: TestEnum.value1,
        intValue: 42,
        numValue: 3.14,
        stringValue: 'Hello, World!',
        uriValue: Uri.parse('https://example.com'),
        iterableValue: ['a', 'b', 'c'],
      ),
    ),
  );
}

@GenerateArgs()
class TestPage extends StatefulWidget implements RouteWrapper {
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
    this.defType = TestEnum.value3,
    this.defaultInt = 0,
    this.defaultNum = 0,
    this.defaultString = '',
    this.defaultIterable = const [],
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

  @override
  State<TestPage> createState() => _TestPageState();

  @override
  Widget wrappedRoute(BuildContext context) {
    return this;
  }
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stringValue),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/second');
          },
          child: Text('Go to Second Page'),
        ),
      ),
    );
  }
}
