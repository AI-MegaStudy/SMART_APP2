// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_app/view/harvest_slot_page.dart';
import 'package:smart_app/view/orders_page.dart';
import 'package:smart_app/view/procurement_page.dart';
import 'package:smart_app/view/product_add_page.dart';
import 'package:smart_app/view/product_page.dart';
import 'package:smart_app/view/quality_page.dart';
import 'package:smart_app/view/return_page.dart';
import 'package:smart_app/view/shipment_page.dart';

const _demoHighlightColor = Color(0xffD81B60);

class DemoTargetKeys {
  static final homeGreeting = GlobalKey(debugLabel: 'demo.home.greeting');
  static final navMenu = GlobalKey(debugLabel: 'demo.nav.menu');
  static final menuProduct = GlobalKey(debugLabel: 'demo.menu.product');
  static final menuHarvest = GlobalKey(debugLabel: 'demo.menu.harvest');
  static final menuOrders = GlobalKey(debugLabel: 'demo.menu.orders');
  static final menuProcurement = GlobalKey(debugLabel: 'demo.menu.procurement');
  static final menuQuality = GlobalKey(debugLabel: 'demo.menu.quality');
  static final menuShipment = GlobalKey(debugLabel: 'demo.menu.shipment');
  static final menuReturn = GlobalKey(debugLabel: 'demo.menu.return');
  static final productAdd = GlobalKey(debugLabel: 'demo.product.add');
  static final productAddVariety = GlobalKey(
    debugLabel: 'demo.product.add.variety',
  );
  static final productAddPackage = GlobalKey(
    debugLabel: 'demo.product.add.package',
  );
  static final productAddImage = GlobalKey(
    debugLabel: 'demo.product.add.image',
  );
  static final productAddPrice = GlobalKey(
    debugLabel: 'demo.product.add.price',
  );
  static final productAddSave = GlobalKey(debugLabel: 'demo.product.add.save');
  static final harvestProduct = GlobalKey(debugLabel: 'demo.harvest.product');
  static final harvestYield = GlobalKey(debugLabel: 'demo.harvest.yield');
  static final harvestPredict = GlobalKey(debugLabel: 'demo.harvest.predict');
  static final harvestOpenSlot = GlobalKey(
    debugLabel: 'demo.harvest.open.slot',
  );
  static final ordersSection = GlobalKey(debugLabel: 'demo.orders.section');
  static final ordersPaid = GlobalKey(debugLabel: 'demo.orders.paid');
  static final reservationsSection = GlobalKey(
    debugLabel: 'demo.reservations.section',
  );
  static final reservationKeep = GlobalKey(debugLabel: 'demo.reservation.keep');
  static final reservationConverted = GlobalKey(
    debugLabel: 'demo.reservation.converted',
  );
  static final procurementFirst = GlobalKey(
    debugLabel: 'demo.procurement.first',
  );
  static final procurementApproveAll = GlobalKey(
    debugLabel: 'demo.procurement.detail.approve.all',
  );
  static final procurementItemQuantity = GlobalKey(
    debugLabel: 'demo.procurement.detail.item.quantity',
  );
  static final procurementSave = GlobalKey(
    debugLabel: 'demo.procurement.detail.save',
  );
  static final procurementApprove = GlobalKey(
    debugLabel: 'demo.procurement.approve',
  );
  static final qualityTarget = GlobalKey(debugLabel: 'demo.quality.target');
  static final qualityImage = GlobalKey(debugLabel: 'demo.quality.image');
  static final qualityAnalyze = GlobalKey(debugLabel: 'demo.quality.analyze');
  static final qualityResult = GlobalKey(debugLabel: 'demo.quality.result');
  static final qualityOwnerGrade = GlobalKey(
    debugLabel: 'demo.quality.owner.grade',
  );
  static final qualityOwnerDecision = GlobalKey(
    debugLabel: 'demo.quality.owner.decision',
  );
  static final qualitySave = GlobalKey(debugLabel: 'demo.quality.save');
  static final shipmentScan = GlobalKey(debugLabel: 'demo.shipment.scan');
  static final shipmentProduct = GlobalKey(debugLabel: 'demo.shipment.product');
  static final shipmentInvoice = GlobalKey(debugLabel: 'demo.shipment.invoice');
  static final shipmentRegister = GlobalKey(
    debugLabel: 'demo.shipment.register',
  );
  static final returnList = GlobalKey(debugLabel: 'demo.return.list');
  static final returnEvidence = GlobalKey(debugLabel: 'demo.return.evidence');
  static final returnAmount = GlobalKey(debugLabel: 'demo.return.amount');
  static final returnApprove = GlobalKey(debugLabel: 'demo.return.approve');

  const DemoTargetKeys._();
}

class OwnerDemoManager {
  OwnerDemoManager({required this.context, required this.selectTab});

  final BuildContext context;
  final ValueChanged<int> selectTab;
  OverlayEntry? _entry;
  Rect? _targetRect;
  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _ensureOverlay();
    final navigator = Navigator.of(context);

    Future<void> root() async {
      _hideHighlight();
      navigator.popUntil((route) => route.isFirst);
      await _wait();
    }

