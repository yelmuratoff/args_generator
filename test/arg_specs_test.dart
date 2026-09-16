import 'dart:io';

import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

String _prefixOf(String generated, String uriSuffix) {
  final match = RegExp(
    "import '[^']*${RegExp.escape(uriSuffix)}' as (_i\\d+);",
  ).firstMatch(generated);
  expect(match, isNotNull, reason: 'missing import of $uriSuffix');
  return match!.group(1)!;
}

void main() {
  group('argSpecs', () {
    late String generated;
    late String annotations;
    late String spec;
    late String kind;
    late String page;

    setUpAll(() async {
      final output = File(
        '${Directory.systemTemp.createTempSync('arg_specs').path}'
        '/router.args.g.dart',
      );

      final summary = await ArgsGeneratorCliRunner().run(
        projectRoot: Directory.current,
        includePaths: ['test/fixtures/arg_specs'],
        outputPath: output.path,
        verbose: false,
        clean: false,
      );

      expect(summary.errors, 0);
      generated = output.readAsStringSync();
      annotations = _prefixOf(
        generated,
        'package:args_generator_annotations/args_annotations.dart',
      );
      spec = '$annotations.PageArgSpec';
      kind = '$annotations.PageArgKind';
      page = _prefixOf(generated, '/test/fixtures/arg_specs/specs_page.dart');
    });

    test('binds the args class into a PageArgs schema', () {
      expect(
        generated,
        contains('class SpecsPageArgs implements $annotations.PageArgs {'),
      );
      expect(
        generated,
        contains('@override\n  Map<String, String> toArguments() => {'),
      );
      expect(
        generated,
        contains(
          'static const schema = $annotations.PageArgsSchema<SpecsPageArgs, '
          'BuildContext, Widget>(\n'
          '    tryParse: tryParse,\n'
          '    builder: builder,\n'
          '    argSpecs: argSpecs,\n'
          '  );',
        ),
      );
    });

    test('lists every constructor parameter under its argument key', () {
      expect(generated, contains('static const List<$spec> argSpecs = ['));
      for (final line in [
        "$spec('id', $kind.integer, isRequired: true),",
        "$spec('title', $kind.text, isRequired: true),",
        "$spec('tags', $kind.list, isRequired: true),",
        "$spec('ratio', $kind.decimal, isRequired: true),",
        "$spec('total', $kind.number, isRequired: true),",
        "$spec('big', $kind.bigInteger, isRequired: true),",
        "$spec('created-at', $kind.dateTime, isRequired: true),",
        "$spec('link', $kind.uri, isRequired: true),",
      ]) {
        expect(generated, contains(line));
      }
    });

    test('never requires a flag, a nullable or a defaulted parameter', () {
      for (final line in [
        "$spec('is-pinned', $kind.flag),",
        "$spec('note', $kind.text),",
        "$spec('count', $kind.integer, defaultValue: 3),",
      ]) {
        expect(generated, contains(line));
      }
    });

    test('offers the enum values of a choice', () {
      for (final line in [
        "$spec('mode', $kind.choice, isRequired: true, "
            'options: $page.SpecsMode.values),',
        "$spec('fallback-mode', $kind.choice, "
            'defaultValue: $page.SpecsMode.dark, '
            'options: $page.SpecsMode.values),',
        "$spec('optional-mode', $kind.choice, "
            'options: $page.SpecsMode.values),',
      ]) {
        expect(generated, contains(line));
      }
    });
  });
}
