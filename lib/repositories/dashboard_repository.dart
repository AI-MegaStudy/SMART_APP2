import 'package:smart_app/model/dashboard_model.dart';
import 'package:smart_app/core/api_service.dart';

class DashboardRepository {
  Future<DashboardModel> fetchDashboard() async {
    try {
      final data = await ApiService.get('/owner/dashboard');
      return DashboardModel.fromJson(data);
    } catch (_) {
      return DashboardModel.demo();
    }
  }
}
