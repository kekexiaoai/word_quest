import 'home_dashboard_snapshot.dart';

abstract class HomeDashboardRepository {
  const HomeDashboardRepository();

  HomeDashboardSnapshot loadDashboard({required DateTime referenceDate});
}
