import 'package:smart_app/model/dashboard_model.dart';
import 'package:smart_app/core/api_debug_log.dart';
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
      if (dashboard.hasActivity) {
        ApiDebugLog.ok(
          'dashboard',
          'open=${dashboard.openSlots}, procurement=${dashboard.newProcurements}, '
              'quality=${dashboard.inspectionWaiting}, ship=${dashboard.readyToShip}, '
              'return=${dashboard.returnRequests}',
        );
        return dashboard;
      }
      ApiDebugLog.fallbackReason(
        'dashboard',
        'API 호출은 성공했지만 전체 값이 0이라 발표용 demo 값을 사용합니다.',
      );
      return DashboardModel.demo();
    } catch (error) {
      ApiDebugLog.fallback('dashboard', error, message: '대시보드 API 실패');
      return DashboardModel.demo();
    }
  }
}
