import 'package:flutter/material.dart';
import 'api/api.dart'; // ★ 화면에서 import 하는 유일한 파일
import 'password_reset_screen.dart'; // ★ 비밀번호 재설정 화면 import

enum AuthProvider { email, kakao, naver, google }

class Inquiry {
  Inquiry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.answered = false,
  });

  final int id;
  final String content;
  final DateTime createdAt;
  final bool answered;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const primary = Color(0xFF3478EF);

  bool _busy = false;
  bool _editingName = false;

  late final TextEditingController _nameController;
  List<Inquiry> _inquiries = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AuthApi.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 1. 이름 저장 처리
  Future<void> _saveName() async {
    final value = _nameController.text.trim();
    final errorMsg = AuthApi.validateName(value);

    if (errorMsg != null) {
      _showMessage(errorMsg);
      return;
    }

    if (value == AuthApi.displayName) {
      setState(() => _editingName = false);
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthApi.updateDisplayName(value);
      if (!mounted) return;
      _showMessage('닉네임이 저장되었습니다');
      setState(() => _editingName = false);
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthApi.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // 2. 환율 강제 갱신
  Future<void> _refreshExchangeRate() async {
    setState(() => _busy = true);
    try {
      await RateApi.load(force: true);
      if (!mounted) return;
      _showMessage('환율 정보가 갱신되었습니다');
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthApi.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 3. 비밀번호 재설정 화면으로 이동 (password_reset_screen.dart 활용)
  void _openPasswordResetScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PasswordResetScreen(),
      ),
    );
  }

  // 4. 문의하기 바텀시트
  Future<void> _openInquiries() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return InquirySheet(
          initialInquiries: _inquiries,
          onChanged: (value) {
            setState(() => _inquiries = value);
          },
        );
      },
    );
  }

  // 5. 로그아웃 (AuthGate가 자동 처리)
  Future<void> _logout() async {
    try {
      await AuthApi.signOut();
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthApi.errorMessage(e));
    }
  }

  // 6. 회원 탈퇴
  Future<void> _deleteAccount() async {
    final pwController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('모든 데이터가 영구 삭제되며 복구할 수 없습니다.'),
              if (AuthApi.isPasswordUser) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: '비밀번호 확인',
                  controller: pwController,
                  obscureText: true,
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final password = AuthApi.isPasswordUser ? pwController.text : null;
      await AccountApi.deleteAccount(password: password);
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthApi.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = dark ? const Color(0xFF172033) : Colors.white;
    final muted = dark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade500;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder(
          stream: AuthApi.userChanges,
          builder: (context, snapshot) {
            if (_busy) {
              return const Center(child: CircularProgressIndicator());
            }

            final lastFetched = RateApi.lastFetched;
            final dateStr = lastFetched != null
                ? '${lastFetched.month}.${lastFetched.day} ${lastFetched.hour}:${lastFetched.minute.toString().padLeft(2, '0')}'
                : '정보 없음';

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      centerTitle: true,
                      title: const Text(
                        '내 정보',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      surfaceTintColor: Colors.transparent,
                      leading: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList.list(
                        children: [
                          ProfileCard(
                            displayName: AuthApi.displayName,
                            email: AuthApi.email ?? '',
                            uid: AuthApi.uid,
                            loginMethodLabel: AuthApi.loginMethodLabel,
                            editingName: _editingName,
                            nameController: _nameController,
                            onEditName: () {
                              _nameController.text = AuthApi.displayName;
                              setState(() => _editingName = true);
                            },
                            onSaveName: _saveName,
                            onCopyId: () {
                              _showMessage('고유 ID를 복사했습니다');
                            },
                          ),
                          const SizedBox(height: 24),
                          const SectionTitle('환율 정보'),
                          AppCard(
                            color: cardColor,
                            children: [
                              SettingTile(
                                icon: Icons.currency_exchange_rounded,
                                title: '환율 상태',
                                subtitle: RateApi.ready
                                    ? '최근 갱신: $dateStr'
                                    : '환율 정보를 불러올 수 없음',
                                trailing: IconButton(
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: primary),
                                  onPressed: _refreshExchangeRate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const SectionTitle('계정 및 보안'),
                          AppCard(
                            color: cardColor,
                            children: [
                              if (AuthApi.isPasswordUser)
                                SettingTile(
                                  icon: Icons.lock_outline_rounded,
                                  title: '비밀번호 재설정',
                                  subtitle: '이메일 인증을 통해 비밀번호를 변경합니다',
                                  onTap: _openPasswordResetScreen, // ★ 수정된 부분
                                ),
                              SettingTile(
                                icon: Icons.logout_rounded,
                                title: '로그아웃',
                                subtitle: '계정에서 로그아웃합니다',
                                onTap: _logout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const SectionTitle('앱 설정'),
                          AppCard(
                            color: cardColor,