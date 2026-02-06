import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/shared/data/actions_data.dart';

final quickActionsProvider = Provider<List<Actions>>((ref) {
  return [
    Actions.newRequests,
    Actions.again,
    Actions.myRequests,
    Actions.help,
  ];
});
