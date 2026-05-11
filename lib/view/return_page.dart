import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_status_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ReturnPage extends StatefulWidget {
  final bool demoOpenFirst;

  const ReturnPage({super.key, this.demoOpenFirst = false});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final repository = OwnerWorkflowRepository();
  final searchController = TextEditingController();
  bool showSearch = false;
  bool loading = true;
  var requests = <OwnerReturnRequestRecord>[];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final loaded = await repository.fetchReturnRequests();
    if (!mounted) return;
    setState(() {
      requests = loaded.toList()
        ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      loading = false;
    });
    if (widget.demoOpenFirst && requests.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 5400), () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ReturnDetailPage(request: requests.first),
            ),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = requests.where((request) {
      return query.isEmpty ||
          '${request.title} ${request.subtitle}'.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: AppScaffold(
        title: '반품 · 환불 관리',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '반품 사유, 상품명을 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading)
            for (var index = 0; index < visible.length; index++)
              _ReturnRequestTile(
                key: index == 0 ? DemoTargetKeys.returnList : null,
                request: visible[index],
                onTap: () async {
                  final handled = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          _ReturnDetailPage(request: visible[index]),
                    ),
                  );
                  if (handled == true) {
                    await _loadRequests();
                  }
                },
              ),
          if (!loading && visible.isEmpty)
            const NoticeBox(color: AppColors.yellow, text: '처리할 반품 요청이 없습니다.'),
        ],
      ),
    );
  }
}

class _ReturnRequestTile extends StatelessWidget {
  final OwnerReturnRequestRecord request;
  final VoidCallback onTap;

  const _ReturnRequestTile({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DataTile(
      icon: Icons.keyboard_return,
      title: request.title,
      subtitle: request.subtitle,
      badge: request.status,
      badgeColor: AppColors.mint,
      iconBackground: AppColors.mint,
      iconColor: AppColors.green,
      onTap: onTap,
      showChevron: true,
    );
  }
}

class _ReturnDetailPage extends StatefulWidget {
  final OwnerReturnRequestRecord request;

  const _ReturnDetailPage({required this.request});

  @override
  State<_ReturnDetailPage> createState() => _ReturnDetailPageState();
}

class _ReturnDetailPageState extends State<_ReturnDetailPage> {
  final repository = OwnerWorkflowRepository();
  final formKey = GlobalKey<FormState>();
  late final TextEditingController detailController;
  late final TextEditingController approvalAmountController;

  @override
  void initState() {
    super.initState();
    detailController = TextEditingController(text: widget.request.detailReason);
    approvalAmountController = TextEditingController(
      text: widget.request.amount,
    );
  }

  @override
  void dispose() {
    detailController.dispose();
    approvalAmountController.dispose();
    super.dispose();
  }

  void _confirmApprove(BuildContext context) {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 항목을 입력해야 승인 가능합니다.');
      return;
    }
    showConfirmAction(
      context: context,
      title: '반품 요청 승인',
      message: '반품 · 환불 상태를 승인 처리할까요?',
      confirmLabel: '승인',
      onConfirm: () async {
        final saved = await repository.decideReturn(
          request: widget.request,
          decision: 'APPROVED',
          approvedAmount: int.tryParse(approvalAmountController.text) ?? 0,
          decisionReason: '점주 승인',
        );
        if (!context.mounted) return;
        if (saved || widget.request.isFallback) {
          showOwnerSnack(context, '반품 현황을 갱신했습니다.');
          Navigator.of(context).pop(true);
        } else {
          showOwnerSnack(context, '반품 요청을 저장하지 못했습니다.');
        }
      },
    );
  }

  Future<void> _confirmReject(BuildContext context) async {
    var reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('반품 요청 거절'),
              content: DropdownButtonFormField<String>(
                initialValue: reason,
                items: const [
                  DropdownMenuItem(value: '', child: Text('선택하세요.')),
                  DropdownMenuItem(value: '고객 단순 변심', child: Text('고객 단순 변심')),
                  DropdownMenuItem(
                    value: '첨부 이미지 확인 불가',
                    child: Text('첨부 이미지 확인 불가'),
                  ),
                  DropdownMenuItem(
                    value: '환불 정책 대상 아님',
                    child: Text('환불 정책 대상 아님'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => reason = value);
                  }
                },
                decoration: const InputDecoration(labelText: '거절 사유'),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: reason.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(true),
                        child: const Text('거절'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == true && context.mounted) {
      final saved = await repository.decideReturn(
        request: widget.request,
        decision: 'REJECTED',
        approvedAmount: 0,
        decisionReason: reason,
      );
      if (!context.mounted) return;
      if (saved || widget.request.isFallback) {
        showOwnerSnack(context, '반품 현황을 갱신했습니다.');
        Navigator.of(context).pop(true);
      } else {
        showOwnerSnack(context, '반품 요청을 저장하지 못했습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '반품 · 환불 상세',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            DataTile(
              icon: Icons.keyboard_return,
              title: widget.request.title,
              subtitle: widget.request.subtitle,
              badge: widget.request.status,
              badgeColor: const Color(0xffFFE1DD),
              iconBackground: const Color(0xffFFE1DD),
              iconColor: const Color(0xffB64033),
            ),
            LabeledField(
              label: '구매 상품 금액',
              value: '${widget.request.amount}원',
              enabled: false,
            ),
            LabeledField(
              label: '고객 요청 사유',
              value: widget.request.reason,
              enabled: false,
            ),
            LabeledBox(
              label: '상세 사유',
              value: widget.request.detailReason,
              controller: detailController,
              enabled: false,
            ),
            if (widget.request.photoCount > 0)
              _CustomerImagePreview(
                key: DemoTargetKeys.returnEvidence,
                imageUrl: widget.request.evidenceImageUrl,
              ),
            LabeledField(
              key: DemoTargetKeys.returnAmount,
              label: '승인 금액',
              value: '',
              controller: approvalAmountController,
              hintText: '승인 금액',
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('승인 금액', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '승인 금액에는 숫자만 입력하세요.';
              },
              suffixText: '원',
            ),
            DualActionBar(
              rightKey: DemoTargetKeys.returnApprove,
              left: '거절',
              right: '승인',
              onLeftPressed: () => _confirmReject(context),
              onRightPressed: () => _confirmApprove(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerImagePreview extends StatelessWidget {
  final String? imageUrl;

  const _CustomerImagePreview({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '고객 첨부 이미지',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: url.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ReturnImageViewer(imageUrl: url),
                    ),
                  );
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      color: AppColors.mint,
                    ),
                    child: url.isEmpty
                        ? const _ImageUnavailable()
                        : _ReturnEvidenceImage(imageUrl: url),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '확대',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnImageViewer extends StatelessWidget {
  final String imageUrl;

  const _ReturnImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('고객 첨부 이미지'),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: _ReturnEvidenceImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnEvidenceImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const _ReturnEvidenceImage({
    required this.imageUrl,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (_, _, _) => const _ImageUnavailable(),
      );
    }
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, _, _) => const _ImageUnavailable(),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.green, size: 32),
          SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다.',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
