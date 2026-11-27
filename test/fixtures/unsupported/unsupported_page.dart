import 'package:args_generator_annotations/args_annotations.dart';

@GenerateArgs()
class UnsupportedPage {
  const UnsupportedPage({required this.ids});

  final List<int> ids;
}
