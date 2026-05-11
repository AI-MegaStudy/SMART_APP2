import 'package:flutter/material.dart';
import 'package:smart_app/core/auth_session.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_profile.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/owner_repository.dart';
import 'package:smart_app/repositories/product_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/farm_detail_page.dart';
import 'package:smart_app/view/login_page.dart';
import 'package:smart_app/view/owner_detail_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ownerRepository = OwnerRepository();
  final productRepository = ProductRepository();
  OwnerProfile? owner;
  OwnerFarmRecord? farm;

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    final results = await Future.wait<Object?>([
      _fetchOwnerProfile(),
      productRepository.fetchOwnerFarms().catchError(
        (_) => <OwnerFarmRecord>[],
      ),
    ]);
    if (!mounted) return;
    final farms = results[1] as List<OwnerFarmRecord>;
    setState(() {
      owner = results[0] as OwnerProfile?;
      farm = farms.isEmpty ? null : farms.first;
    });
  }

  Future<OwnerProfile?> _fetchOwnerProfile() async {
    try {
      return await ownerRepository.fetchProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = owner?.ownerName.trim();
    final farmName = farm?.farmName.trim();
    return AppScaffold(
      title: '마이',
      subtitle: '점주와 농장 정보',
      children: [
        HeroPanel(
          eyebrow: farmName == null || farmName.isEmpty ? '내 농장' : farmName,
          title: ownerName == null || ownerName.isEmpty
              ? '점주 정보'
              : '$ownerName 점주',
          icon: Icons.badge_outlined,
          compact: true,
        ),
        ProfileListTile(
          key: DemoTargetKeys.profileOwnerInfo,
          icon: Icons.person_outline,
          title: '내 정보 수정',
          subtitle: '이름, 이메일, 비밀번호, 전화번호, 사업자번호',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OwnerDetailPage())),
        ),
        ProfileListTile(
          key: DemoTargetKeys.profileFarmInfo,
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
              onConfirm: () async {
                await AuthSession.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            );
          },
        ),
        PrimaryAction(
          label: '계정 지원 요청',
          onPressed: () {
            showConfirmAction(
              context: context,
              title: '계정 지원 요청',
              message: '비밀번호 초기화, 계정 비활성화, 사업자 정보 변경 같은 계정 지원을 요청할까요?',
              confirmLabel: '요청',
              onConfirm: () => showInfoAction(
                context: context,
                title: '요청 접수',
                message: '계정 지원 요청이 접수되었습니다. 운영자가 사업자 정보 확인 후 연락합니다.',
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
