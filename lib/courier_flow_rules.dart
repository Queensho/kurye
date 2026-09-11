class CourierFlowRules {
  static const activeStatuses = <String>{
    'accepted',
    'at_pickup',
    'picked_up',
    'at_dropoff',
  };

  static bool isActiveStatus(String? status) =>
      status != null && activeStatuses.contains(status);

  static String? nextStatus(String? status) => switch (status) {
        'accepted' => 'at_pickup',
        'at_pickup' => 'picked_up',
        'picked_up' => 'at_dropoff',
        'at_dropoff' => 'delivered',
        _ => null,
      };

  static bool isPresenceFresh(
    DateTime? lastSeen, {
    DateTime? now,
    Duration timeout = const Duration(minutes: 3),
  }) {
    if (lastSeen == null) return false;
    final reference = now ?? DateTime.now().toUtc();
    return !lastSeen.toUtc().isBefore(reference.toUtc().subtract(timeout));
  }
}
