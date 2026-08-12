/// أيقونات البراندات الثابتة المتاحة لصاحب المتجر.
class BrandPresetIcons {
  BrandPresetIcons._();

  static const folder = 'assets/iconbrand';

  static const fileNames = [
    '1111.png',
    '1122.png',
    '1133.png',
    '1144.png',
    '1155.png',
    '1166.png',
  ];

  static List<String> get assetPaths =>
      fileNames.map((name) => '$folder/$name').toList(growable: false);

  static bool isAssetPath(String? path) =>
      path != null && path.startsWith('$folder/');
}
