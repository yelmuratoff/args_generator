/// The entry point for the library that provides code generation functionality
/// for generating page arguments in a Flutter application.
///
/// This library integrates with the `build` package to perform source code
/// generation at compile time. It includes a custom generator for generating
/// page arguments used in routing.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'args_generator.dart';

export 'src/generator.dart';

/// Creates a [Builder] for the `args_generator`.
///
/// The builder utilizes the [SharedPartBuilder] to perform code generation
/// for classes annotated with the `@GenerateArgs` annotation. It relies on
/// the [PageArgsGenerator] class to define the logic for generating the
/// necessary code.
///
/// - [options]: Configuration options for the builder.
///
/// Returns:
/// A [Builder] that integrates with the `build_runner` for source code generation.
Builder pageArgsGenerator(BuilderOptions options) => SharedPartBuilder(
      [PageArgsGenerator()],
      'args_generator',
    );

/// Annotation used to mark classes for which page arguments should be generated.
///
/// When applied to a class, the `@GenerateArgs` annotation triggers the
/// code generation process for that class to create the necessary arguments
/// for routing.
///
/// Example:
/// ```dart
/// @GenerateArgs()
/// class MyPageArgs {
///   final String id;
///   const MyPageArgs(this.id);
/// }
/// ```
///
/// This annotation is used by the `PageArgsGenerator` during the code generation
/// process.
class GenerateArgs {
  /// Creates an instance of the `GenerateArgs` annotation.
  const GenerateArgs();
}
