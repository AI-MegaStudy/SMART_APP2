import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';
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
  bool isLoading = false;
  String? loadError;
  final repository = ProductRepository();
  List<OwnerFarmRecord> farms = const [];
  final selectedProducts = <ProductRecord>{};

  final products = <ProductRecord>[
    const ProductRecord('양광 사과', '5kg 박스', 39000, 42, '판매 중', AppColors.mint),
    const ProductRecord('부사 사과', '3kg 박스', 32000, 18, '준비 중', AppColors.yellow),
    const ProductRecord(
      '양광 사과',
      '7kg 박스',
      68000,
      12,
      '판매 중지',
      Color(0xffFFE1DD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    if (farms.isEmpty) {
      showOwnerSnack(context, '농장 정보가 없어 서버에 상품을 등록할 수 없습니다.');
      return;
    }
    final product = await Navigator.of(context).push<ProductRecord>(
      MaterialPageRoute(
        builder: (_) => ProductAddPage(farmId: farms.first.farmId),
      ),
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
      title: '상품 판매 중지',
      message: '선택한 ${selectedProducts.length}개 상품을 판매 중지 상태로 변경할까요?',
      confirmLabel: '변경',
      onConfirm: () async {
        await _stopSelectedProducts();
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final loadedFarms = await repository.fetchOwnerFarms();
      final loadedProducts = await repository.fetchOwnerProducts();
      if (!mounted) return;
      setState(() {
        farms = loadedFarms;
        products
          ..clear()
          ..addAll(loadedProducts);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => loadError = '서버 연결을 확인해주세요.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _stopSelectedProducts() async {
    final selected = selectedProducts.toList();
    try {
      for (final product in selected) {
        if (product.id == null) continue;
        final updated = await repository.updateProductStatus(
          productId: product.id!,
          productStatus: 'HIDDEN',
        );
        setState(() {
          final index = products.indexOf(product);
          if (index >= 0) {
            products[index] = updated;
          }
        });
      }
      setState(() {
        products.removeWhere(
          (product) => product.id == null && selected.contains(product),
        );
        selectedProducts.clear();
        deleteMode = false;
      });
      if (!mounted) return;
      showOwnerSnack(context, '상품 상태를 갱신했습니다.');
    } on ApiException catch (error) {
      if (!mounted) return;
      showOwnerSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showOwnerSnack(context, '상품 상태 변경에 실패했습니다.');
    }
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
          if (isLoading) const LinearProgressIndicator(minHeight: 3),
          if (loadError != null)
            NoticeBox(
              color: AppColors.yellow,
              text: '$loadError 더미 목록을 표시합니다.',
            ),
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
                    visible.isNotEmpty &&
                            selectedProducts.length == visible.length
                        ? '전체 선택 해제'
                        : '전체 선택',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _toggleDeleteMode,
                  child: const Text('판매 중지'),
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
                child: const Text('판매 중지'),
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
