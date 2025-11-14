import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/home/data/actions_data.dart';

final quickActionsProvider = Provider<List<Actions>>((ref) {
  return [
    Actions.again,
    Actions.myRequests,
    Actions.offers,
    Actions.help,
  ];
});
