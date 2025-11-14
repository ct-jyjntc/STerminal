import '../../domain/models/group.dart';
import '../local/local_collection_repository.dart';

class GroupsRepository extends LocalCollectionRepository<HostGroup> {
  GroupsRepository({
    required super.prefs,
  }) : super(
          storageKey: 'groups/v1',
          decoder: HostGroup.fromJson,
          encoder: (value) => value.toJson(),
        );
}
