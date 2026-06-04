class TouristObject {
  final String id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String descriptionUz;
  final String descriptionRu;
  final String descriptionEn;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String category;
  final bool isRecommended;
  final double rating;
  final int reviewCount;

  TouristObject({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.descriptionUz,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.category = 'Other',
    this.isRecommended = false,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEn': nameEn,
      'descriptionUz': descriptionUz,
      'descriptionRu': descriptionRu,
      'descriptionEn': descriptionEn,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'category': category,
      'isRecommended': isRecommended ? 1 : 0, // SQLite doesn't have bool, use int
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory TouristObject.fromMap(Map<String, dynamic> map) {
    return TouristObject(
      id: map['id'],
      nameUz: map['nameUz'] ?? '',
      nameRu: map['nameRu'] ?? '',
      nameEn: map['nameEn'] ?? '',
      descriptionUz: map['descriptionUz'] ?? '',
      descriptionRu: map['descriptionRu'] ?? '',
      descriptionEn: map['descriptionEn'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      category: map['category'] ?? 'Other',
      isRecommended: (map['isRecommended'] == 1 || map['isRecommended'] == true),
      rating: map['rating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  // Helper method to get localized name
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }

  // Helper method to get localized description
  String getLocalizedDescription(String languageCode) {
    switch (languageCode) {
      case 'uz':
        return descriptionUz;
      case 'ru':
        return descriptionRu;
      case 'en':
      default:
        return descriptionEn;
    }
  }
}
