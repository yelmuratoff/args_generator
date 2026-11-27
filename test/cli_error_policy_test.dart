import 'dart:io';

import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  group('a library that fails to generate', () {
    late Directory outputDirectory;
    late File output;

    setUp(() {
      outputDirectory = Directory.systemTemp.createTempSync('error_policy');
      output = File('${outputDirectory.path}/router.args.g.dart')
        ..writeAsStringSync('// previous output\n');
    });

    tearDown(() => outputDirectory.deleteSync(recursive: true));

    Future<ArgsGeneratorRunSummary> generate({required bool clean}) {
      return ArgsGeneratorCliRunner().run(
        projectRoot: Directory.current,
        includePaths: ['test/fixtures/unsupported'],
        outputPath: output.path,
        verbose: false,
        clean: clean,
      );
    }

    test(
      'is counted as an error instead of emitting uncompilable code',
      () async {
        final summary = await generate(clean: false);

        expect(summary.errors, 1);
      },
    );

    test('leaves the previous output untouched', () async {
      final summary = await generate(clean: false);

      expect(summary.writtenFiles, 0);
      expect(output.readAsStringSync(), '// previous output\n');
    });

    test('keeps the previous output in clean mode', () async {
      final summary = await generate(clean: true);

      expect(summary.deletedFiles, 0);
      expect(output.existsSync(), isTrue);
    });
  });

  test('fails a page whose supported positional parameter follows an '
      'unsupported one', () async {
    final outputDirectory = Directory.systemTemp.createTempSync('gap');
    addTearDown(() => outputDirectory.deleteSync(recursive: true));

    final summary = await ArgsGeneratorCliRunner().run(
      projectRoot: Directory.current,
      includePaths: ['test/fixtures/positional_gap'],
      outputPath: '${outputDirectory.path}/router.args.g.dart',
      verbose: false,
      clean: false,
    );

    expect(summary.errors, 1);
  });

  test('rejects an sdk path that is not a Dart SDK', () {
    expect(
      ArgsGeneratorCliRunner().run(
        projectRoot: Directory.current,
        includePaths: ['test/fixtures/behavior'],
        outputPath: 'unused.g.dart',
        verbose: false,
        clean: false,
        sdkPath: 'does/not/exist',
      ),
      throwsA(isA<ArgsGeneratorException>()),
    );
  });

  test('rejects include paths that do not exist with a typed exception', () {
    expect(
      ArgsGeneratorCliRunner().run(
        projectRoot: Directory.current,
        includePaths: ['does/not/exist'],
        outputPath: 'unused.g.dart',
        verbose: false,
        clean: false,
      ),
      throwsA(isA<ArgsGeneratorException>()),
    );
  });
}
