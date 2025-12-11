class Product {
  final String id;
  final String placeId;
  final String name;
  final int price;
  final String? imageUrl;
  final String? description;

  Product({
    required this.id,
    required this.placeId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      placeId: json['place_id'].toString(),
      name: json['name'],
      price: int.parse(json['price'].toString()),
      imageUrl: json['image_url'], // sesuai field DB
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "place_id": placeId,
      "name": name,
      "price": price,
      "image_url": imageUrl,
      "description": description,
    };
  }
}
