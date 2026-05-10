import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_app/main.dart';

void main() {
  testWidgets('Owner app login and main shell smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OwnerApp());

    expect(find.text('오늘 수확 운영을 시작하세요'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'owner@harvestslot.kr',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'owner1234');
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 김하늘 점주님'), findsOneWidget);
    expect(find.text('메뉴'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('점주 운영 업무 전체'), findsOneWidget);
    expect(find.text('상품 관리'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('배송 · 반품'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('배송 · 반품'), findsOneWidget);
    expect(find.text('반품 · 환불 관리'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('점주와 농장 정보'), findsOneWidget);
    expect(find.text('내 정보 수정'), findsOneWidget);
    expect(find.text('농장 정보 수정'), findsOneWidget);

    await tester.tap(find.text('농장 정보 수정'));
    await tester.pumpAndSettle();
    expect(find.text('농장 정보 수정'), findsOneWidget);
  });
}
