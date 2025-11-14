import '../../domain/models/host.dart';
import '../local/local_collection_repository.dart';

class HostsRepository extends LocalCollectionRepository<Host> {
  HostsRepository({
    required super.prefs,
  }) : super(
          storageKey: 'hosts/v1',
          decoder: Host.fromJson,
          encoder: (value) => value.toJson(),
        );

  List<Host> byGroup(String? groupId) {
    return snapshot.where((host) => host.groupId == groupId).toList();
  }
}
