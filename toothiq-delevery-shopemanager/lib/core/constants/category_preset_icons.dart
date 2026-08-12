/// أيقونات الأقسام الثابتة المتاحة لصاحب المتجر.
class CategoryPresetIcons {
  CategoryPresetIcons._();

  static const folder = 'assets/categaryicon';

  static const fileNames = [
    'ChatGPT Image Aug 11, 2026, 03_53_17 PM 1.png',
    'ChatGPT Image Aug 11, 2026, 03_53_17 PM 2.png',
    'ChatGPT Image Aug 11, 2026, 03_53_17 PM 3.png',
    'ChatGPT Image Aug 11, 2026, 03_53_17 PM 4.png',
    'ChatGPT Image Aug 11, 2026, 03_53_17 PM 5.png',
    'Frame 427321702.png',
    'Frame 427321703.png',
    'Frame 427321704.png',
    'Frame 427321705.png',
    'Frame 427321706.png',
    'Frame 427321707.png',
    'Frame 427321708.png',
    'Frame 427321709.png',
    'Frame 427321710.png',
    'Frame 427321711.png',
    'Frame 427321712.png',
    'Frame 427321713.png',
    'Frame 427321714.png',
    'Frame 427321715.png',
    'Frame 427321716.png',
    'Frame 427321717.png',
    'Frame 427321718.png',
    'Frame 427321719.png',
    'Frame 427321720.png',
    'Frame 427321722.png',
    'Frame 427321723.png',
    'Frame 427321724.png',
    'Frame 427321725.png',
    'Frame 427321727.png',
    'Frame 427321728.png',
    'Frame 427321729.png',
    'Frame 427321730.png',
    'Frame 427321732.png',
    'Frame 427321733.png',
    'Frame 427321734.png',
    'Frame 427321735.png',
    'Frame 427321736.png',
    'Frame 427321737.png',
    'Frame 427321738.png',
    'Frame 427321739.png',
    'Frame 427321740.png',
    'Frame 427321741.png',
    'Frame 427321742.png',
    'Frame 427321743.png',
    'Frame 427321744.png',
  ];

  static List<String> get assetPaths =>
      fileNames.map((name) => '$folder/$name').toList(growable: false);

  static bool isAssetPath(String? path) =>
      path != null && path.startsWith('$folder/');
}
