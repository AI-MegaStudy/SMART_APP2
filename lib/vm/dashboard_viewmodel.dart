import 'package:flutter/material.dart';
import 'package:smart_app/model/dashboard_model.dart';
import 'package:smart_app/repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository repository;

  DashboardViewModel(this.repository);

  bool isLoading = false;
  String? errorMessage;
  DashboardModel? dashboard;

  Future<void> loadDashboard() async {
    if (isLoading) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      dashboard = await repository.fetchDashboard();
    } catch (_) {
      errorMessage = '대시보드 정보를 불러오지 못했습니다.';
    }

    isLoading = false;
    notifyListeners();
  }
}
