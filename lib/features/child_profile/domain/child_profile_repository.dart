import 'child_profile.dart';

abstract class ChildProfileRepository {
  const ChildProfileRepository();

  List<ChildProfile> loadChildren();
}
