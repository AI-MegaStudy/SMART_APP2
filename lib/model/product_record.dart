import 'package:flutter/material.dart';

class ProductRecord {
  final String name;
  final String packageUnit;
  final int price;
  final int stockKg;
  final String status;
  final Color color;

  const ProductRecord(
    this.name,
    this.packageUnit,
    this.price,
    this.stockKg,
    this.status,
    this.color,
  );

  String get priceLabel {
    final text = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$buffer원';
  }
}
