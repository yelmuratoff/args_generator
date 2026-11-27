
# Args Generator

<p align="center">
  <a href="https://pub.dev/packages/args_generator"><img src="https://img.shields.io/pub/v/args_generator.svg" alt="Generator"></a>
  <a href="https://pub.dev/packages/args_generator_annotations"><img src="https://img.shields.io/pub/v/args_generator_annotations.svg" alt="Annotations"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/yelmuratoff/args_generator"><img src="https://img.shields.io/github/stars/yelmuratoff/args_generator?style=social" alt="Pub"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/likes/args_generator?logo=flutter" alt="Pub likes"></a>
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/popularity/args_generator?logo=flutter" alt="Pub popularity"></a>
  <a href="https://pub.dev/packages/args_generator/score"><img src="https://img.shields.io/pub/points/args_generator?logo=flutter" alt="Pub points"></a>
</p>


**Args Generator** is a Dart library designed to simplify the management of arguments passed between pages in Flutter applications. By leveraging code generation, this package creates companion argument classes for pages, ensuring type safety and reducing boilerplate.

## Features

- **Type-Safe Argument Parsing**: Automatically generate classes for managing page arguments.
- **Flexible Support**: Handles a variety of data types including `int`, `String`, `bool`, `double`, `DateTime`, `Uri`, and even custom enums. An optional parameter of another type, such as a callback, is left out of the args class and the page keeps its default. A required one stops generation with an error that names the parameter.
- **Optional and Default Arguments**: Supports optional fields and default values seamlessly. A default is copied into the generated file, so write it as a literal, an enum value, or a `static const` of a class (`Defaults.pageSize`); a top-level constant is not visible there.
- **Customizable**: Allows for fine-tuning of generated code to match your requirements.

## Getting Started

### Requirements

- Dart 3.11 or newer.
- In a Flutter app, Flutter 3.47 or newer. Earlier Flutter releases pin `meta` 1.18.0, which conflicts with the `analyzer` 14 that the generator depends on, so `pub get` fails.

### Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  args_generator_annotations: ^1.3.0

dev_dependencies:
  args_generator: ^1.4.0
  build_runner: ^2.16.1 # only for Option B
```

Run the command to fetch the dependencies:

```bash
dart pub get
```

### Usage

You can generate code in two ways:

### Option A: CLI (recommended)

No `build_runner` needed.

```bash
dart run args_generator
```

This generates the aggregated output file (default: `lib/args/router.args.g.dart`).

To override:

```bash
dart run args_generator --output lib/generator/router.args.g.dart --clean --fail-on-error
```

By default it analyzes `lib/`. You can specify paths:

```bash
dart run args_generator -p lib -p example/lib
```

To remove stale generated files when you delete `@GenerateArgs` from a library:

```bash
dart run args_generator --clean
```

If you want the process to fail in CI when generation hits an error:

```bash
dart run args_generator --fail-on-error
```

When a library fails to generate, the CLI reports it and leaves the existing output file as it was, so a broken page never removes the routes of the others.

#### Faster runs with a compiled CLI

`dart run` starts the analyzer in JIT mode, which takes most of the run. A natively compiled CLI generates the same output about three times faster. `dart install` (Dart 3.10+) installs one on your `PATH`. Pin the version from your `pubspec.lock`; releases up to 1.4.0 cannot find the SDK when compiled.

```bash
dart install args_generator@<version>
args_generator -o lib/generator/router.args.g.dart
```

A compiled CLI runs outside the Dart SDK, so it looks the SDK up from `FLUTTER_ROOT`, then from the `dart` on `PATH`. Pass `--sdk-path` to choose one.

### Option B: build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

1. Annotate your page class with `@GenerateArgs()`.
2. Generate `*.args.g.dart` using CLI or `build_runner`.

#### Example

```dart
import 'package:args_generator_annotations/args_annotations.dart';

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
class TestPageArgs implements PageArgs {
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

### Argument specs and schema

Every generated class also implements `PageArgs` and carries two constants:

```dart
class TestPageArgs implements PageArgs {
  // ...

  static const List<PageArgSpec> argSpecs = [
    PageArgSpec('int-value', PageArgKind.integer, isRequired: true),
    PageArgSpec('default-bool', PageArgKind.flag, defaultValue: false),
    PageArgSpec('type-value', PageArgKind.choice, isRequired: true, options: TestEnum.values),
    // ...
  ];

  static const schema = PageArgsSchema<TestPageArgs, BuildContext, Widget>(
    tryParse: tryParse,
    builder: builder,
    argSpecs: argSpecs,
  );
}
```

- `argSpecs` lists the key, kind, requirement, default and enum values of every argument, so a tool can build or validate route arguments without repeating them.
- `schema` lets a router declare the arguments a route takes. With an enum whose type parameter is inferred from the schema, passing the wrong `*Args` class fails to compile:

```dart
enum Routes<A extends PageArgs> {
  test('test', args: TestPageArgs.schema),
  settings('settings');

  const Routes(this.name, {this.args});

  final String name;
  final PageArgsSchema<A, BuildContext, Widget>? args;
}

extension RouteArgumentsX<A extends PageArgs> on Routes<A> {
  Map<String, String> argumentsOf(A args) => args.toArguments();
}

Routes.test.argumentsOf(TestPageArgs(/* ... */)); // OK
Routes.test.argumentsOf(SecondPageArgs(/* ... */)); // compile-time error
```

Keep such helpers as extension methods on the route: a top-level `push<A>(Routes<A> route, A args)` infers `A` from both arguments and accepts any `PageArgs`.

## Agent skills

From 1.5.0 the package ships an agent skill, [`args-generator-usage`](skills/args-generator-usage/SKILL.md). It teaches a coding agent to annotate pages, run the generator, read the generated class, and fix pages that fail to generate. `args_generator_annotations` 1.3.1 adds `args-generator-annotations-routing` for typed routing with `schema` and `argSpecs`.

Install them from your app root after `flutter pub get` (or `dart pub get`):

```bash
dart run skills@ get -p args_generator -s args-generator-usage
dart run skills@ get -p args_generator_annotations -s args-generator-annotations-routing
```

`--agent <name>` chooses which agent's skill directory receives them. Run the same commands after upgrading either package to refresh the installed copies.

## Aggregated Builder

The aggregated builder is a new feature that allows you create one file with all the arguments for the pages in your project. This is useful for managing all the arguments in one place.

```

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
