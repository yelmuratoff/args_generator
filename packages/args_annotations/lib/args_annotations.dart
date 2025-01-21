library;

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
