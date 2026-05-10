import 'package:flutter/material.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/product_add_page.dart';
import 'package:smart_app/view/product_edit_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final searchController = TextEditingController();
  String filter = '전체';
  bool showSearch = false;
  bool deleteMode = false;
  final selectedProducts = <ProductRecord>{};

  final products = [
    const ProductRecord('양광 사과', '5kg 박스', 39000, 42, '판매 중', AppColors.mint),
    const ProductRecord('부사 사과', '3kg 박스', 32000, 18, '준비 중', AppColors.yellow),
    const ProductRecord('양광 사과', '7kg 박스', 68000, 12, '판매 중지', Color(0xffFFE1DD)),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final product = await Navigator.of(context).push<ProductRecord>(
      MaterialPageRoute(builder: (_) => const ProductAddPage()),
    );
    setState(() {
      deleteMode = false;
      selectedProducts.clear();
      if (product != null) {
        products.add(product);
      }
    });
  }

  Future<void> _openEdit(ProductRecord product) async {
    final updated = await Navigator.of(context).push<ProductRecord>(
      MaterialPageRoute(builder: (_) => ProductEditPage(product: product)),
    );
    if (updated != null) {
      setState(() {
        final index = products.indexOf(product);
        if (index >= 0) {
          products[index] = updated;
        }
      });
    }
  }

  void _toggleDeleteMode() {
    if (!deleteMode) {
      setState(() => deleteMode = true);
      return;
    }
    if (selectedProducts.isEmpty) {
      showOwnerSnack(context, '삭제할 상품을 선택하세요.');
      return;
    }
    showConfirmAction(
      context: context,
      title: '상품 삭제',
      message: '선택한 ${selectedProducts.length}개 상품을 삭제할까요?',
      confirmLabel: '삭제',
      onConfirm: () {
        setState(() {
          products.removeWhere(selectedProducts.contains);
          selectedProducts.clear();
          deleteMode = false;
        });
        showOwnerSnack(context, '상품 목록을 갱신했습니다.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = products.where((product) {
      final matchesFilter = filter == '전체' || product.status == filter;
      final matchesQuery =
          query.isEmpty ||
          '${product.name} ${product.packageUnit} ${product.priceLabel} ${product.stockKg} ${product.status}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      body: AppScaffold(
        title: '상품 관리',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionChipIcon(
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
            const SizedBox(width: 6),
            ActionChipIcon(icon: Icons.add, onPressed: _openAdd),
          ],
        ),
        children: [
          if (showSearch)
            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '상품명, 포장 단위, 상태를 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          FilterTabs(
            labels: const ['전체', '판매 중', '준비 중', '판매 중지'],
            selected: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
          for (final product in visible)
            deleteMode
                ? _ProductDeleteTile(
                    product: product,
                    selected: selectedProducts.contains(product),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedProducts.add(product);
                        } else {
                          selectedProducts.remove(product);
                        }
                      });
                    },
                  )
                : _ProductTile(
                    product: product,
                    onTap: () => _openEdit(product),
                  ),
          if (deleteMode)
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (selectedProducts.length == visible.length) {
                        selectedProducts.clear();
                      } else {
                        selectedProducts
                          ..clear()
                          ..addAll(visible);
                      }
                    });
                  },
                  child: Text(
                    visible.isNotEmpty && selectedProducts.length == visible.length
                        ? '전체 선택 해제'
                        : '전체 선택',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _toggleDeleteMode,
                  child: const Text('삭제'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    deleteMode = false;
                    selectedProducts.clear();
                  }),
                  child: const Text('완료'),
                ),
              ],
            )
          else
            Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _toggleDeleteMode,
              child: const Text('삭제'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductRecord product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stockStyle = TextStyle(
      color: product.stockKg <= 10 ? Colors.red : AppColors.muted,
      fontWeight: FontWeight.w800,
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                child: const Icon(Icons.local_florist, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.name} · ${product.packageUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(text: '${product.priceLabel} · '),
                          TextSpan(
                            text: '잔여 ${product.stockKg}박스',
                            style: stockStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(text: product.status, color: product.color),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDeleteTile extends StatelessWidget {
  final ProductRecord product;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _ProductDeleteTile({
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: onChanged,
      title: Text(
        '${product.name} · ${product.packageUnit}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${product.priceLabel} · 잔여 ${product.stockKg}박스'),
      controlAffinity: ListTileControlAffinity.leading,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
