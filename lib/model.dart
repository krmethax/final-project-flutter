class Products {
  final String id;
  final DateTime created;
  final DateTime updated;

  String title;
  double price;
  String? category;
  String? description;
  String? image;

  Products({
    required this.id,
    required this.created,
    required this.updated,
    required this.title,
    required this.price,
    this.category,
    this.description,
    this.image,
  });

  factory Products.fromRecord(Map<String, dynamic> r) {
    return Products(
      id: r['id'] as String,
      created: DateTime.parse(r['created'] as String),
      updated: DateTime.parse(r['updated'] as String),
      title: r['title'] ?? '',
      price: (r['price'] is int)
          ? (r['price'] as int).toDouble()
          : (r['price'] ?? 0.0),
      category: r['category'],
      description: r['description'],
      image: r['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'category': category,
      'description': description,
      'image': image,
    };
  }
}
