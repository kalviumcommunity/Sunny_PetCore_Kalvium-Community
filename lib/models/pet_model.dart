// This model represents a Pet in the PetCore system.
// It holds the 9 required details: Pet ID, Name, Species, Breed, Gender, DOB/Age, Weight, Color, Owner ID.
class PetModel {
  final String? id;       // Document ID assigned by Firestore
  final String petId;     // Unique Pet Identifier (e.g. PET-001)
  final String name;      // Pet name
  final String species;   // Species (e.g. Dog, Cat, Bird)
  final String breed;     // Breed (e.g. Labrador Retriever)
  final String gender;    // Gender (Male / Female)
  final String dobAge;    // Date of Birth or approximate age
  final double weight;    // Weight in kilograms
  final String color;     // Color or markings
  final String ownerId;   // ID of the owner who owns this pet

  PetModel({
    this.id,
    required this.petId,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.dobAge,
    required this.weight,
    required this.color,
    required this.ownerId,
  });

  // Converts this Pet object into a Map (key-value pairs) to save into Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'dobAge': dobAge,
      'weight': weight,
      'color': color,
      'ownerId': ownerId,
    };
  }

  // Creates a Pet object from a Map retrieved from Firestore
  factory PetModel.fromMap(Map<String, dynamic> map, String id) {
    return PetModel(
      id: id,
      petId: map['petId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      breed: map['breed'] ?? '',
      gender: map['gender'] ?? '',
      dobAge: map['dobAge'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] ?? '',
      ownerId: map['ownerId'] ?? '',
    );
  }
}
