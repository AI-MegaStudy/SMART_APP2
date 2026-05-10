import 'package:flutter/material.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class HarvestSlotPage extends StatefulWidget {
  const HarvestSlotPage({super.key});

  @override
  State<HarvestSlotPage> createState() => _HarvestSlotPageState();
}

class _HarvestSlotPageState extends State<HarvestSlotPage> {
  String selectedProduct = '양광 사과';

  _HarvestPrediction get prediction => _predictions.firstWhere(
    (item) => item.product == selectedProduct,
    orElse: () => _predictions.first,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScaffold(
        title: '수확 예측',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        children: [
          LabeledDropdown(
            label: '상품',
            value: selectedProduct,
            items: [for (final item in _predictions) item.product],
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedProduct = value);
              }
            },
          ),
          const YieldChart(),
          GridCards(
            children: [
              MetricCard(
                icon: Icons.calendar_month_outlined,
                value: prediction.period,
                label: '예측 수확 날짜',
              ),
              MetricCard(
                icon: Icons.scale_outlined,
                value: prediction.expectedYield,
                label: '예상 수확량',
              ),
              MetricCard(
                icon: Icons.shopping_bag_outlined,
                value: prediction.reservation,
                label: '권장 예약량',
              ),
              MetricCard(
                icon: Icons.paid_outlined,
                value: prediction.price,
                label: '권장 판매가(kg 기준)',
              ),
            ],
          ),
          DataTile(
            icon: Icons.verified_outlined,
            title: '신뢰도 ${prediction.confidence}',
            subtitle: '최근 수확량, 기상, 주문 데이터를 반영한 예측입니다.',
            badge: '',
            badgeColor: const Color(0xffDFF4E8),
          ),
        ],
      ),
    );
  }
}

class _HarvestPrediction {
  final String product;
  final String period;
  final String expectedYield;
  final String reservation;
  final String price;
  final String confidence;

  const _HarvestPrediction(
    this.product,
    this.period,
    this.expectedYield,
    this.reservation,
    this.price,
    this.confidence,
  );
}

const _predictions = [
  _HarvestPrediction(
    '양광 사과',
    '10.12-10.18',
    '420kg',
    '260-320kg',
    '7,800원/kg',
    '82%',
  ),
  _HarvestPrediction(
    '부사 사과',
    '10.18-10.24',
    '300kg',
    '180-240kg',
    '10,600원/kg',
    '79%',
  ),
];
