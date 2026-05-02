class DashboardSectionLine {
  const DashboardSectionLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class ChildDashboardSnapshot {
  const ChildDashboardSnapshot({
    required this.name,
    required this.gradeLabel,
    required this.taskSummary,
    required this.accuracyLabel,
    required this.streakLabel,
    required this.progress,
    required this.weaknessHighlights,
  });

  final String name;
  final String gradeLabel;
  final String taskSummary;
  final String accuracyLabel;
  final String streakLabel;
  final double progress;
  final List<String> weaknessHighlights;
}

class HomeDashboardSnapshot {
  const HomeDashboardSnapshot({
    required this.children,
    required this.bookHighlights,
    required this.todayHighlights,
    required this.parentHighlights,
  });

  final List<ChildDashboardSnapshot> children;
  final List<DashboardSectionLine> bookHighlights;
  final List<DashboardSectionLine> todayHighlights;
  final List<DashboardSectionLine> parentHighlights;
}
