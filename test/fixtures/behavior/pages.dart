import 'package:args_generator_annotations/args_annotations.dart';

class BuildContext {
  const BuildContext();
}

class Widget {
  const Widget();
}

class SizedBox extends Widget {
  const SizedBox.shrink();
}

enum Shade { light, dark }

abstract final class Defaults {
  static const pageSize = 20;
}

@GenerateArgs()
class DefaultsPage extends Widget {
  const DefaultsPage({
    this.count = 3,
    this.ratio = 1.5,
    this.total = 7,
    this.isOn = true,
    this.title = 'DefaultsPage',
    this.tags = const ['a', 'b'],
    this.shade = Shade.dark,
    this.optionalCount = 4,
    this.pageSize = Defaults.pageSize,
    this.shorthandShade = .light,
  });

  final int count;
  final double ratio;
  final num total;
  final bool isOn;
  final String title;
  final List<String> tags;
  final Shade shade;
  final int? optionalCount;
  final int pageSize;
  final Shade shorthandShade;
}

@GenerateArgs()
class CallbackPage extends Widget {
  const CallbackPage({required this.id, this.onTap});

  final int id;
  final void Function()? onTap;
}

@GenerateArgs()
class CallbackOnlyPage extends Widget {
  const CallbackOnlyPage({this.onTap});

  final void Function()? onTap;
}

@GenerateArgs()
class PositionalPage extends Widget {
  const PositionalPage(this.id, {this.note});

  final int id;
  final String? note;
}
