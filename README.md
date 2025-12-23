
# Args Generator

<p align="center">
  <a href="https://pub.dev/packages/args_generator"><img src="https://img.shields.io/pub/v/args_generator.svg" alt="Generator"></a>
  <a href="https://pub.dev/packages/args_annotations"><img src="https://img.shields.io/pub/v/args_annotations.svg" alt="Annotations"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/args_generator"><img src="https://img.shields.io/github/stars/yelmuratoff/args_generator?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/likes/args_generator?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/popularity/args_generator?logo=flutter" alt="Pub popularity"></a>
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/points/args_generator?logo=flutter" alt="Pub points"></a>
</p>


**Args Generator** is a Dart library designed to simplify the management of arguments passed between pages in Flutter applications. By leveraging code generation, this package creates companion argument classes for pages, ensuring type safety and reducing boilerplate.

In the future, the library will be rewritten to utilize Dart macros, further enhancing performance, reducing code complexity, and integrating more seamlessly with the Dart ecosystem.

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
  args_generator: ^1.0.4

dev_dependencies:
  build_runner: ^2.4.14
  args_annotations: ^1.0.4
```

Run the command to fetch the dependencies:

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

### Usage

You can generate code in two ways:

### Option A: CLI (recommended)

No `build_runner` needed.

```bash
dart run args_generator
```

By default it analyzes `lib/`. You can specify paths:

```bash
dart run args_generator -p lib -p example/lib
```

If you want the process to fail in CI when generation hits an error:

```bash
dart run args_generator --fail-on-error
```

To remove stale generated files when you delete `@GenerateArgs` from a library:

```bash
dart run args_generator --clean
```

### Option B: build_runner

Add `args_generator` to your `dev_dependencies` and configure `build_runner`.
2. Run `build_runner` to generate the corresponding arguments class.

#### Example

```dart
import 'package:args_annotations/args_annotations.dart';

part 'test_page.args.g.dart';

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
dart run build_runner build --delete-conflicting-outputs
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
- **Complex Types**: `BigInt`, `DateTime`, `Uri`, `Iterable`
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

Simplify your Flutter page argument management with **Args Generator**! 🚀
