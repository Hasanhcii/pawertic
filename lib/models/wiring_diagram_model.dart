class WiringDiagramModel {
  String id, model, category, details;
  List<String> images;

  WiringDiagramModel({
    required this.id,
    required this.model,
    required this.category,
    required this.details,
    required this.images,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'model': model,
    'category': category,
    'details': details,
    'images': images,
  };

  factory WiringDiagramModel.fromMap(Map<String, dynamic> map, String docId) => WiringDiagramModel(
    id: docId,
    model: map['model'] ?? '',
    category: map['category'] ?? '',
    details: map['details'] ?? '',
    images: List<String>.from(map['images'] ?? []),
  );
}
