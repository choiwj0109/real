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
                            children: [
                              SettingTile(
                                icon: Icons.dark_mode_outlined,
                                title: '다크 모드',
                                subtitle: '눈이 편안한 어두운 화면',
                                trailing: Switch(
                                  value: widget.darkMode,
                                  activeColor: primary,
                                  onChanged: widget.onDarkModeChanged,
                                ),
                              ),
                              SettingTile(
                                icon: Icons.support_agent_rounded,
                                title: '문의하기',
                                subtitle: _inquiries.isEmpty
                                    ? '평일 09:00 – 18:00 운영'
                                    : '접수한 문의 ${_inquiries.length}건',
                                onTap: _openInquiries,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AppCard(
                            color: cardColor,
                            children: [
                              SettingTile(
                                icon: Icons.person_off_outlined,
                                title: '회원 탈퇴',
                                subtitle: '계정과 모든 데이터를 영구 삭제합니다',
                                danger: true,
                                onTap: _deleteAccount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Trip Wallet v1.0.0\n이용약관 · 개인정보처리방침',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.uid,
    required this.loginMethodLabel,
    required this.editingName,
    required this.nameController,
    required this.onEditName,
    required this.onSaveName,
    required this.onCopyId,
  });

  final String displayName;
  final String email;
  final String uid;
  final String loginMethodLabel;
  final bool editingName;
  final TextEditingController nameController;
  final VoidCallback onEditName;
  final VoidCallback onSaveName;
  final VoidCallback onCopyId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3478EF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x383478EF),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : '유',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '안녕하세요,',
                      style: TextStyle(
                        color: Color(0xFFCFE0FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (editingName)
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        onSubmitted: (_) {
                          onSaveName();
                        },
                        onTapOutside: (_) {
                          onSaveName();
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: onEditName,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color(0xFFCFE0FF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFFCFE0FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$loginMethodLabel 계정',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2368D8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '고유 ID',
                        style: TextStyle(
                          color: Color(0xFFCFE0FF),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        uid,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onCopyId,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.color,
    required this.children,
  });

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D15305C),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                indent: 68,
                color: Theme.of(context).dividerColor.withOpacity(.2),
              ),
          ],
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : const Color(0xFF3478EF);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? Colors.red : null,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.blueGrey,
          ),
    );
  }
}

class InquirySheet extends StatefulWidget {
  const InquirySheet({
    super.key,
    required this.initialInquiries,
    required this.onChanged,
  });

  final List<Inquiry> initialInquiries;
  final ValueChanged<List<Inquiry>> onChanged;

  @override
  State<InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends State<InquirySheet> {
  late List<Inquiry> inquiries;
  final controller = TextEditingController();

  bool writing = false;

  @override
  void initState() {
    super.initState();
    inquiries = List.of(widget.initialInquiries);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      inquiries.insert(
        0,
        Inquiry(
          id: DateTime.now().millisecondsSinceEpoch,
          content: controller.text.trim(),
          createdAt: DateTime.now(),
        ),
      );

      controller.clear();
      writing = false;
    });

    widget.onChanged(List.of(inquiries));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      duration: const Duration(milliseconds: 150),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .92,
        minChildSize: .5,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const SheetHandle(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      writing ? '새 문의' : '나의 문의 내역',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!writing)
                    FilledButton(
                      onPressed: () {
                        setState(() => writing = true);
                      },
                      child: const Text('새 문의'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                writing
                    ? '궁금한 점이나 불편한 점을 남겨주세요.'
                    : '접수된 문의 내역입니다.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (writing) ...[
                AppTextField(
                  label: '문의 내용',
                  controller: controller,
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('문의 보내기'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => writing = false);
                  },
                  child: const Text('문의 내역으로'),
                ),
              ] else if (inquiries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 44),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(.2),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        '접수된 문의가 없습니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                for (final item in inquiries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: item.answered
                                    ? Colors.green.withOpacity(.1)
                                    : Colors.orange.withOpacity(.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.answered ? '답변 완료' : '답변 대기',
                                style: TextStyle(
                                  color: item.answered
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${item.createdAt.year}.${item.createdAt.month}.${item.createdAt.day}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}