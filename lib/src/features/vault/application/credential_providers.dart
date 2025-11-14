import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/credential.dart';

final credentialsStreamProvider = StreamProvider<List<Credential>>(
  (ref) => ref.watch(credentialsRepositoryProvider).watchAll(),
);

final credentialByIdProvider = StreamProvider.family<Credential?, String>(
  (ref, id) => ref.watch(credentialsRepositoryProvider).watchById(id),
);
