// lib\core\models\food_entry_model.dart
class FoodEntry {
  final int? id;
  final String name;
  final int calories;
  final double? carbsG;
  final double? proteinG;
  final double? fatG;
  final String? mealType;
  final DateTime? loggedAt;

  const FoodEntry({
    this.id,
    required this.name,
    required this.calories,
    this.carbsG,
    this.proteinG,
    this.fatG,
    this.mealType,
    this.loggedAt,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      calories: json['calories'] as int,
      carbsG: json['carbs_g'] != null
          ? double.tryParse(json['carbs_g'].toString())
          : null,
      proteinG: json['protein_g'] != null
          ? double.tryParse(json['protein_g'].toString())
          : null,
      fatG: json['fat_g'] != null
          ? double.tryParse(json['fat_g'].toString())
          : null,
      mealType: json['meal_type'],
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'])
          : null,
    );
  }
}