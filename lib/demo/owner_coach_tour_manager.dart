// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/view/farm_detail_page.dart';
import 'package:smart_app/view/harvest_slot_page.dart';
import 'package:smart_app/view/orders_page.dart';
import 'package:smart_app/view/owner_detail_page.dart';
import 'package:smart_app/view/procurement_page.dart';
import 'package:smart_app/view/procurement_status_page.dart';
import 'package:smart_app/view/product_add_page.dart';
import 'package:smart_app/view/product_page.dart';
import 'package:smart_app/view/quality_page.dart';
import 'package:smart_app/view/return_page.dart';
import 'package:smart_app/view/return_status_page.dart';
import 'package:smart_app/view/shipment_page.dart';
import 'package:smart_app/view/shipment_status_page.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

const _coachAccent = Color(0xffC04A6A);
const _coachShadow = Color(0xff4A3438);

class _CoachTourCancelled implements Exception {
  const _CoachTourCancelled();
}

class OwnerCoachTourManager {
  OwnerCoachTourManager({required this.context, required this.selectTab});

  final BuildContext context;
  final ValueChanged<int> selectTab;
  bool _running = false;
  TutorialCoachMark? _coach;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    final navigator = Navigator.of(context);

    Future<void> root() async {
      _coach?.finish();
      navigator.popUntil((route) => route.isFirst);
      await _wait();
    }

