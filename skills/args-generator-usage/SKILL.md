---
name: args-generator-usage
description: Generate typed route arguments for Flutter pages with args_generator. Use when annotating a page with @GenerateArgs, running `dart run args_generator` or build_runner for it, reading the generated *Args class, or fixing a page that fails to generate.
---

# Generate page arguments with args_generator

`args_generator` turns every class annotated with `@GenerateArgs()` into a
`<Page>Args` class in one aggregated file. The generated class converts route
arguments (`Map<String, String>`) to typed fields and back, and builds the page.

## Set up

- `args_generator_annotations` goes in `dependencies`, because pages import it.
  `args_generator` goes in `dev_dependencies`.
- A Flutter app needs Flutter 3.47 or newer; earlier releases pin `meta` 1.18.0
  and `pub get` fails.
- Import `package:args_generator_annotations/args_annotations.dart` in the page.
  Do not add a `part` directive: the output is one aggregated file, not a part.

## Generate

Run from the app root, then commit the output:

```sh
dart run args_generator -o lib/generator/router.args.g.dart
```

- `-p <dir>` (repeatable) chooses what to scan; the default is `lib`.
- `--fail-on-error` makes CI fail when a page cannot be generated.
- `--clean` deletes the output once no page is annotated.
- When any page fails, the CLI prints the reason and leaves the output file as
  it was. Fix the page and run again.
- With build_runner (`dart run build_runner build`) the output path comes from
  the `output` option of the `args_generator` builder; the default is
  `lib/args/router.args.g.dart`.

## What the page may declare

The unnamed constructor drives generation. Supported parameter types: `int`,
`double`, `num`, `BigInt`, `bool`, `String`, `DateTime`, `Uri`, an enum,
`List<String>`, `Iterable<String>`, each optionally nullable.

- An optional parameter of another type (a callback, `Key? key`) is left out
  of the args class; the page gets its default.
- A required parameter of another type stops generation with an error naming
  it. Make it optional, or pass the data through a supported type.
- A positional parameter is passed positionally. A supported positional
  parameter after an unsupported one is an error.
- A default is copied into the generated file. Use a literal, an enum value
  (`Mode.dark` or `.dark`), or a `static const` of a class. A top-level
  constant is not visible there.
- If the page class has a `wrappedRoute(BuildContext)` method, `builder`
  returns `page.wrappedRoute(context)`.

## How values are read

Keys are the parameter names in kebab-case (`createdAt` → `created-at`).

- A missing key takes the constructor default. Without a default, a nullable
  parameter is `null`, a `String` is `''`, a `bool` is `false`, a list is
  empty, an enum takes its first value, and other non-nullable types make
  `tryParse` return `null`.
- A number, `BigInt`, `DateTime`, `Uri`, or enum value that fails to parse
  makes `tryParse` return `null` for a non-nullable parameter and gives `null`
  for a nullable one.
- `bool` is `true` only for `true` (case-insensitive); any other value is
  `false`. Lists are comma-separated and do not escape commas inside items.
- `DateTime` is written in ISO 8601; enums are written by name.

## Use the generated class

```dart
final args = DetailPageArgs(id: 42, mode: Mode.dark);
final arguments = args.toArguments(); // {'id': '42', 'mode': 'dark'}

final parsed = DetailPageArgs.tryParse(arguments); // null when invalid

Widget page = DetailPageArgs.builder(
  context,
  arguments: arguments,
  notFoundScreen: const NotFoundPage(),
);
```

`DetailPageArgs.argSpecs` lists every key with its kind, requirement, default,
and enum options. `DetailPageArgs.schema` bundles `tryParse`, `builder`, and
`argSpecs` for a router. For typed routing on top of `schema`, see the
`args-generator-annotations-routing` skill from `args_generator_annotations`.

## Faster runs

`dart run` starts the analyzer in JIT mode. A compiled CLI is about three times
faster: `dart install args_generator@<version from pubspec.lock>`, then run
`args_generator` with the same options. It finds the Dart SDK through
`FLUTTER_ROOT` or the `dart` on `PATH`; `--sdk-path` overrides that.
