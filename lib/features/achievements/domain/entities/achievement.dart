import 'package:equatable/equatable.dart';

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final bool isPersisted; // New field to track DB status
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final String? progressLabel;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    this.isUnlocked = false,
    this.isPersisted = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.progressLabel,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconPath,
        isUnlocked,
        isPersisted,
        unlockedAt,
        progress,
        progressLabel,
      ];
}
