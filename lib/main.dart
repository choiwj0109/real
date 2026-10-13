import 'package:flutter/material.dart';

void main() => runApp(const TripWalletApp());

enum AuthProvider { email, kakao, naver, google }

class UserProfile {
  const UserProfile({
    required this.nickname,
    required this.email,
    required this.uid,
    required this.avatarUrl,
    required this.provider,
  });

  final String nickname;
  final String email;
  final String uid;
  final String avatarUrl;
  final AuthProvider provider;

  UserProfile copyWith({String? nickname}) => UserProfile(
        nickname: nickname ?? this.nickname,
        email: email,
        uid: uid,
        avatarUrl: avatarUrl,
        provider: provider,
      );
}

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

class TripWalletApp extends StatefulWidget {
  const TripWalletApp({super.key});

  @override
  State<TripWalletApp> createState() => _TripWalletAppState();
}

class _TripWalletAppState extends State<TripWalletApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3478EF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trip Wallet',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        fontFamilyFallback: const ['Noto Sans KR', 'sans-serif'],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          surface: const Color(0xFF172033),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamilyFallback: const ['Noto Sans KR', 'sans-serif'],
      ),
      home: ProfileScreen(
        darkMode: darkMode,
        onDarkModeChanged: (value) {
          setState(() => darkMode = value);
        },
      ),
    );
  }
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

  UserProfile user = const UserProfile(
    nickname: '별빛여우',
    email: 'starfox@example.com',
    uid: 'USR-20240318-A7F2',
    avatarUrl:
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=240&h=240&fit=crop&auto=format',
    provider: AuthProvider.email,
  );

  bool apiConsent = true;
  bool autoSmsParsing = true; // 🎯 문자 결제 내역 자동 파싱 설정 변수
  bool editingName = false;

  late final TextEditingController nameController;
  List<Inquiry> inquiries = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: user.nickname);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void saveName() {
    final value = nameController.text.trim();

    if (value.isNotEmpty) {
      user = user.copyWith(nickname: value);
    }

    setState(() => editingName = false);
    showMessage('닉네임이 저장되었습니다');
  }

  void showMessage(String message) {
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

  Future<void> openInquiries() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return InquirySheet(
          initialInquiries: inquiries,
          onChanged: (value) {
            setState(() => inquiries = value);
          },
        );
      },
    );
  }

  Future<void> openPasswordSheet() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  const Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '주기적인 비밀번호 변경으로 계정을 안전하게 보호하세요.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '현재 비밀번호',
                    controller: current,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: '새 비밀번호',
                    controller: next,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: '새 비밀번호 확인',
                    controller: confirm,
                    obscureText: true,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (current.text.isEmpty) {
                        setSheetState(() {
                          error = '현재 비밀번호를 입력해주세요.';
                        });
                      } else if (next.text.length < 8) {
                        setSheetState(() {
                          error = '새 비밀번호는 8자 이상이어야 합니다.';
                        });
                      } else if (next.text != confirm.text) {
                        setSheetState(() {
                          error = '새 비밀번호가 일치하지 않습니다.';
                        });
                      } else {
                        Navigator.pop(context);
                        showMessage('비밀번호가 변경되었습니다');
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '변경하기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = dark
        ? const Color(0xFF172033)
        : Colors.white;

    final muted = dark
        ? Colors.blueGrey.shade300
        : Colors.blueGrey.shade500;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
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
                        user: user,
                        editingName: editingName,
                        nameController: nameController,
                        onEditName: () {
                          setState(() => editingName = true);
                        },
                        onSaveName: saveName,
                        onCopyId: () {
                          showMessage('고유 ID를 복사했습니다');
                        },
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle('계정 및 보안'),
                      AppCard(
                        color: cardColor,
                        children: [
                          SettingTile(
                            icon: Icons.lock_outline_rounded,
                            title: '비밀번호 변경',
                            subtitle: '안전한 비밀번호로 계정을 보호하세요',
                            onTap: openPasswordSheet,
                          ),
                          SettingTile(
                            icon: Icons.verified_user_outlined,
                            title: 'API 데이터 활용 동의',
                            subtitle: apiConsent
                                ? '서비스 개선을 위한 활용에 동의 중'
                                : '데이터 활용에 동의하지 않음',
                            trailing: Switch(
                              value: apiConsent,
                              activeColor: primary,
                              onChanged: (value) {
                                setState(() => apiConsent = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle('연결된 카드 및 계좌'),
                      AppCard(
                        color: cardColor,
                        children: const [
                          PaymentTile(
                            icon: Icons.credit_card_rounded,
                            title: '연결된 카드',
                            items: [
                              'VISA  •••• 4242',
                              'mastercard  •••• 8833',
                            ],
                          ),
                          PaymentTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: '연결된 계좌',
                            items: [
                              '카카오뱅크  3333-••••-7821',
                              '신한은행  110-••••-2049',
                            ],
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
                          // 🎯 문자 자동 파싱 설정 항목 추가
                          SettingTile(
                            icon: Icons.sms_outlined,
                            title: '문자 결제 내역 자동 추출',
                            subtitle: autoSmsParsing
                                ? '수신된 문자의 결제 금액을 자동 파싱합니다'
                                : '문자 결제 내역 자동 파싱이 꺼져 있습니다',
                            trailing: Switch(
                              value: autoSmsParsing,
                              activeColor: primary,
                              onChanged: (value) {
                                setState(() => autoSmsParsing = value);
                                showMessage(
                                  value
                                      ? '문자 자동 추출 기능이 활성화되었습니다.'
                                      : '문자 자동 추출 기능이 비활성화되었습니다.',
                                );
                              },
                            ),
                          ),
                          SettingTile(
                            icon: Icons.support_agent_rounded,
                            title: '문의하기',
                            subtitle: inquiries.isEmpty
                                ? '평일 09:00 – 18:00 운영'
                                : '접수한 문의 ${inquiries.length}건',
                            onTap: openInquiries,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        color: cardColor,
                        children: [
                          SettingTile(
                            icon: Icons.logout_rounded,
                            title: '회원 탈퇴',
                            subtitle: '계정과 모든 데이터를 영구 삭제합니다',
                            danger: true,
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('회원 탈퇴'),
                                    content: const Text(
                                      '모든 데이터가 영구 삭제되며 복구할 수 없습니다.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('취소'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('탈퇴'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
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
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    required this.editingName,
    required this.nameController,
    required this.onEditName,
    required this.onSaveName,
    required this.onCopyId,
  });

  final UserProfile user;
  final bool editingName;
  final TextEditingController nameController;
  final VoidCallback onEditName;
  final VoidCallback onSaveName;
  final VoidCallback onCopyId;

  String? get providerLabel {
    return switch (user.provider) {
      AuthProvider.email => null,
      AuthProvider.kakao => '카카오 계정',
      AuthProvider.naver => '네이버 계정',
      AuthProvider.google => 'Google 계정',
    };
  }

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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3478EF),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 15,
                        color: Color(0xFF3478EF),
                      ),
                    ),
                  ),
                ],
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
                          child: Text(
                            user.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFFCFE0FF),
                        fontSize: 12,
                      ),
                    ),
                    if (providerLabel != null) ...[
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
                          providerLabel!,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
                        user.uid,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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

class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF3478EF).withOpacity(.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3478EF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(.55),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                    : '접수한 문의와 답변 여부를 확인하세요.',
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

// -----------------------------------------------------------------------------
// 공통 컴포넌트
// -----------------------------------------------------------------------------

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