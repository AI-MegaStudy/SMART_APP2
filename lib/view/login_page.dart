import 'package:flutter/material.dart';
import 'package:smart_app/view/email_find_page.dart';
import 'package:smart_app/view/home.dart';
import 'package:smart_app/view/password_find_page.dart';
import 'package:smart_app/view/signup_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(text: 'owner@harvestslot.kr');
  final passwordController = TextEditingController(text: 'owner1234');
  String? loginError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() {
    setState(() => loginError = null);
    if (!(formKey.currentState?.validate() ?? false)) return;
    final ok =
        emailController.text.trim() == 'owner@harvestslot.kr' &&
        passwordController.text.trim() == 'owner1234';
    if (!ok) {
      setState(() => loginError = '이메일 또는 비밀번호가 일치하지 않습니다.');
      formKey.currentState?.validate();
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const whiteText = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SeedLogo(),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height < 720
                              ? 72
                              : 170,
                        ),
                        const Text(
                          '오늘 수확 운영을 시작하세요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '충주 햇살농원의 주문, 발주, 배송 현황을 이어서 관리합니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 20,
                          validator: (value) =>
                              loginError ?? emailValidator(value),
                          decoration: const InputDecoration(
                            hintText: '이메일',
                            counterText: '',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          maxLength: 20,
                          validator: passwordValidator,
                          decoration: const InputDecoration(
                            hintText: '비밀번호',
                            counterText: '',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _login,
                          child: const Text('로그인'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              ),
                              child: const Text('회원가입', style: whiteText),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailFindPage(),
                                ),
                              ),
                              child: const Text('이메일 찾기', style: whiteText),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PasswordFindPage(),
                                ),
                              ),
                              child: const Text('비밀번호 찾기', style: whiteText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedLogo extends StatelessWidget {
  const _SeedLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xff215C42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.eco_outlined, color: Colors.white, size: 30),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff8EA198), Color(0xff245E45)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -70,
            bottom: -40,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(
                Icons.spa,
                size: 360,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
