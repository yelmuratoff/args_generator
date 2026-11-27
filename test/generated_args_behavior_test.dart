import 'dart:convert';
import 'dart:io';

import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

const _driver = r'''
import 'dart:convert';

import 'router.args.g.dart';
import 'PAGES_URI' as pages;

void main() {
  const context = pages.BuildContext();
  final defaults = DefaultsPageArgs.tryParse({})!;
  final explicit = DefaultsPageArgs.tryParse({
    'count': '5',
    'is-on': 'false',
    'title': 'Custom',
    'tags': 'x',
    'shade': 'light',
  })!;
  final callback = CallbackPageArgs.builder(
    context,
    arguments: {'id': '7'},
  ) as pages.CallbackPage;
  final positional = PositionalPageArgs.builder(
    context,
    arguments: {'id': '9', 'note': 'hi'},
  ) as pages.PositionalPage;
  print(jsonEncode({
    'defaults': {
      'count': defaults.count,
      'ratio': defaults.ratio,
      'total': defaults.total,
      'isOn': defaults.isOn,
      'title': defaults.title,
      'tags': defaults.tags,
      'shade': defaults.shade.name,
      'optionalCount': defaults.optionalCount,
      'pageSize': defaults.pageSize,
      'shorthandShade': defaults.shorthandShade.name,
    },
    'explicit': {
      'count': explicit.count,
      'isOn': explicit.isOn,
      'title': explicit.title,
      'tags': explicit.tags,
      'shade': explicit.shade.name,
    },
    'callbackId': callback.id,
    'callbackOnlyBuilt': CallbackOnlyPageArgs.builder(
      context,
      arguments: {},
    ) is pages.CallbackOnlyPage,
    'positional': {'id': positional.id, 'note': positional.note},
  }));
}
''';

void main() {
  group('generated args for the behavior fixture', () {
    late String generated;
    late Map<String, Object?> observed;

    setUpAll(() async {
      final workDirectory = Directory('.dart_tool/args_generator_test/behavior')
        ..createSync(recursive: true);
      addTearDown(() => workDirectory.deleteSync(recursive: true));
      final output = File('${workDirectory.path}/router.args.g.dart');

      final summary = await ArgsGeneratorCliRunner().run(
        projectRoot: Directory.current,
        includePaths: ['test/fixtures/behavior'],
        outputPath: output.path,
        verbose: false,
        clean: false,
      );
      expect(summary.errors, 0);
      generated = output.readAsStringSync();

      final pagesUri = File('test/fixtures/behavior/pages.dart').absolute.uri;
      final driver = File('${workDirectory.path}/driver.dart')
        ..writeAsStringSync(_driver.replaceFirst('PAGES_URI', '$pagesUri'));
      final run = await Process.run(Platform.resolvedExecutable, [
        'run',
        driver.path,
      ]);
      expect(
        run.exitCode,
        0,
        reason: 'generated code failed to run:\n${run.stdout}\n${run.stderr}',
      );
      observed = jsonDecode(run.stdout as String) as Map<String, Object?>;
    });

    test(
      'uses the constructor default of every type when a key is missing',
      () {
        expect(observed['defaults'], {
          'count': 3,
          'ratio': 1.5,
          'total': 7,
          'isOn': true,
          'title': 'DefaultsPage',
          'tags': ['a', 'b'],
          'shade': 'dark',
          'optionalCount': 4,
          'pageSize': 20,
          'shorthandShade': 'light',
        });
      },
    );

    test('prefers a present key over the constructor default', () {
      expect(observed['explicit'], {
        'count': 5,
        'isOn': false,
        'title': 'Custom',
        'tags': ['x'],
        'shade': 'light',
      });
    });

    test('leaves string literals that spell a class name unprefixed', () {
      expect(generated, contains("this.title = 'DefaultsPage'"));
      expect(generated, isNot(contains(RegExp(r"'_i\d+\.DefaultsPage'"))));
    });

    test('builds a page whose constructor has an unsupported optional '
        'parameter', () {
      expect(observed['callbackId'], 7);
    });

    test('passes positional constructor parameters positionally', () {
      expect(observed['positional'], {'id': 9, 'note': 'hi'});
    });

    test('builds a page that has no supported parameter', () {
      expect(observed['callbackOnlyBuilt'], isTrue);
    });
  });
}
