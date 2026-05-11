import 'package:smart_app/model/dashboard_model.dart';
import 'package:smart_app/core/api_service.dart';

class DashboardRepository {
  Future<DashboardModel> fetchDashboard() async {
    try {
      final dashboard = await ApiService.getData<DashboardModel>(
        '/owner/dashboard',
        requiresAuth: true,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return DashboardModel.fromJson(json);
        },
      );
      return dashboard.hasActivity ? dashboard : DashboardModel.demo();
    } catch (_) {
      return DashboardModel.demo();
    }
  }
}
