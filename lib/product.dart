enum Category { all, shoes, clothing, beauty, accessories }

class Product {
  final String id;
  final String title;
  final double price;
  final String company;
  final List<String> sizes;
  final String imageUrl;
  final Category category;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.company,
    required this.sizes,
    required this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'company': company,
      'sizes': sizes,
      'category': category.name,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      title: map['title'],
      imageUrl: map['imageUrl'],
      price: (map['price'] as num).toDouble(),
      company: map['company'],
      sizes: List<String>.from(map['sizes'] ?? []),
      category: Category.values.firstWhere((e) => e.name == map['category']),
    );
  }
}
