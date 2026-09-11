import 'package:flutter_test/flutter_test.dart';
import 'package:kurye/courier_flow_rules.dart';

void main() {
  group('CourierFlowRules', () {
    test('active shipment statuses are resumable', () {
      expect(CourierFlowRules.isActiveStatus('accepted'), isTrue);
      expect(CourierFlowRules.isActiveStatus('at_pickup'), isTrue);
      expect(CourierFlowRules.isActiveStatus('picked_up'), isTrue);
      expect(CourierFlowRules.isActiveStatus('at_dropoff'), isTrue);
      expect(CourierFlowRules.isActiveStatus('delivered'), isFalse);
      expect(CourierFlowRules.isActiveStatus('cancelled'), isFalse);
    });

    test('shipment status order is strict', () {
      expect(CourierFlowRules.nextStatus('accepted'), 'at_pickup');
      expect(CourierFlowRules.nextStatus('at_pickup'), 'picked_up');
      expect(CourierFlowRules.nextStatus('picked_up'), 'at_dropoff');
      expect(CourierFlowRules.nextStatus('at_dropoff'), 'delivered');
      expect(CourierFlowRules.nextStatus('delivered'), isNull);
      expect(CourierFlowRules.nextStatus('searching'), isNull);
    });

    test('courier presence expires after three minutes', () {
      final now = DateTime.utc(2026, 9, 12, 0, 0, 0);
      expect(
        CourierFlowRules.isPresenceFresh(
          now.subtract(const Duration(minutes: 2, seconds: 59)),
          now: now,
        ),
        isTrue,
      );
      expect(
        CourierFlowRules.isPresenceFresh(
          now.subtract(const Duration(minutes: 3, seconds: 1)),
          now: now,
        ),
        isFalse,
      );
      expect(CourierFlowRules.isPresenceFresh(null, now: now), isFalse);
    });
  });
}
