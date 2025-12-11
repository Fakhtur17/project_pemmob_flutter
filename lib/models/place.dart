enum PlaceType { cafe, restaurant }

class Place {
  final String id;
  final String name;
  final PlaceType type;
  final String address;
  final String openHours;
  final double rating;
  final String imageUrl;
  final String? description;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.openHours,
    required this.rating,
    required this.imageUrl,
    this.description,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'].toString(),
      name: json['name'],
      type: json['type'] == 'cafe' ? PlaceType.cafe : PlaceType.restaurant,
      address: json['address'],
      openHours: json['open_hours'],
      rating: double.parse(json['rating'].toString()),
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type == PlaceType.cafe ? "cafe" : "restaurant",
      "address": address,
      "open_hours": openHours,
      "rating": rating,
      "image_url": imageUrl,
      "description": description,
    };
  }
}
