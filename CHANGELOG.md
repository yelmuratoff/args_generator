## 1.0.5

- Added CLI generation via `dart run args_generator` (no `build_runner` required).
- Added CLI options: `-p/--path` (multiple), `-v/--verbose`, `--fail-on-error`.
- Added `--clean` to delete stale `*.args.g.dart` when a library no longer contains `@GenerateArgs`.
- Refactored generation internals: introduced a BuildStep-free emitter used by the CLI while keeping `build_runner` support intact.
- Updated documentation and added small CLI runner tests.

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
