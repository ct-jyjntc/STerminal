import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/snippet.dart';

final snippetsStreamProvider = StreamProvider<List<Snippet>>(
  (ref) => ref.watch(snippetsRepositoryProvider).watchAll(),
);
