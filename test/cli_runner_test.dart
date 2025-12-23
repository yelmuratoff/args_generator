import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  test('wrapAsPartForCli produces stable header', () {
    final out = wrapAsPartForCli(
      partOfUri: 'test_page.dart',
      body: 'class X {}',
    );

    expect(out, contains("part of 'test_page.dart';"));
    expect(out, contains('class X {}'));
    expect(out, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'));
  });

  test('argsOutputForLibrary replaces extension', () {
    expect(
      argsOutputForLibrary('/a/b/test_page.dart'),
      '/a/b/test_page.args.g.dart',
    );
  });

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
