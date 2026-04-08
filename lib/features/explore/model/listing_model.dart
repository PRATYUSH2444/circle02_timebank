class ListingModel {
  final String id;
  final String skill;
  final String level;
  final String description;
  final int duration;
  final String mentorId;

  final String mentorName;
  final int totalSlots;

  ListingModel({
    required this.id,
    required this.skill,
    required this.level,
    required this.description,
    required this.duration,
    required this.mentorId,
    required this.mentorName,
    required this.totalSlots,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) {
    return ListingModel(
      id: map['id'],
      skill: map['skill'],
      level: map['level'],
      description: map['description'],
      duration: map['duration'],
      mentorId: map['mentor_id'],
      mentorName: map['mentor_name'] ?? "Unknown",
      totalSlots: (map['total_slots'] ?? 0) as int,
    );
  }
}