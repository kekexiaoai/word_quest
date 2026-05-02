import 'adventure_dashboard_snapshot.dart';

abstract class AdventureRepository {
  const AdventureRepository();

  AdventureDashboardSnapshot loadAdventure({
    required String childId,
    required DateTime referenceDate,
  });
}
