
# Page Args Generator

![version](https://img.shields.io/badge/version-0.0.1-blue)
![sdk](https://img.shields.io/badge/sdk-%5E3.6.0-blue)
![build_runner](https://img.shields.io/badge/build_runner-%5E2.4.14-blue)

**Page Args Generator** is a Dart library designed to simplify the management of arguments passed between pages in Flutter applications. By leveraging code generation, this package creates companion argument classes for pages, ensuring type safety and reducing boilerplate.

## Features

- **Type-Safe Argument Parsing**: Automatically generate classes for managing page arguments.
- **Flexible Support**: Handles a variety of data types including `int`, `String`, `bool`, `double`, `DateTime`, `Uri`, and even custom enums.
- **Optional and Default Arguments**: Supports optional fields and default values seamlessly.
- **Customizable**: Allows for fine-tuning of generated code to match your requirements.

## Getting Started

### Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  args_generator: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.14
```

Run the command to fetch the dependencies:

```bash
dart pub get
```

### Usage

1. Annotate your page class with `@GenerateArgs()`.
2. Run `build_runner` to generate the corresponding arguments class.

#### Example

```dart
import 'package:args_generator/args_generator.dart';

part 'test_page_args.g.dart';

@GenerateArgs()
class TestPage {
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
```

Run the command to generate the `TestPageArgs` class:

```bash
dart run build_runner build
```

#### Generated Code

The following class will be generated:

```dart
class TestPageArgs {
  const TestPageArgs({
    required this.bigIntValue,
    required this.boolValue,
    // ... other fields
  });

  final BigInt bigIntValue;
  final bool boolValue;
  // ... other fields

  static TestPageArgs? tryParse(Map<String, String> args) {
    try {
      return TestPageArgs(
        bigIntValue: BigInt.tryParse(args['big-int-value'] ?? '0') ?? BigInt.zero,
        boolValue: args['bool-value']?.toLowerCase() == 'true',
        // ... parsing logic for other fields
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, String> toArguments() => {
        'big-int-value': bigIntValue.toString(),
        'bool-value': boolValue.toString(),
        // ... encoding logic for other fields
      };
}
```

## Supported Types

- **Primitives**: `int`, `String`, `bool`, `double`, `num`
- **Complex Types**: `BigInt`, `DateTime`, `Uri`, `List<String>`
- **Enums**: Custom enums with automatic mapping
- **Optional Fields**: Support for nullable fields with `null` values
- **Default Values**: Handle fields with default values

## Error Handling

- If a required argument is missing or invalid during `tryParse`, `null` is returned.
- Unsupported field types throw an `InvalidGenerationSourceError`.

## Development

### Contributing

We welcome contributions! Please open issues or submit pull requests on the GitHub repository.

## License

This package is licensed under the MIT License. See the LICENSE file for details.

---

Simplify your Flutter page argument management with **Page Args Generator**! 🚀