    try {
      await root();
      selectTab(1);
      await _show(
        key: DemoTargetKeys.homeGreeting,
        title: '점주 업무 홈',
        message: '오늘 처리할 선별, 발주, 배송, 반품 현황을 한눈에 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.dashboardQuality,
        title: '선별 대기',
        message: '출고 전에 품질 확인이 필요한 상품 수를 바로 확인합니다.',
      );
      await _push(const QualityPage(demoAutoImage: true));
      await _show(
        key: DemoTargetKeys.qualityTarget,
        title: '검사 대상 선택',
        message: '발주 승인된 상품 중 실제 검사할 품목을 선택합니다.',
      );
      await root();
      selectTab(1);
      await _wait();
      await _show(
        key: DemoTargetKeys.dashboardProcurement,
        title: '신규 발주',
        message: '고객 결제가 끝난 뒤 출고 가능 여부를 확인해야 하는 주문입니다.',
      );
      await _push(const ProcurementPage());
      await _show(
        key: DemoTargetKeys.procurementFirst,
        title: '발주 요청 카드',
        message: '상품, 수량, 고객 주문 정보를 확인한 뒤 승인 수량을 결정합니다.',
      );
      await root();
      selectTab(1);
      await _wait();
      await _show(
        key: DemoTargetKeys.dashboardShipment,
        title: '배송 준비',
        message: '승인이 끝나 출고 등록을 기다리는 상품입니다.',
      );
      await _push(const ShipmentPage(demoAutofill: true));
      await _show(
        key: DemoTargetKeys.shipmentProduct,
        title: '배송 상품 선택',
        message: '승인된 발주 상품을 선택하고 송장번호를 입력해 배송을 등록합니다.',
      );
      await root();
      selectTab(1);
      await _wait();
      await _show(
        key: DemoTargetKeys.dashboardReturn,
        title: '반품 요청',
        message: '배송 후 고객이 요청한 반품/환불 건입니다.',
      );
      await _push(const ReturnPage());
      await _show(
        key: DemoTargetKeys.returnList,
        title: '반품 요청',
        message: '요청 사유와 상품 정보를 확인한 뒤 승인 또는 거절을 처리합니다.',
      );

      await root();
      selectTab(1);
      await _wait();
      await _show(
        key: DemoTargetKeys.navMenu,
        title: '전체 메뉴',
        message: '상품 등록부터 배송과 사후 처리까지 주요 업무로 이동합니다.',
      );
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuProduct,
        title: '상품 관리',
        message: '고객에게 노출할 상품, 포장 단위, 가격, 이미지를 관리합니다.',
      );
      await _push(const ProductPage());
      await _show(
        key: DemoTargetKeys.productAdd,
        title: '상품 추가',
        message: '판매할 상품 정보를 입력하고 등록 전 내용을 확인합니다.',
      );
      await _push(
        const ProductAddPage(
          farmId: 3,
          demoPreset: true,
          demoImageAsset:
              'assets/images/owner_demo/demo_register_yanggwang_product.png',
        ),
      );
      await _show(
        key: DemoTargetKeys.productAddVariety,
        title: '품종 선택',
        message: '품종은 고객에게 보이는 상품명과 수확 일정 관리의 기준이 됩니다.',
      );
      await _show(
        key: DemoTargetKeys.productAddPackage,
        title: '포장 단위',
        message: '고객이 예약하고 결제할 박스 단위를 정합니다.',
      );
      await _show(
        key: DemoTargetKeys.productAddImage,
        title: '대표 이미지',
        message: '고객이 상품을 고를 때 먼저 보는 대표 사진을 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.productAddPrice,
        title: '기본 판매가',
        message: '권장가를 참고해 점주가 최종 판매가를 조정합니다.',
      );
      await _show(
        key: DemoTargetKeys.productAddSave,
        title: '등록 직전',
        message: '가격과 표시 수량까지 확인한 뒤 상품 등록을 마무리합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuHarvest,
        title: '수확 예측',
        message: '최근 수확 실적과 재배 조건을 바탕으로 예약 가능한 물량을 계산합니다.',
      );
      await _push(const HarvestSlotPage(demoAutoPredict: true));
      await _show(
        key: DemoTargetKeys.harvestProduct,
        title: '예측 상품',
        message: '등록된 상품 중 예약 물량을 산정할 상품을 선택합니다.',
      );
      await _show(
        key: DemoTargetKeys.harvestYield,
        title: '최근 수확 기준',
        message: '최근 수확량과 재배 면적을 기준으로 올해 예약 가능량을 잡습니다.',
      );
      await _show(
        key: DemoTargetKeys.harvestFeatures,
        title: '예측 기준',
        message: '수확량, 면적, 가격, 재배 조건을 확인해 예측 기준을 점검합니다.',
      );
      await _show(
        key: DemoTargetKeys.harvestPredict,
        title: '수확량 예측',
        message: '입력한 조건으로 예상 수확 시기와 예약 가능 물량을 계산합니다.',
      );
      await _show(
        key: DemoTargetKeys.harvestResultChart,
        title: '예측 결과',
        message: '예상 수확량과 권장 예약량을 차트와 숫자로 확인합니다.',
        contextAttempts: 80,
      );
      await _show(
        key: DemoTargetKeys.harvestResultMetrics,
        title: '권장 예약 범위',
        message: '실제 수확 변동을 감안해 무리 없는 예약 범위를 확인합니다.',
        contextAttempts: 80,
      );
      await _show(
        key: DemoTargetKeys.harvestConfidence,
        title: '예측 신뢰도',
        message: '예측 결과를 어느 정도 예약에 반영할지 참고합니다.',
        contextAttempts: 80,
      );
      await _show(
        key: DemoTargetKeys.harvestOpenSlot,
        title: '슬롯 확정',
        message: '점주가 기간, 예약량, 판매가를 최종 확인한 뒤 고객 예약 슬롯을 엽니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuOrders,
        title: '주문 현황',
        message: '고객 예약과 결제 결과가 점주 화면에 어떻게 들어오는지 확인합니다.',
      );
      final ordersSection = ValueNotifier<String>('주문');
      await _push(
        OrdersPage(
          demoMode: true,
          demoAutoSwitchReservations: false,
          demoSectionListenable: ordersSection,
        ),
      );
      await _show(
        key: DemoTargetKeys.ordersSection,
        title: '주문 목록',
        message: '결제가 완료된 주문을 확인하고 출고 준비 단계로 넘깁니다.',
      );
      await _show(
        key: DemoTargetKeys.ordersPaid,
        title: '결제 완료 주문',
        message: '고객 결제가 완료된 주문은 이후 발주 승인과 배송 처리로 이어집니다.',
      );
      ordersSection.value = '예약';
      await _wait();
      await _show(
        key: DemoTargetKeys.reservationsSection,
        title: '예약 목록',
        message: '결제 전 예약은 주문과 분리해 남은 예약 상태로 관리합니다.',
      );
      await _show(
        key: DemoTargetKeys.reservationKeep,
        title: '예약 유지',
        message: '아직 결제로 전환되지 않은 예약도 점주 화면에서 상태를 구분해 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.reservationConverted,
        title: '주문 전환 예약',
        message: '예약이 결제로 이어지면 주문 목록에서 이어서 처리합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuProcurement,
        title: '발주 승인',
        message: '결제 완료 주문을 실제 출고 가능한 수량으로 승인하는 단계입니다.',
      );
      await _push(const ProcurementPage(demoOpenFirst: true));
      await _show(
        key: DemoTargetKeys.procurementFirst,
        title: '발주 요청 카드',
        message: '주문 상품과 수량을 확인하고 출고 가능 여부를 결정합니다.',
      );
      await _show(
        key: DemoTargetKeys.procurementApproveAll,
        title: '전체 승인',
        message: '주문 전체를 승인하거나 품목별로 승인 수량을 조정할 수 있습니다.',
        contextAttempts: 90,
      );
      await _show(
        key: DemoTargetKeys.procurementItemQuantity,
        title: '품목별 승인 수량',
        message: '실제 출고 가능한 수량을 품목별로 조정할 수 있습니다.',
        contextAttempts: 90,
      );
      await _show(
        key: DemoTargetKeys.procurementSave,
        title: '결정 저장',
        message: '저장된 승인 결과는 배송 준비 목록으로 이어집니다.',
        contextAttempts: 90,
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuProcurementStatus,
        title: '발주 현황',
        message: '승인 대기, 승인, 부분 승인, 거절 상태를 주문별로 확인합니다.',
      );
      await _push(const ProcurementStatusPage());
      await _show(
        key: DemoTargetKeys.procurementStatusItem,
        title: '발주 상태',
        message: '각 주문이 현재 어떤 처리 단계에 있는지 확인합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuQuality,
        title: '신선도 검사',
        message: '출고 전 이미지를 분석해 추천 등급과 품질 점수를 확인합니다.',
      );
      await _push(
        const QualityPage(demoAutoImage: true, demoAutoAnalyze: true),
      );
      await _show(
        key: DemoTargetKeys.qualityTarget,
        title: '검사 대상',
        message: '승인된 발주 품목 중 출고 전 검사할 대상을 선택합니다.',
      );
      await _show(
        key: DemoTargetKeys.qualityImage,
        title: '검사 이미지',
        message: '촬영하거나 선택한 사진으로 상품 상태를 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.qualityAnalyze,
        title: '분석 실행',
        message: '사진을 기준으로 등급과 신선도 점수를 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.qualityResult,
        title: '검사 결과',
        message: '추천 등급, 신선도, 색상, 형태, 멍 가능성을 한 번에 확인합니다.',
        contextAttempts: 120,
      );
      await _show(
        key: DemoTargetKeys.qualityDecision,
        title: '추천 판정',
        message: '검사 결과를 참고해 출고 가능 여부를 최종 확인합니다.',
        contextAttempts: 120,
      );
      await _show(
        key: DemoTargetKeys.qualityOwnerGrade,
        title: '점주 확정 등급',
        message: '추천 등급을 참고해 점주가 최종 상품 등급을 확정합니다.',
      );
      await _show(
        key: DemoTargetKeys.qualityOwnerDecision,
        title: '점주 판정',
        message: '출고, 보류, 재촬영 같은 최종 업무 판단을 선택합니다.',
      );
      await _show(
        key: DemoTargetKeys.qualitySave,
        title: '점주 최종 저장',
        message: '확정한 등급과 출고 판단을 저장해 배송 단계로 넘깁니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuShipment,
        title: '배송 관리',
        message: '승인된 상품을 선택하고 송장번호를 등록해 출고 처리합니다.',
      );
      await _push(const ShipmentPage(demoAutofill: true));
      await _show(
        key: DemoTargetKeys.shipmentScan,
        title: '송장 스캔',
        message: '송장을 스캔하거나 직접 입력해 배송 정보를 빠르게 등록합니다.',
      );
      await _show(
        key: DemoTargetKeys.shipmentProduct,
        title: '배송 상품',
        message: '승인된 발주 상품을 선택해 출고 대상을 확정합니다.',
      );
      await _show(
        key: DemoTargetKeys.shipmentInvoice,
        title: '송장번호',
        message: '송장번호와 포장 수량을 입력해 고객이 배송 상태를 확인할 수 있게 합니다.',
      );
      await _show(
        key: DemoTargetKeys.shipmentRegister,
        title: '배송 등록',
        message: '등록 후 배송 현황에서 발송 상태를 이어서 관리합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuShipmentStatus,
        title: '배송 현황',
        message: '배송 대기, 배송 중, 배송 완료 상태를 송장 기준으로 확인합니다.',
      );
      await _push(const ShipmentStatusPage());
      await _show(
        key: DemoTargetKeys.shipmentStatusItem,
        title: '배송 상태',
        message: '송장번호와 현재 배송 단계를 주문별로 확인합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuReturn,
        title: '반품 · 환불 관리',
        message: '배송 후 고객 반품 요청의 사유와 증빙 이미지를 확인합니다.',
      );
      await _push(const ReturnPage(demoOpenFirst: true));
      await _show(
        key: DemoTargetKeys.returnList,
        title: '반품 요청',
        message: '고객의 반품 요청 건을 선택해 상세 사유와 증빙을 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.returnEvidence,
        title: '고객 첨부 이미지',
        message: '손상 반품의 경우 손상 박스 이미지를 보고 환불 여부를 판단합니다.',
      );
      await _show(
        key: DemoTargetKeys.returnAmount,
        title: '승인 금액',
        message: '구매 금액과 요청 사유를 보고 환불 승인 금액을 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.returnApprove,
        title: '환불 승인',
        message: '승인 금액을 확인하고 환불 처리 직전까지 진행합니다.',
      );

