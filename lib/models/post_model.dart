class Post {
  final String id;
  final String caption;
  final List<String> images;
  final String? location;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.caption,
    required this.images,
    this.location,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      caption: json['caption'],
      images: List<String>.from(json['images']),
      location: json['location'],
      userId: json['user'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'images': images,
      if (location != null) 'location': location,
    };
  }
}
