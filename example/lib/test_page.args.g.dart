// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_page.dart';

// **************************************************************************
// PageArgsGenerator
// **************************************************************************

class TestPageArgs {
  const TestPageArgs({
    required this.title,
  });

  final String title;

  /// Tries to parse the arguments from a [Map] and returns an instance of [TestPageArgs].
  /// Returns `null` if parsing fails.
  static TestPageArgs? tryParse(Map<String, String> args) {
    try {
      return TestPageArgs(
        title: args['title'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts the fields of this class into a [Map] of arguments.
  Map<String, String> toArguments() => {'title': title};
}
