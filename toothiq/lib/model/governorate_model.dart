class GovernorateModel {
  final String id;
  final String nameAr;

  const GovernorateModel({
    required this.id,
    required this.nameAr,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    return GovernorateModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
    );
  }
}
