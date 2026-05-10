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
      openSlots: 6,
      newProcurements: 4,
      inspectionWaiting: 7,
      readyToShip: 3,
      returnRequests: 2,
    );
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      openSlots: _readInt(json, 'openSlots'),
      newProcurements: _readInt(json, 'newProcurements'),
      inspectionWaiting: _readInt(json, 'inspectionWaiting'),
      readyToShip: _readInt(json, 'readyToShip'),
      returnRequests: _readInt(json, 'returnRequests'),
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
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
