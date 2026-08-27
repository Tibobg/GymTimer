class Exercise {
  final String id;
  final String name;
  final String category;
  final String? imageAsset;
  final String? mediaUrl;
  final double? defaultWeight;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.imageAsset,
    this.mediaUrl,
    this.defaultWeight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'imageAsset': imageAsset,
    'mediaUrl': mediaUrl,
    'defaultWeight': defaultWeight,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    imageAsset: json['imageAsset'],
    mediaUrl: json['mediaUrl'],
    defaultWeight:
        json['defaultWeight'] != null
            ? (json['defaultWeight'] as num).toDouble()
            : null,
  );
}
