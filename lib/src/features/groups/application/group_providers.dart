import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../domain/models/group.dart';

final groupsStreamProvider = StreamProvider<List<HostGroup>>(
  (ref) => ref.watch(groupsRepositoryProvider).watchAll(),
);
