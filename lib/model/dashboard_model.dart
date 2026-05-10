class DashboardModel {
  final int openSlots;
  final int newProcurements;
  final int inspectionWaiting;
  final int readyToShip;
  final int returnRequests;

  DashboardModel({
    required this.openSlots,
    required this.newProcurements,
    required this.inspectionWaiting,
    required this.readyToShip,
    required this.returnRequests,
  });

  factory DashboardModel.demo() {
    return DashboardModel(
      openSlots: 0,
      newProcurements: 0,
      inspectionWaiting: 0,
      readyToShip: 0,
      returnRequests: 0,
    );
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      openSlots: _readInt(json, 'open_slots', fallbackKey: 'openSlots'),
      newProcurements: _readInt(
        json,
        'new_procurements',
        fallbackKey: 'newProcurements',
      ),
      inspectionWaiting: _readInt(
        json,
        'quality_waiting',
        fallbackKey: 'inspectionWaiting',
      ),
      readyToShip: _readInt(json, 'ready_to_ship', fallbackKey: 'readyToShip'),
      returnRequests: _readInt(
        json,
        'return_requests',
        fallbackKey: 'returnRequests',
      ),
    );
  }

  static int _readInt(
    Map<String, dynamic> json,
    String key, {
    String? fallbackKey,
  }) {
    final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
