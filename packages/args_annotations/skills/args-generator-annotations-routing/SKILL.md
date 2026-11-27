---
name: args-generator-annotations-routing
description: Type-check navigation against generated page arguments with PageArgs, PageArgsSchema, and PageArgSpec from args_generator_annotations. Use when wiring *Args.schema into a router or route enum, validating route arguments with argSpecs, or building tooling such as deep-link checks from argument specs.
---

# Typed routing with args_generator_annotations

Every class that `args_generator` generates implements `PageArgs` and exposes
two constants. This package defines their types and has no Flutter dependency.

- `PageArgs.toArguments()` returns the `Map<String, String>` route arguments.
- `static const argSpecs` is a `List<PageArgSpec>`, one per argument
  `tryParse` reads.
- `static const schema` is a `PageArgsSchema<A, BuildContext, Widget>` that
  binds `tryParse`, `builder`, and `argSpecs`. `C` and `W` are the UI
  framework's context and widget types.

## Declare which arguments a route takes

Put the schema on the route, and let the type parameter come from it, so
passing the wrong args class fails to compile:

```dart
enum Routes<A extends PageArgs> {
  detail('detail', args: DetailPageArgs.schema),
  settings('settings');

  const Routes(this.name, {this.args});

  final String name;
  final PageArgsSchema<A, BuildContext, Widget>? args;
}

extension RouteArgumentsX<A extends PageArgs> on Routes<A> {
  Map<String, String> argumentsOf(A args) => args.toArguments();

  Widget build(BuildContext context, Map<String, String> arguments) =>
      args!.builder(context, arguments: arguments);
}
```

Keep such helpers as extension members on the route. A top-level
`push<A extends PageArgs>(Routes<A> route, A args)` infers `A` from both
arguments, widens it to `PageArgs`, and accepts any args class.

## Validate arguments with specs

`PageArgSpec` fields:

- `key`: the parameter name in kebab-case, the key in the route arguments.
- `kind`: a `PageArgKind` (`integer`, `decimal`, `number`, `bigInteger`,
  `text`, `flag`, `dateTime`, `uri`, `choice`, `list`).
- `isRequired`: `true` when the parameter is required, non-nullable, has no
  default, and is not a `flag`.
- `defaultValue`: the constructor default, or `null`.
- `options`: the enum values a `choice` accepts; empty for other kinds.

```dart
List<String> missingKeys(
  PageArgsSchema<PageArgs, Object?, Object?> schema,
  Map<String, String> arguments,
) => [
  for (final spec in schema.argSpecs)
    if (spec.isRequired && !arguments.containsKey(spec.key)) spec.key,
];
```

`schema.tryParse` stays the authority: it also rejects malformed values that a
key check cannot see. Use the specs to report which key is missing, or to build
a deep link or a debug form without repeating the keys by hand.

Regenerate with `args_generator` after changing a page constructor. The specs,
schema, and `toArguments()` keys all follow the constructor.
