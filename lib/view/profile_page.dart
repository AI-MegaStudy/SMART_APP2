import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/farm_detail_page.dart';
import 'package:smart_app/view/login_page.dart';
import 'package:smart_app/view/owner_detail_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '마이',
      subtitle: '점주와 농장 정보',
      children: [
        const HeroPanel(
          eyebrow: '충주 햇살농원',
          title: '김하늘 점주',
          icon: Icons.badge_outlined,
          compact: true,
        ),
        ProfileListTile(
          icon: Icons.person_outline,
          title: '내 정보 수정',
          subtitle: '이름, 이메일, 비밀번호, 전화번호, 사업자번호',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OwnerDetailPage())),
        ),
        ProfileListTile(
          icon: Icons.warehouse_outlined,
          title: '농장 정보 수정',
          subtitle: '농장명, 주소, 농장 소개, 배송 정책, 반품 정책',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FarmDetailPage())),
        ),
        const SizedBox(height: 12),
        PrimaryAction(
          label: '로그아웃',
          onPressed: () {
            showConfirmAction(
              context: context,
              title: '로그아웃',
              message: '현재 계정에서 로그아웃할까요?',
              confirmLabel: '확인',
              onConfirm: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            );
          },
        ),
        PrimaryAction(
          label: '회원 탈퇴',
          backgroundColor: Colors.red,
          onPressed: () {
            showConfirmAction(
              context: context,
              title: '회원 탈퇴',
              message: '회원 탈퇴를 진행할까요?',
              confirmLabel: '확인',
              onConfirm: () => showInfoAction(
                context: context,
                title: '회원 탈퇴',
                message: '회원 탈퇴가 완료되었습니다.',
                onConfirm: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                child: Icon(icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