    try {
      await root();
      selectTab(1);
      await _focus(key: DemoTargetKeys.homeGreeting);
      await _focus(
        key: DemoTargetKeys.navMenu,
        beforeDelay: const Duration(milliseconds: 300),
      );

      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuProduct);
      await _push(const ProductPage());
      await _focus(key: DemoTargetKeys.productAdd);
      await _push(
        const ProductAddPage(
          farmId: 3,
          demoPreset: true,
          demoImageAsset:
              'assets/images/owner_demo/demo_register_yanggwang_product.png',
        ),
      );
      await _focus(key: DemoTargetKeys.productAddVariety);
      await _focus(key: DemoTargetKeys.productAddPackage);
      await _focus(key: DemoTargetKeys.productAddImage);
      await _focus(key: DemoTargetKeys.productAddPrice);
      await _focus(key: DemoTargetKeys.productAddSave);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuHarvest);
      await _push(const HarvestSlotPage(demoAutoPredict: true));
      await _focus(key: DemoTargetKeys.harvestProduct);
      await _focus(key: DemoTargetKeys.harvestYield);
      await _focus(key: DemoTargetKeys.harvestPredict);
      await _focus(key: DemoTargetKeys.harvestOpenSlot);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuOrders);
      await _push(const OrdersPage(demoMode: true));
      await _focus(key: DemoTargetKeys.ordersSection);
      await _focus(key: DemoTargetKeys.ordersPaid);
      await _focus(key: DemoTargetKeys.reservationsSection);
      await _focus(key: DemoTargetKeys.reservationKeep);
      await _focus(key: DemoTargetKeys.reservationConverted);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuProcurement);
      await _push(const ProcurementPage(demoOpenFirst: true));
      await _focus(key: DemoTargetKeys.procurementFirst);
      await _wait(const Duration(milliseconds: 800));
      await _focus(key: DemoTargetKeys.procurementApproveAll);
      await _focus(key: DemoTargetKeys.procurementItemQuantity);
      await _focus(key: DemoTargetKeys.procurementSave);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuQuality);
      await _push(
        const QualityPage(demoAutoImage: true, demoAutoAnalyze: true),
      );
      await _focus(key: DemoTargetKeys.qualityTarget);
      await _focus(key: DemoTargetKeys.qualityImage);
      await _focus(key: DemoTargetKeys.qualityAnalyze);
      await _focus(key: DemoTargetKeys.qualityResult);
      await _focus(key: DemoTargetKeys.qualityOwnerGrade);
      await _focus(key: DemoTargetKeys.qualityOwnerDecision);
      await _focus(key: DemoTargetKeys.qualitySave);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuShipment);
      await _push(const ShipmentPage(demoAutofill: true));
      await _focus(key: DemoTargetKeys.shipmentScan);
      await _focus(key: DemoTargetKeys.shipmentProduct);
      await _focus(key: DemoTargetKeys.shipmentInvoice);
      await _focus(key: DemoTargetKeys.shipmentRegister);

      await root();
      selectTab(0);
      await _wait();
      await _focus(key: DemoTargetKeys.menuReturn);
      await _push(const ReturnPage(demoOpenFirst: true));
      await _focus(key: DemoTargetKeys.returnList);
      await _focus(key: DemoTargetKeys.returnEvidence);
      await _focus(key: DemoTargetKeys.returnAmount);
      await _focus(key: DemoTargetKeys.returnApprove);
    } finally {
      await _wait(const Duration(milliseconds: 600));
      stop();
    }
  }

  void stop() {
    _running = false;
    _entry?.remove();
    _entry = null;
    _targetRect = null;
  }

  Future<void> _push(Widget page) async {
    _hideHighlight();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    await _wait(const Duration(milliseconds: 1100));
  }

  Future<void> _focus({
    required GlobalKey key,
    Duration beforeDelay = Duration.zero,
  }) async {
    if (beforeDelay > Duration.zero) await _wait(beforeDelay);
    _hideHighlight();
    final targetContext = await _waitForContext(key);
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.34,
      );
    }
    final rect = await _waitForStableRect(key);
    if (rect == null) return;
    _targetRect = rect;
    _entry?.markNeedsBuild();
    await _wait(const Duration(seconds: 4));
  }

  Future<BuildContext?> _waitForContext(GlobalKey key) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final current = key.currentContext;
      if (current != null) return current;
      await _wait(const Duration(milliseconds: 120));
    }
    return null;
  }

  Future<Rect?> _waitForStableRect(GlobalKey key) async {
    Rect? previous;
    var stableFrames = 0;
    for (var attempt = 0; attempt < 18; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final rect = _readTargetRect(key);
      if (rect == null) {
        stableFrames = 0;
        previous = null;
        await _wait(const Duration(milliseconds: 70));
        continue;
      }
      final stable = previous != null && _rectDistance(previous, rect) < 0.6;
      stableFrames = stable ? stableFrames + 1 : 0;
      previous = rect;
      if (stableFrames >= 2) return rect;
      await _wait(const Duration(milliseconds: 70));
    }
    return previous;
  }

  Rect? _readTargetRect(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  double _rectDistance(Rect a, Rect b) {
    return (a.left - b.left).abs() +
        (a.top - b.top).abs() +
        (a.width - b.width).abs() +
        (a.height - b.height).abs();
  }

  void _hideHighlight() {
    if (_targetRect == null) return;
    _targetRect = null;
    _entry?.markNeedsBuild();
  }

  Future<void> _wait([Duration duration = const Duration(milliseconds: 450)]) {
    return Future<void>.delayed(duration);
  }

  void _ensureOverlay() {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (context) => _DemoOverlay(rect: _targetRect),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }
}

class _DemoOverlay extends StatelessWidget {
  const _DemoOverlay({required this.rect});

  final Rect? rect;

  @override
  Widget build(BuildContext context) {
    final target = rect;
    if (target == null) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    if (target.bottom < media.padding.top ||
        target.top > media.size.height - media.padding.bottom ||
        target.right < 0 ||
        target.left > media.size.width) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: target.inflate(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _demoHighlightColor.withValues(alpha: 0.72),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
