import 'product.dart';

class Booking {
  final String? id;
  final String userId;
  final String placeId;
  final String placeName;
  final DateTime dateTime;
  final int people;
  final String tableName;
  final List<Product> selectedProducts;

  Booking({
    this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.dateTime,
    required this.people,
    required this.tableName,
    List<Product>? selectedProducts,
  }) : selectedProducts = selectedProducts ?? [];

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      placeId: json['place_id'].toString(),
      placeName: json['place']?['name']?.toString() ?? "Unknown", // ⬅️ FIX
      dateTime: DateTime.parse(json['date_time'].toString()),
      people: int.tryParse(json['people'].toString()) ?? 1,
      tableName: json['table_name'].toString(),
      selectedProducts: (json['products'] as List? ?? [])
          .map((p) => Product.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "place_id": placeId,
      "place_name": placeName,
      "date_time": dateTime.toIso8601String(),
      "people": people,
      "table_name": tableName,
      "products": selectedProducts.map((p) => p.toJson()).toList(),
    };
  }
}
