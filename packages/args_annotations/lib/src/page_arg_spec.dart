/// How the value of a generated route argument is written.
enum PageArgKind {
  /// An `int`.
  integer,

  /// A `double`.
  decimal,

  /// A `num`.
  number,

  /// A `BigInt`.
  bigInteger,

  /// A `String`.
  text,

  /// A `bool`, written as `true` or `false`.
  flag,

  /// A `DateTime`, written in ISO 8601.
  dateTime,

  /// A `Uri`.
  uri,

  /// An enum value, written as its `name`.
  choice,

  /// A `List` or `Iterable`, written as comma-separated values.
  list,
}

/// Describes one argument a generated `*Args` class reads from route
/// arguments.
///
/// The generator emits a `static const argSpecs` list of these next to
/// `tryParse`, so tools can build or validate arguments without repeating the
/// keys and types by hand.
class PageArgSpec {
  /// Creates a description of the argument stored under [key].
  const PageArgSpec(
    this.key,
    this.kind, {
    this.isRequired = false,
    this.defaultValue,
    this.options = const [],
  });

  /// The argument key: the constructor parameter name in kebab-case.
  final String key;

  /// How the argument value is written.
  final PageArgKind kind;

  /// Whether the page needs a value: the parameter is required,
  /// non-nullable, has no default and is not a [PageArgKind.flag].
  final bool isRequired;

  /// The constructor default of the parameter, or `null` without one.
  final Object? defaultValue;

  /// The values a [PageArgKind.choice] argument accepts.
  final List<Enum> options;
}
