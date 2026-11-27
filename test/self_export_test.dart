import 'dart:convert';
import 'dart:io';

import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

Directory _createPackage() {
  final root = Directory(
    Directory.systemTemp
        .createTempSync('self_export')
        .resolveSymbolicLinksSync(),
  );
  final annotations = Directory('packages/args_annotations').absolute.uri;

  File('${root.path}/pubspec.yaml').writeAsStringSync(
    'name: self_export\n'
    'environment:\n'
    '  sdk: ">=3.8.1 <4.0.0"\n',
  );
  File('${root.path}/.dart_tool/package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {
            'name': 'args_generator_annotations',
            'rootUri': '$annotations',
            'packageUri': 'lib/',
          },
          {'name': 'self_export', 'rootUri': '../', 'packageUri': 'lib/'},
        ],
      }),
    );
  File('${root.path}/lib/router.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync("export 'router.args.g.dart';\n");
  File('${root.path}/lib/detail_page.dart').writeAsStringSync('''
import 'package:args_generator_annotations/args_annotations.dart';
import 'package:self_export/router.dart';

@GenerateArgs()
class DetailPage {
  const DetailPage({required this.id});

  final int id;
}
''');
  return root;
}

void main() {
  test('keeps generated class names unprefixed when the router re-exports '
      'the output into the annotated libraries', () async {
    final root = _createPackage();
    addTearDown(() => root.deleteSync(recursive: true));

    Future<String> generate() async {
      final summary = await ArgsGeneratorCliRunner().run(
        projectRoot: root,
        includePaths: ['lib'],
        outputPath: 'lib/router.args.g.dart',
        verbose: false,
        clean: false,
      );
      expect(summary.errors, 0);
      return File('${root.path}/lib/router.args.g.dart').readAsStringSync();
    }

    await generate();
    final regenerated = await generate();

    expect(regenerated, contains('class DetailPageArgs implements '));
    expect(regenerated, isNot(contains(RegExp(r'_i\d+\.DetailPageArgs'))));
  });
}
