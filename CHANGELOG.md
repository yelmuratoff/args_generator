## 1.5.0

- Allows `build` 5, so the generator works with `build_runner` 2.17.
- Ships the `args-generator-usage` agent skill; see the README section "Agent skills".
- Fixed a dot-shorthand enum default (`this.mode = .dark`) producing an `argSpecs` entry that did not compile.

- Fixed a string default that spells the name of an imported class (`this.title = 'HomePage'`) being rewritten to `'_i1.HomePage'`. Import prefixes now go only on identifiers in the generated code, never inside strings or comments.
- `tryParse` now falls back to the constructor default of an `int`, `double`, `num`, `bool`, `String` or `List` parameter when its key is missing. Before, a non-nullable parameter with a default made `tryParse` return `null`, and `bool`, `String` and `List` defaults were ignored.
- A default applies only when the key is missing. A nullable enum with a default now reads an unknown value as `null`; it used to fall back to the default.
- Fixed the generated constructor of a page with no supported parameter, which did not compile.
- Fixed `builder` referencing `args.<name>` for a constructor parameter whose type is not supported, which did not compile. Optional parameters of other types are left out; a required one fails generation with an error naming it.
- Fixed `builder` passing positional constructor parameters as named arguments.
- `List` and `Iterable` parameters are supported only with `String` elements. A `List<int>` used to generate code that did not compile.
- The CLI leaves the output file untouched when any library fails to generate, also with `--clean`. Before, it wrote the output without the failed pages, or deleted it.
- The CLI exits with code 64 and a message when no include path exists, instead of throwing.
- Added `--sdk-path`. A natively compiled CLI (`dart install`, `dart compile exe`) finds the Dart SDK through `FLUTTER_ROOT` or the `dart` on `PATH`; it used to fail because it runs outside the SDK.
- The `build_runner` builder keeps no state between builds. A library that fails to generate or resolve is logged as a severe error, which fails the build, and the output keeps the other pages. Before, resolution failures were skipped silently.
- Classes in the aggregated file are sorted by library and class name, so the output no longer depends on file system order.
- Documented that Flutter apps need Flutter 3.47 or newer: earlier releases pin `meta` 1.18.0, which `analyzer` 14 cannot use.

## 1.4.0

- Requires `analyzer` 14, `build` 4 and `source_gen` 4, so the generator runs alongside current `build_runner`, `freezed` and `drift_dev` on Dart 3.10+ SDKs, where `analyzer` 7 fails on dot-shorthand syntax in the Flutter SDK.
- Raised the minimum Dart SDK to 3.11. Projects on older SDKs keep resolving 1.3.0.
- Migrated every builder and the CLI to the analyzer element model and removed the `deprecated_member_use` ignores.
- Generated `*Args` classes and imports are unchanged; the aggregated file may list the classes in a different order.

## 1.3.0

- Generated `*Args` classes implement `PageArgs` and expose `static const argSpecs`: the key, kind, requirement, default and enum values of every argument `tryParse` reads.
- Generated `*Args` classes expose `static const schema`, a `PageArgsSchema` binding `tryParse`, `builder` and `argSpecs`, so a router can declare which arguments a route takes and type-check navigation against them.
- `TypeHelper` reports the `PageArgKind` of the type it handles.
- Fixed generated class names being prefixed (`class _i2.DetailPageArgs`) when a library imported by an annotated page re-exports the generated file.
- Requires `args_generator_annotations` 1.3.0.

## 1.2.6

- Added aggregated CLI generation via `dart run args_generator` (no `build_runner` required).
- Added CLI options: `-p/--path` (multiple), `-o/--output`, `-v/--verbose`, `--fail-on-error`.
- Added `--clean` to delete stale `*.args.g.dart` when a library no longer contains `@GenerateArgs`.
- Refactored generation internals: introduced a BuildStep-free emitter used by the CLI while keeping `build_runner` support intact.
- Reduced analyzer deprecation noise: refactored `TypeHelper` API to work on a lightweight `ArgField` model instead of deprecated analyzer element types.
- Updated internal type utilities to use the new analyzer element model where possible (e.g. `element3` / `library2`).
- Added targeted `deprecated_member_use` ignores in generator/build_runner integration where upstream dependencies still require the legacy element model.

## 1.1.1

- Enhance null and empty checks for Iterable and String type helpers

## 1.1.0

- Page builder replaced by aggregated builder.

## 1.0.7

- Added new aggregated builder.
Please see example project for more details.

## 1.0.4

- If the page has a `wrappedRoute` method, then it will be used in the `builder`.

## 1.0.2

- Added new static method `builder` to the generated class for creating the associated widget from arguments.

## 0.0.9

- Added the `args_annotations' package to fix a bug with `source_gen` that does not work with `Flutter` projects.

## 0.0.8

- Parsing fixed for `null` values.

## 0.0.7

- Skip the complex types.

## 0.0.6

- Fix dart:mirrors issue.

## 0.0.5

- Added `super` fields to args.

## 0.0.4

- `SharedPartBuilder` was replaced with `PartBuilder`.

## 0.0.3

- Updated docs.

## 0.0.2

- Initial version.
