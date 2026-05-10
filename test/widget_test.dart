import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_app/core/auth_session.dart';
import 'package:smart_app/main.dart';

void main() {
  setUp(() {
    AuthSession.accessToken = null;
    AuthSession.role = null;
  });

  testWidgets('Owner app shows login when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OwnerApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 수확 운영을 시작하세요'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('Owner app restores session and opens main shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'harvest_slot_owner_access_token': 'mock-owner-token',
      'harvest_slot_owner_role': 'OWNER',
    });

    await tester.pumpWidget(const OwnerApp());
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 김하늘 점주님'), findsOneWidget);
    expect(find.text('메뉴'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('점주 운영 업무 전체'), findsOneWidget);
    expect(find.text('상품 관리'), findsOneWidget);

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
