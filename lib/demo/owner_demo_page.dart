import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OwnerDemoPage extends StatefulWidget {
  const OwnerDemoPage({super.key});

  @override
  State<OwnerDemoPage> createState() => _OwnerDemoPageState();
}

class _OwnerDemoPageState extends State<OwnerDemoPage> {
  static const stepDelay = Duration(milliseconds: 1650);
  final steps = OwnerDemoStep.seed();
  Timer? timer;
  var index = 0;
  var isPaused = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(stepDelay, (_) {
      if (!mounted || isPaused) return;
      setState(() => index = (index + 1) % steps.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[index];
    return Scaffold(
      backgroundColor: const Color(0xffF7FAF4),
      body: AppScaffold(
        title: '점주앱 자동 데모',
        subtitle: '발표 영상용 빠른 시연 모드',
        leading: ActionChipIcon(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: ActionChipIcon(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          onPressed: () => setState(() => isPaused = !isPaused),
        ),
        children: [
          _DemoProgress(index: index, total: steps.length),
          _DemoStage(step: step),
          _DemoClickCard(step: step),
          _DemoScreen(step: step),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      index = index == 0 ? steps.length - 1 : index - 1;
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('이전'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => index = (index + 1) % steps.length);
                  },
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('다음'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoProgress extends StatelessWidget {
  const _DemoProgress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (index + 1) / total,
            color: AppColors.green,
            backgroundColor: AppColors.line,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${index + 1} / $total',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DemoStage extends StatelessWidget {
  const _DemoStage({required this.step});

  final OwnerDemoStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: step.tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: step.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(step.icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.screen,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            step.narration,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoClickCard extends StatelessWidget {
  const _DemoClickCard({required this.step});

  final OwnerDemoStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _PulseDot(color: step.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '자동 탭 위치',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.tapTarget,
                  style: TextStyle(
                    color: step.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.touch_app_outlined, color: step.accent),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Container(
          width: 38 + value * 12,
          height: 38 + value * 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.12 + value * 0.08),
          ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        );
      },
    );
  }
}

class _DemoScreen extends StatelessWidget {
  const _DemoScreen({required this.step});

  final OwnerDemoStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.icon, color: step.accent),
              const SizedBox(width: 8),
              Text(
                step.screen,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _StatusPill(label: step.status, color: step.accent),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Column(
                children: [
                  for (final item in step.visualItems) ...[
                    _VisualLine(
                      label: item.label,
                      value: item.value,
                      highlighted: item.highlighted,
                      color: step.accent,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: step.pulseAlignment,
                    child: _PulseDot(color: step.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _DemoActionBar(step: step),
        ],
      ),
    );
  }
}

class _DemoActionBar extends StatelessWidget {
  const _DemoActionBar({required this.step});

  final OwnerDemoStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: step.accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: step.accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              step.actionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _VisualLine extends StatelessWidget {
  const _VisualLine({
    required this.label,
    required this.value,
    required this.highlighted,
    required this.color,
  });

  final String label;
  final String value;
  final bool highlighted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.12)
            : const Color(0xffF7FAF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? color : AppColors.line,
          width: highlighted ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            highlighted ? Icons.radio_button_checked : Icons.circle_outlined,
            size: 18,
            color: highlighted ? color : AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlighted ? color : AppColors.text,
                fontSize: highlighted ? 16 : 15,
                fontWeight: highlighted ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerDemoStep {
  const OwnerDemoStep({
    required this.screen,
    required this.title,
    required this.tapTarget,
    required this.narration,
    required this.status,
    required this.actionLabel,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.border,
    required this.pulseAlignment,
    required this.visualItems,
  });

  final String screen;
  final String title;
  final String tapTarget;
  final String narration;
  final String status;
  final String actionLabel;
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color border;
  final Alignment pulseAlignment;
  final List<OwnerDemoVisualItem> visualItems;

  static List<OwnerDemoStep> seed() {
    const green = AppColors.green;
    const blue = Color(0xff2364AA);
    const amber = Color(0xff9B6A00);
    const red = Color(0xffB64033);
    return const [
      OwnerDemoStep(
        screen: '홈',
        title: '점주 계정 로그인 후 업무 현황 확인',
        tapTarget: '하단 메뉴 탭 → 메뉴',
        narration: '점주 홈에서 오늘 처리할 선별, 발주, 배송, 반품 현황을 확인합니다.',
        status: '시작',
        actionLabel: '하단 메뉴 탭',
        icon: Icons.home_outlined,
        accent: green,
        tint: Color(0xffEEF8F0),
        border: Color(0xffCFE8D8),
        pulseAlignment: Alignment.bottomLeft,
        visualItems: [
          OwnerDemoVisualItem('인사말', '청주 햇살농원', true),
          OwnerDemoVisualItem('업무 현황', '4개 카드', true),
          OwnerDemoVisualItem('하단 메뉴', '자동 탭', true),
        ],
      ),
      OwnerDemoStep(
        screen: '메뉴',
        title: '상품 관리 메뉴 선택',
        tapTarget: '기본 관리 → 상품 관리',
        narration: '메뉴 목록에서 실제 누를 항목은 진한 녹색 글자와 터치 포인트로 강조합니다.',
        status: '탭',
        actionLabel: '상품 관리 열기',
        icon: Icons.local_florist_outlined,
        accent: green,
        tint: Color(0xffEEF8F0),
        border: Color(0xffCFE8D8),
        pulseAlignment: Alignment.topRight,
        visualItems: [
          OwnerDemoVisualItem('상품 관리', '강조', true),
          OwnerDemoVisualItem('수확 예측', '대기', false),
          OwnerDemoVisualItem('신선도 검사', '대기', false),
        ],
      ),
      OwnerDemoStep(
        screen: '상품 관리',
        title: '부사/양광 상품과 박스 단위 확인',
        tapTarget: '우측 상단 + 버튼 → 등록',
        narration:
            '품종은 양광/부사만 선택하고, 박스 단위는 1kg, 3kg, 5kg, 7.5kg, 10kg으로 고정합니다.',
        status: '등록',
        actionLabel: '+ 버튼 탭 후 등록 완료',
        icon: Icons.add_circle_outline,
        accent: green,
        tint: Color(0xffEEF8F0),
        border: Color(0xffCFE8D8),
        pulseAlignment: Alignment.bottomRight,
        visualItems: [
          OwnerDemoVisualItem('양광 사과', '5kg 박스', true),
          OwnerDemoVisualItem('부사 사과', '3kg 박스', true),
          OwnerDemoVisualItem('등록 완료', '스낵바', true),
        ],
      ),
      OwnerDemoStep(
        screen: '수확 예측',
        title: '예측값 확인 후 점주가 확정 수량 선택',
        tapTarget: '수확 예측 실행 → 수확 슬롯 열기',
        narration: '예측값은 자동 오픈 기준이 아니라 참고값입니다. 점주가 날짜, 예약 가능 kg, 판매가를 확정합니다.',
        status: '예측',
        actionLabel: '수확 예측 실행',
        icon: Icons.auto_graph_outlined,
        accent: blue,
        tint: Color(0xffEEF6FF),
        border: Color(0xffC9DDF5),
        pulseAlignment: Alignment.bottomCenter,
        visualItems: [
          OwnerDemoVisualItem('예상 수확량', '610kg', true),
          OwnerDemoVisualItem('권장 예약량', '293-378kg', true),
          OwnerDemoVisualItem('슬롯 오픈', '420kg', true),
        ],
      ),
      OwnerDemoStep(
        screen: '발주 승인',
        title: '주문 완료 건을 선택해 승인 처리',
        tapTarget: '첫 번째 발주 체크박스 → 승인',
        narration: '발주 목록에서 품목을 확인하고 전체 승인, 부분 승인, 거절 중 하나로 처리합니다.',
        status: '승인',
        actionLabel: '승인 버튼 탭',
        icon: Icons.inventory_2_outlined,
        accent: amber,
        tint: Color(0xffFFF7DA),
        border: Color(0xffF1D88E),
        pulseAlignment: Alignment.centerRight,
        visualItems: [
          OwnerDemoVisualItem('홍길동 · 양광 10kg', '선택', true),
          OwnerDemoVisualItem('승인 버튼', '강조', true),
          OwnerDemoVisualItem('발주 현황', '갱신', true),
        ],
      ),
      OwnerDemoStep(
        screen: '신선도 검사',
        title: '이미지 선택 후 선별 보조 판정 저장',
        tapTarget: '이미지 박스 → 분석 → 저장',
        narration: '추천 등급과 신선도는 보조 자료이며, 최종 등급과 출고 여부는 점주가 확정합니다.',
        status: '분석',
        actionLabel: '분석 후 저장',
        icon: Icons.center_focus_strong_outlined,
        accent: blue,
        tint: Color(0xffEEF6FF),
        border: Color(0xffC9DDF5),
        pulseAlignment: Alignment.topLeft,
        visualItems: [
          OwnerDemoVisualItem('이미지 선택', '샘플', true),
          OwnerDemoVisualItem('추천 등급', 'A', true),
          OwnerDemoVisualItem('점주 판정', 'PASS', true),
        ],
      ),
      OwnerDemoStep(
        screen: '배송 관리',
        title: '택배사와 송장번호 등록',
        tapTarget: '발주 선택 → QR 버튼 → 등록',
        narration: '배송 가능한 발주를 선택하면 중량과 박스 수가 채워지고, 스캔 버튼으로 송장 입력을 보조합니다.',
        status: '배송',
        actionLabel: '송장 스캔 후 등록',
        icon: Icons.local_shipping_outlined,
        accent: green,
        tint: Color(0xffEEF8F0),
        border: Color(0xffCFE8D8),
        pulseAlignment: Alignment.center,
        visualItems: [
          OwnerDemoVisualItem('택배사', 'CJ대한통운', true),
          OwnerDemoVisualItem('송장번호', '자동 입력', true),
          OwnerDemoVisualItem('배송 등록', '완료', true),
        ],
      ),
      OwnerDemoStep(
        screen: '반품 · 환불 관리',
        title: '고객 첨부 이미지 확인 후 승인',
        tapTarget: '반품 요청 카드 → 승인',
        narration: '반품 사유와 고객 첨부 이미지를 확인하고 승인 금액을 확정해 처리합니다.',
        status: '완료',
        actionLabel: '반품 승인',
        icon: Icons.keyboard_return_outlined,
        accent: red,
        tint: Color(0xffFFF1EF),
        border: Color(0xffF1C9C4),
        pulseAlignment: Alignment.bottomRight,
        visualItems: [
          OwnerDemoVisualItem('고객 첨부 이미지', '확인', true),
          OwnerDemoVisualItem('승인 금액', '입력', true),
          OwnerDemoVisualItem('반품 현황', '갱신', true),
        ],
      ),
    ];
  }
}

class OwnerDemoVisualItem {
  const OwnerDemoVisualItem(this.label, this.value, this.highlighted);

  final String label;
  final String value;
  final bool highlighted;
}
