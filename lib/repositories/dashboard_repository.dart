import 'package:smart_app/model/dashboard_model.dart';
import 'package:smart_app/core/api_service.dart';

class DashboardRepository {
  Future<DashboardModel> fetchDashboard() async {
    try {
      return ApiService.getData<DashboardModel>(
        '/owner/dashboard',
        requiresAuth: true,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return DashboardModel.fromJson(json);
        },
      );
    } catch (_) {
      return DashboardModel.demo();
    }
  }
}
