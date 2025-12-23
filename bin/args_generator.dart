import 'dart:io';

import 'package:args/args.dart';
import 'package:args_generator/src/cli/cli_runner.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message.',
    )
    ..addMultiOption(
      'path',
      abbr: 'p',
      defaultsTo: const ['lib'],
      help: 'Paths to analyze (relative to current directory).',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Print per-file progress.',
    )
    ..addFlag(
      'fail-on-error',
      defaultsTo: false,
      help: 'Exit with non-zero code if any library fails to generate.',
    )
    ..addFlag(
      'clean',
      defaultsTo: false,
      help: 'Delete stale *.args.g.dart outputs when no @GenerateArgs remain.',
    );

  late final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(_usage(parser));
    exitCode = 64;
    return;
  }

  if (results.flag('help')) {
    stdout.writeln(_usage(parser));
    return;
  }

  final projectRoot = Directory.current;
  final pubspec =
      File('${projectRoot.path}${Platform.pathSeparator}pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln(
      'No pubspec.yaml found in: ${projectRoot.path}\n'
      'Run this command from your Dart/Flutter project root.',
    );
    exitCode = 64;
    return;
  }

  final includePaths = (results.multiOption('path')).toList(growable: false);
  final verbose = results.flag('verbose');
  final failOnError = results.flag('fail-on-error');
  final clean = results.flag('clean');

  final runner = ArgsGeneratorCliRunner();
  final summary = await runner.run(
    projectRoot: projectRoot,
    includePaths: includePaths,
    verbose: verbose,
    clean: clean,
  );

  if (verbose) {
    stdout.writeln('---');
  }
  stdout.writeln(
    'args_generator: generated ${summary.writtenFiles} file(s), '
    'deleted ${summary.deletedFiles}, '
    'skipped ${summary.skippedFiles}, '
    'errors ${summary.errors}.',
  );

  if (failOnError && summary.errors > 0) {
    exitCode = 1;
  }
}

String _usage(ArgParser parser) {
  return [
    'Generates *.args.g.dart without build_runner.',
    '',
    'Usage:',
    '  dart run args_generator [options]',
    '',
    'Options:',
    parser.usage,
  ].join('\n');
}
