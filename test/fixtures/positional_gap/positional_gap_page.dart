import 'package:args_generator_annotations/args_annotations.dart';

@GenerateArgs()
class PositionalGapPage {
  const PositionalGapPage([this.onTap, this.id = 0]);

  final void Function()? onTap;
  final int id;
}
