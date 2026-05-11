class QualityTargetRecord {
  const QualityTargetRecord({
    required this.procurementId,
    required this.procurementItemId,
    required this.orderId,
    required this.customerName,
    required this.productName,
    required this.packageCount,
    required this.requestedKg,
    required this.isFallback,
  });

  final int procurementId;
  final int procurementItemId;
  final int orderId;
  final String customerName;
  final String productName;
  final int packageCount;
  final double requestedKg;
  final bool isFallback;

  factory QualityTargetRecord.fromProcurementJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    return QualityTargetRecord(
      procurementId: _asInt(json['procurement_id']),
      procurementItemId: _asInt(firstItem['procurement_item_id']),
      orderId: _asInt(json['order_id']),
      customerName: json['customer_name']?.toString() ?? '고객',
      productName: firstItem['product_name']?.toString() ?? '상품',
      packageCount: _asInt(firstItem['approved_package_count'], fallback: 1),
      requestedKg: _asDouble(firstItem['approved_kg']),
      isFallback: false,
    );
  }

  String get title =>
      '$customerName · $productName ${requestedKg.toStringAsFixed(0)}kg';

  String get subtitle => '$packageCount박스 · 발주 #$procurementId';
}

class QualityImageUploadRecord {
  const QualityImageUploadRecord({required this.imageUrl});

  final String imageUrl;

  factory QualityImageUploadRecord.fromJson(Map<String, dynamic> json) {
    return QualityImageUploadRecord(
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class QualityAnalysisRecord {
  const QualityAnalysisRecord({
    required this.modelGrade,
    required this.freshnessScore,
    required this.colorScore,
    required this.roundnessScore,
    required this.bruiseProbability,
    required this.modelDecision,
    required this.imageUrl,
    this.modelVersion,
    this.actionRequired,
    this.angleLabel,
    this.angleConfidence,
    this.gradeConfidence,
  });

  final String modelGrade;
  final double freshnessScore;
  final double colorScore;
  final double roundnessScore;
  final double bruiseProbability;
  final String modelDecision;
  final String imageUrl;
  final String? modelVersion;
  final String? actionRequired;
  final String? angleLabel;
  final double? angleConfidence;
  final double? gradeConfidence;

  factory QualityAnalysisRecord.fromJson(Map<String, dynamic> json) {
    final freshnessScore = _asDouble(json['freshness_score']);
    final colorScore = _asDouble(json['color_score']);
    final roundnessScore = _asDouble(json['roundness_score']);
    return QualityAnalysisRecord(
      modelGrade: json['model_grade']?.toString() ?? 'A',
      freshnessScore: freshnessScore,
      colorScore: colorScore == 0 ? freshnessScore : colorScore,
      roundnessScore: roundnessScore == 0 ? freshnessScore - 3 : roundnessScore,
      bruiseProbability: _asDouble(json['bruise_probability']),
      modelDecision: json['model_decision']?.toString() ?? 'PASS',
      imageUrl: json['image_url']?.toString() ?? '',
      modelVersion: json['model_version']?.toString(),
      actionRequired: json['action_required']?.toString(),
      angleLabel: json['angle_label']?.toString(),
      angleConfidence: _asDoubleOrNull(json['angle_confidence']),
      gradeConfidence: _asDoubleOrNull(json['grade_confidence']),
    );
  }

  factory QualityAnalysisRecord.localEstimate({
    required String imageName,
    required int byteLength,
  }) {
    final score = 84 + (byteLength % 12);
    final color = 82 + ((imageName.length + byteLength) % 14);
    final roundness = 80 + ((imageName.length * 3 + byteLength) % 16);
    final bruise = 0.05 + ((imageName.length + byteLength) % 18) / 100;
    final grade = score >= 92
        ? 'A'
        : score >= 86
        ? 'B'
        : 'C';
    return QualityAnalysisRecord(
      modelGrade: grade,
      freshnessScore: score.toDouble(),
      colorScore: color.toDouble(),
      roundnessScore: roundness.toDouble(),
      bruiseProbability: bruise,
      modelDecision: bruise < 0.2 && score >= 86 ? 'PASS' : 'REVIEW',
      imageUrl: '',
      modelVersion: 'local-estimate-v1',
      actionRequired: 'OWNER_REVIEW',
    );
  }

  String get freshnessLabel => '${freshnessScore.round()}점';
  String get colorLabel => '${colorScore.round()}점';
  String get roundnessLabel => '${roundnessScore.round()}점';
  String get bruiseProbabilityLabel => '${(bruiseProbability * 100).round()}%';
  String get decisionLabel => modelDecision == 'PASS' ? '통과' : '확인 필요';
  String get bruiseLabel {
    if (bruiseProbability < 0.25) return '멍 가능성 낮음';
    if (bruiseProbability < 0.55) return '멍 가능성 보통';
    return '멍 가능성 높음';
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
