import 'dart:io';

import 'package:args_generator/src/cli/cli_runner.dart';
import 'package:test/test.dart';

void main() {
  group('detectSdkPath', () {
    late Directory root;
    late String compiledExecutable;

    String createSdk(String path) {
      Directory('$path/lib/_internal').createSync(recursive: true);
      File('$path/version').writeAsStringSync('3.14.0');
      File('$path/bin/dart').createSync(recursive: true);
      return path;
    }

    setUp(() {
      root = Directory(
        Directory.systemTemp
            .createTempSync('sdk_path')
            .resolveSymbolicLinksSync(),
      );
      compiledExecutable = '${root.path}/tools/bin/args_generator';
      File(compiledExecutable).createSync(recursive: true);
    });

    tearDown(() => root.deleteSync(recursive: true));

    test(
      'leaves the SDK to the analyzer when the executable runs from one',
      () {
        final sdk = createSdk('${root.path}/dart-sdk');

        expect(
          detectSdkPath(
            resolvedExecutable: '$sdk/bin/dart',
            environment: const {},
          ),
          isNull,
        );
      },
    );

    test('uses the Dart SDK inside FLUTTER_ROOT for a compiled executable', () {
      final sdk = createSdk('${root.path}/flutter/bin/cache/dart-sdk');

      expect(
        detectSdkPath(
          resolvedExecutable: compiledExecutable,
          environment: {'FLUTTER_ROOT': '${root.path}/flutter'},
        ),
        sdk,
      );
    });

    test('uses the SDK of the dart executable on PATH', () {
      final sdk = createSdk('${root.path}/dart-sdk');

      expect(
        detectSdkPath(
          resolvedExecutable: compiledExecutable,
          environment: {'PATH': '${root.path}/empty:$sdk/bin'},
        ),
        sdk,
      );
    });

    test('throws a typed exception when no SDK can be found', () {
      expect(
        () => detectSdkPath(
          resolvedExecutable: compiledExecutable,
          environment: {'PATH': '${root.path}/empty'},
        ),
        throwsA(isA<ArgsGeneratorException>()),
      );
    });
  }, testOn: '!windows');
}
