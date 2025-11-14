import '../../domain/models/snippet.dart';
import '../local/local_collection_repository.dart';

class SnippetsRepository extends LocalCollectionRepository<Snippet> {
  SnippetsRepository({
    required super.prefs,
  }) : super(
          storageKey: 'snippets/v1',
          decoder: Snippet.fromJson,
          encoder: (value) => value.toJson(),
        );
}
