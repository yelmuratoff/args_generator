/// The entry point for the library that provides code generation functionality
/// for generating page arguments in a Flutter application.
///
/// This library integrates with the `build` package to perform source code
/// generation at compile time. It includes a custom generator for generating
/// page arguments used in routing.
library;

import 'package:args_generator/args_generator.dart';
import 'package:build/build.dart';

export 'src/generator.dart';
export 'src/agr_generator.dart';

Builder argsGenerator(BuilderOptions options) {
  final mode = options.config['mode'] as String? ?? 'default';
  if (mode == 'aggregated') {
    return aggregatingArgsBuilder(options);
  } else {
    return pageArgsGenerator(options);
  }
}
