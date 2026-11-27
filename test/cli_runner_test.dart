import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  test('shouldDeleteStaleOutput only in clean mode', () {
    expect(
      shouldDeleteStaleOutput(
        clean: true,
        hasAnnotatedElements: false,
        outputExists: true,
      ),
      isTrue,
    );

    expect(
      shouldDeleteStaleOutput(
        clean: false,
        hasAnnotatedElements: false,
        outputExists: true,
      ),
      isFalse,
    );

    expect(
      shouldDeleteStaleOutput(
        clean: true,
        hasAnnotatedElements: true,
        outputExists: true,
      ),
      isFalse,
    );

    expect(
      shouldDeleteStaleOutput(
        clean: true,
        hasAnnotatedElements: false,
        outputExists: false,
      ),
      isFalse,
    );
  });
}
