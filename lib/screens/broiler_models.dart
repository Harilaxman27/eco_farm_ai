class Broiler {
  int? id;
  String name;
  int numberOfHens;
  String breed;
  double initialWeight;
  double currentWeight;
  double feedConsumed;
  String healthStatus;
  String medication;
  String status; // alive or dead
  String date;
  bool isVaccinated; // ✅ NEW FIELD

  Broiler({
    this.id,
    required this.name,
    required this.numberOfHens,
    required this.breed,
    required this.initialWeight,
    required this.currentWeight,
    required this.feedConsumed,
    required this.healthStatus,
    required this.medication,
    required this.status,
    required this.date,
    this.isVaccinated = false, // ✅ default to false
  });

  // Convert Broiler object to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'numberOfHens': numberOfHens,
      'breed': breed,
      'initialWeight': initialWeight,
      'currentWeight': currentWeight,
      'feedConsumed': feedConsumed,
      'healthStatus': healthStatus,
      'medication': medication,
      'status': status,
      'date': date,
      'isVaccinated': isVaccinated ? 1 : 0, // Store as 1 (true) or 0 (false)
    };
  }

  // Create a Broiler object from Map data
  factory Broiler.fromMap(Map<String, dynamic> map) {
    return Broiler(
      id: map['id'],
      name: map['name'],
      numberOfHens: map['numberOfHens'],
      breed: map['breed'],
      initialWeight: map['initialWeight'],
      currentWeight: map['currentWeight'],
      feedConsumed: map['feedConsumed'],
      healthStatus: map['healthStatus'],
      medication: map['medication'],
      status: map['status'],
      date: map['date'],
      isVaccinated: map['isVaccinated'] == 1, // Convert 1 or 0 back to bool
    );
  }
}
