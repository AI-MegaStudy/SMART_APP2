import 'package:flutter_test/flutter_test.dart';
import 'package:smart_app/model/dashboard_model.dart';

void main() {
  test('DashboardModel maps FastAPI snake_case dashboard payload', () {
    final model = DashboardModel.fromJson({
      'open_slots': 2,
      'new_procurements': '3',
      'quality_waiting': 4.0,
      'ready_to_ship': 5,
      'return_requests': 6,
    });

    expect(model.openSlots, 2);
    expect(model.newProcurements, 3);
    expect(model.inspectionWaiting, 4);
    expect(model.readyToShip, 5);
    expect(model.returnRequests, 6);
  });

  test('DashboardModel keeps legacy camelCase fallback mapping', () {
    final model = DashboardModel.fromJson({
      'openSlots': 7,
      'newProcurements': 8,
      'inspectionWaiting': 9,
      'readyToShip': 10,
      'returnRequests': 11,
    });

    expect(model.openSlots, 7);
    expect(model.newProcurements, 8);
    expect(model.inspectionWaiting, 9);
    expect(model.readyToShip, 10);
    expect(model.returnRequests, 11);
  });

  test('DashboardModel demo fallback keeps owner presentation populated', () {
    final model = DashboardModel.demo();

    expect(model.openSlots, 1);
    expect(model.newProcurements, 2);
    expect(model.inspectionWaiting, 2);
    expect(model.readyToShip, 2);
    expect(model.returnRequests, 1);
    expect(model.hasActivity, isTrue);
  });
}
