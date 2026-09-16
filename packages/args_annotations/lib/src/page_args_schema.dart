import 'page_arg_spec.dart';

/// A generated `*Args` class: page arguments that serialize into route
/// arguments.
abstract interface class PageArgs {
  /// The route arguments that [PageArgsSchema.tryParse] reads back.
  Map<String, String> toArguments();
}

/// What a generated `*Args` class knows about its page, bundled for routers
/// and tools.
///
/// The generator emits one as `static const schema`. [C] and [W] are the
/// build context and widget types of the UI framework, which keeps this
/// package free of Flutter.
class PageArgsSchema<A extends PageArgs, C, W> {
  /// Bundles the generated members of an `*Args` class.
  const PageArgsSchema({
    required this.tryParse,
    required this.builder,
    required this.argSpecs,
  });

  /// Parses route arguments, returning `null` when a required one is missing
  /// or malformed.
  final A? Function(Map<String, String> arguments) tryParse;

  /// Builds the page from route arguments, or [notFoundScreen] when
  /// [tryParse] fails.
  final W Function(
    C context, {
    required Map<String, String> arguments,
    W? notFoundScreen,
  })
  builder;

  /// Every argument [tryParse] reads.
  final List<PageArgSpec> argSpecs;
}
