class ListingModel {
  final String id;
  final String skill;
  final String level;
  final String description;
  final int duration;
  final String mentorId;

  ListingModel({
    required this.id,
    required this.skill,
    required this.level,
    required this.description,
    required this.duration,
    required this.mentorId,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) {
    return ListingModel(
      id: map['id'],
      skill: map['skill'],
      level: map['level'],
      description: map['description'],
      duration: map['duration'],
      mentorId: map['mentor_id'],
    );
  }
}