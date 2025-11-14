import '../../domain/models/credential.dart';
import '../local/local_collection_repository.dart';

class CredentialsRepository extends LocalCollectionRepository<Credential> {
  CredentialsRepository({
    required super.prefs,
  }) : super(
          storageKey: 'credentials/v1',
          decoder: Credential.fromJson,
          encoder: (value) => value.toJson(),
        );
}
