import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/harvest_slot_page.dart';
import 'package:smart_app/view/orders_page.dart';
import 'package:smart_app/view/procurement_page.dart';
import 'package:smart_app/view/procurement_status_page.dart';
import 'package:smart_app/view/product_page.dart';
import 'package:smart_app/view/quality_page.dart';
import 'package:smart_app/view/return_page.dart';
import 'package:smart_app/view/return_status_page.dart';
import 'package:smart_app/view/shipment_page.dart';
import 'package:smart_app/view/shipment_status_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final searchController = TextEditingController();
  bool showSearch = false;

  static const sections = [
    MenuSectionData(
      title: '기본 관리',
      items: [
        MenuEntry(
          icon: Icons.local_florist_outlined,
          title: '상품 관리',
          subtitle: '판매 상품 등록, 포장 단위, 가격 관리',
          page: ProductPage(),
        ),
        MenuEntry(
          icon: Icons.auto_graph_outlined,
          title: '수확 예측',
          subtitle: 'ML 예측 확인 후 주문 가능 수량 확인',
          page: HarvestSlotPage(),
        ),
        MenuEntry(
          icon: Icons.center_focus_strong_outlined,
          title: '신선도 검사',
          subtitle: '촬영, DL 결과 확인, 점주 최종 판정',
          page: QualityPage(),
        ),
      ],
    ),
    MenuSectionData(
      title: '주문 처리',
      items: [
        MenuEntry(
          icon: Icons.receipt_long_outlined,
          title: '주문 현황',
          subtitle: '고객 주문 완료와 결제 상태 확인',
          page: OrdersPage(),
        ),
        MenuEntry(
          icon: Icons.inventory_2_outlined,
          title: '발주 승인',
          subtitle: '주문 완료 건 선택 후 승인 또는 거절',
          page: ProcurementPage(),
        ),
        MenuEntry(
          icon: Icons.fact_check_outlined,
          title: '발주 현황',
          subtitle: '발주 승인 상태 확인',
          page: ProcurementStatusPage(),
        ),
      ],
    ),
    MenuSectionData(
      title: '배송 관리',
      items: [
        MenuEntry(
          icon: Icons.local_shipping_outlined,
          title: '배송 관리',
          subtitle: '택배사, 송장 번호, 발송 수량 등록',
          page: ShipmentPage(),
        ),
        MenuEntry(
          icon: Icons.route_outlined,
          title: '배송 현황',
          subtitle: '송장과 발송 상태 확인',
          page: ShipmentStatusPage(),
        ),
      ],
    ),
    MenuSectionData(
      title: '반품 관리',
      items: [
        MenuEntry(
          icon: Icons.keyboard_return_outlined,
          title: '반품 · 환불 관리',
          subtitle: '반품 요청 확인, 승인/거절, 환불 처리',
          page: ReturnPage(),
        ),
        MenuEntry(
          icon: Icons.assignment_return_outlined,
          title: '반품 · 환불 현황',
          subtitle: '반품과 환불 처리 상태 확인',
          page: ReturnStatusPage(),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visibleSections = [
      for (final section in sections)
        MenuSectionData(
          title: section.title,
          items: query.isEmpty
              ? section.items
              : section.items
                    .where(
                      (item) => '${item.title} ${item.subtitle}'
                          .toLowerCase()
                          .contains(query),
                    )
                    .toList(),
        ),
    ].where((section) => section.items.isNotEmpty).toList();

    return AppScaffold(
      title: '메뉴',
      subtitle: '점주 운영 업무 전체',
      trailing: ActionChipIcon(
        icon: showSearch ? Icons.close : Icons.search,
        onPressed: () {
          setState(() {
            showSearch = !showSearch;
            if (!showSearch) {
              searchController.clear();
            }
          });
        },
      ),
      children: [
        if (showSearch)
          _InlineSearchField(
            controller: searchController,
            hintText: '메뉴명을 검색하세요',
            onChanged: (_) => setState(() {}),
          ),
        for (final section in visibleSections)
          MenuSection(title: section.title, items: section.items),
        if (visibleSections.isEmpty)
          const NoticeBox(color: AppColors.yellow, text: '검색 결과가 없습니다.'),
      ],
    );
  }
}

class _InlineSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _InlineSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.clear),
              ),
      ),
    );
  }
}

class MenuSectionData {
  final String title;
  final List<MenuEntry> items;

  const MenuSectionData({required this.title, required this.items});
}

class MenuSection extends StatelessWidget {
  final String title;
  final List<MenuEntry> items;

  const MenuSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          _MenuTile(entry: items[i]),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class MenuEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;

  const MenuEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });
}

class _MenuTile extends StatelessWidget {
  final MenuEntry entry;

  const _MenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => entry.page));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
