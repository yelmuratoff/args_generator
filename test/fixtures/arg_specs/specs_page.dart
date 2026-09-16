import 'package:args_generator_annotations/args_annotations.dart';

enum SpecsMode { light, dark }

@GenerateArgs()
class SpecsPage {
  const SpecsPage({
    required this.id,
    required this.title,
    required this.mode,
    required this.isPinned,
    required this.tags,
    required this.ratio,
    required this.total,
    required this.big,
    required this.createdAt,
    required this.link,
    this.note,
    this.count = 3,
    this.fallbackMode = SpecsMode.dark,
    this.optionalMode,
  });

  final int id;
  final String title;
  final SpecsMode mode;
  final bool isPinned;
  final List<String> tags;
  final double ratio;
  final num total;
  final BigInt big;
  final DateTime createdAt;
  final Uri link;
  final String? note;
  final int count;
  final SpecsMode fallbackMode;
  final SpecsMode? optionalMode;
}
