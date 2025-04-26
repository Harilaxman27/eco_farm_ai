class EggProduction {
  final int? id; // nullable, as it may be null before inserting into DB
  final String batch;
  final String quality;
  final int quantity;
  final String date;

  EggProduction({
    this.id,
    required this.batch,
    required this.quality,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch': batch,
      'quality': quality,
      'quantity': quantity,
      'date': date,
    };
  }

  factory EggProduction.fromMap(Map<String, dynamic> map) {
    return EggProduction(
      id: map['id'],
      batch: map['batch'],
      quality: map['quality'],
      quantity: map['quantity'],
      date: map['date'],
    );
  }
}