      await root();
      selectTab(0);
      await _wait();
      await _show(
        key: DemoTargetKeys.menuReturnStatus,
        title: '반품 · 환불 현황',
        message: '접수, 승인, 거절, 환불 완료 상태를 항목 단위로 추적합니다.',
      );
      await _push(const ReturnStatusPage());
      await _show(
        key: DemoTargetKeys.returnStatusItem,
        title: '반품 상태',
        message: '접수된 반품 건이 승인, 거절, 환불 중 어디까지 진행됐는지 확인합니다.',
      );

      await root();
      selectTab(1);
      await _wait();
      await _show(
        key: DemoTargetKeys.navProfile,
        title: '마이',
        message: '업무 흐름을 마친 뒤 점주와 농장 기본 정보를 관리합니다.',
      );
      selectTab(2);
      await _wait();
      await _show(
        key: DemoTargetKeys.profileOwnerInfo,
        title: '내 정보 수정',
        message: '이름, 전화번호, 사업자번호 등 점주 기본 정보를 관리합니다.',
      );
      await _push(const OwnerDetailPage());
      await _show(
        key: DemoTargetKeys.ownerDetailName,
        title: '점주 이름',
        message: '고객과 운영 화면에 표시되는 점주 기본 정보를 확인합니다.',
      );
      await _show(
        key: DemoTargetKeys.ownerDetailPhone,
        title: '연락처',
        message: '배송, 문의, 운영 알림에 필요한 연락처를 관리합니다.',
      );
      await _show(
        key: DemoTargetKeys.ownerDetailSave,
        title: '내 정보 저장',
        message: '수정 내용을 확인한 뒤 저장합니다.',
      );
      await root();
      selectTab(2);
      await _wait();
      await _show(
        key: DemoTargetKeys.profileFarmInfo,
        title: '농장 정보 수정',
        message: '농장명, 주소, 소개, 정책, 대표 이미지를 관리합니다.',
      );
      await _push(const FarmDetailPage());
      await _show(
        key: DemoTargetKeys.farmDetailName,
        title: '농장명',
        message: '고객에게 노출되는 농장명을 관리합니다.',
      );
      await _show(
        key: DemoTargetKeys.farmDetailImage,
        title: '농장 대표 이미지',
        message: '고객에게 농장을 소개할 대표 사진을 확인하고 변경합니다.',
      );
      await _show(
        key: DemoTargetKeys.farmDetailSave,
        title: '농장 정보 저장',
        message: '농장 소개와 정책까지 확인한 뒤 저장합니다.',
      );
    } on _CoachTourCancelled {
      // 사용자가 상단 스킵을 눌러 튜토리얼을 종료했다.
    } finally {
      _running = false;
      _coach = null;
    }
  }

  void stop() {
    _coach?.finish();
    _coach = null;
    _running = false;
  }

  Future<void> _push(Widget page) async {
    _coach?.finish();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    await _wait(const Duration(milliseconds: 950));
  }

  Future<void> _show({
    required GlobalKey key,
    required String title,
    required String message,
    int contextAttempts = 24,
  }) async {
    final targetContext = await _waitForContext(
      key,
      maxAttempts: contextAttempts,
    );
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.34,
    );
    await _wait(const Duration(milliseconds: 120));

    final targetRect = _targetRect(key);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final contentAlign =
        targetRect != null && targetRect.center.dy > screenHeight * 0.58
        ? ContentAlign.top
        : ContentAlign.bottom;
    final completed = Completer<bool>();
    void completeStep(bool skipped) {
      if (!completed.isCompleted) completed.complete(skipped);
      _coach?.finish();
    }

    _coach = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: title,
          targetPosition: targetRect == null
              ? null
              : TargetPosition(targetRect.size, targetRect.topLeft),
          keyTarget: targetRect == null ? key : null,
          shape: ShapeLightFocus.RRect,
          radius: 14,
          paddingFocus: 6,
          color: _coachAccent,
          enableOverlayTab: true,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: contentAlign,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              builder: (_, _) => _CoachBubble(
                title: title,
                message: message,
                onSkip: () => completeStep(true),
                onNext: () => completeStep(false),
              ),
            ),
          ],
        ),
      ],
      hideSkip: true,
      useSafeArea: true,
      colorShadow: _coachShadow,
      opacityShadow: 0.24,
      paddingFocus: 6,
      pulseEnable: false,
      focusAnimationDuration: const Duration(milliseconds: 180),
      unFocusAnimationDuration: const Duration(milliseconds: 120),
      onFinish: () {
        if (!completed.isCompleted) completed.complete(false);
      },
      onSkip: () {
        if (!completed.isCompleted) completed.complete(true);
        return true;
      },
    )..show(context: context, rootOverlay: true);

    final skipped = await completed.future;
    _coach = null;
    await _wait(const Duration(milliseconds: 120));
    if (skipped) {
      throw const _CoachTourCancelled();
    }
  }

  Future<BuildContext?> _waitForContext(
    GlobalKey key, {
    int maxAttempts = 24,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final current = key.currentContext;
      if (current != null) return current;
      await _wait(const Duration(milliseconds: 120));
    }
    return null;
  }

  Rect? _targetRect(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Future<void> _wait([Duration duration = const Duration(milliseconds: 450)]) {
    return Future<void>.delayed(duration);
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({
    required this.title,
    required this.message,
    required this.onSkip,
    required this.onNext,
  });

  final String title;
  final String message;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _coachAccent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xff17251E)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                height: 1.34,
                fontWeight: FontWeight.w700,
                color: Color(0xff546157),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _CoachBubbleAction(label: '스킵', muted: true, onTap: onSkip),
                const Spacer(),
                _CoachBubbleAction(label: '다음', onTap: onNext),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachBubbleAction extends StatelessWidget {
  const _CoachBubbleAction({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final foreground = muted ? const Color(0xff7A817A) : _coachAccent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
