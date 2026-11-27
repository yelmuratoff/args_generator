@Timeout(Duration(minutes: 3))
library;

import 'package:args_generator/args_generator.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const _output = 'app|lib/router.args.g.dart';

const _homePage = r'''
import 'package:args_generator_annotations/args_annotations.dart';

enum Mode { light, dark }

@GenerateArgs()
class HomePage {
  const HomePage({
    required this.id,
    this.title = 'HomePage',
    this.mode = Mode.dark,
  });

  final int id;
  final String title;
  final Mode mode;
}
''';

const _unsupportedPage = r'''
import 'package:args_generator_annotations/args_annotations.dart';

@GenerateArgs()
class ListPage {
  const ListPage({required this.ids});

  final List<int> ids;
}
''';

Future<TestBuilderResult> _build(
  Map<String, String> sources, {
  Map<String, Object>? outputs,
  void Function(LogRecord log)? onLog,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'app');
  await readerWriter.testing.loadIsolateSources();
  return testBuilder(
    argsGenerator(const BuilderOptions({'output': 'lib/router.args.g.dart'})),
    sources,
    rootPackage: 'app',
    readerWriter: readerWriter,
    outputs: outputs,
    onLog: onLog,
  );
}

void main() {
  group('build_runner aggregating builder', () {
    test('writes the args class of an annotated page', () async {
      await _build(
        {'app|lib/home_page.dart': _homePage},
        outputs: {
          _output: decodedMatches(
            allOf(
              contains('class HomePageArgs implements '),
              contains("this.title = 'HomePage'"),
              contains(RegExp(r'this\.mode = _i\d+\.Mode\.dark')),
            ),
          ),
        },
      );
    });

    test('writes nothing when no page is annotated', () async {
      await _build({
        'app|lib/plain.dart': 'class Plain {}\n',
      }, outputs: const {});
    });

    test(
      'reports an unsupported required parameter as a severe error',
      () async {
        final severe = <LogRecord>[];
        await _build(
          {'app|lib/list_page.dart': _unsupportedPage},
          onLog: (log) {
            if (log.level >= Level.SEVERE) severe.add(log);
          },
        );

        expect(
          severe.map((log) => '${log.message} ${log.error}'),
          contains(contains('`ids` of ListPage has the unsupported type')),
        );
      },
    );

    test('keeps writing the other pages when one library fails', () async {
      await _build(
        {
          'app|lib/home_page.dart': _homePage,
          'app|lib/list_page.dart': _unsupportedPage,
        },
        outputs: {
          _output: decodedMatches(
            allOf(
              contains('class HomePageArgs implements '),
              isNot(contains('ListPageArgs')),
            ),
          ),
        },
      );
    });
  });
}
