  import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();
    final loyalty = context.watch<LoyaltyProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    final userBookings = bookings.getUserBookings(user.id);
    final transactions = loyalty.getUserTransactions(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user.photoPath != null ? FileImage(File(user.photoPath!)) : null,
                    child: user.photoPath == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (user.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _showEditProfile(context, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.black, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                Expanded(child: _StatBox(
                  label: 'Бронирования',
                  value: '${userBookings.length}',
                  icon: Icons.hotel_rounded,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(
                  label: 'Баллы лояльности',
                  value: '${user.loyaltyPoints}',
                  icon: Icons.stars_rounded,
                  highlight: true,
                )),
              ],
            ),
            const SizedBox(height: 16),
            // Loyalty history
            if (transactions.isNotEmpty) ...[
              _SectionHeader(title: 'История лояльности'),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: transactions.take(5).map((t) {
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: t.isPositive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        child: Icon(
                          t.isPositive ? Icons.add : Icons.remove,
                          size: 16,
                          color: t.isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                      title: Text(_translateLoyaltyDescription(t.description), style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14)),
                      subtitle: Text(DateUtil.timeAgo(t.createdAt), style: theme.textTheme.bodyMedium),
                      trailing: Text(
                        '${t.isPositive ? '+' : ''}${t.points}',
                        style: TextStyle(
                          color: t.isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _translateLoyaltyDescription(String description) {
    final desc = description.trim();
    if (desc.toLowerCase() == 'welcome bonus') {
      return 'Приветственный бонус';
    }
    return description;
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.currentUser?.name);
    final emailCtrl = TextEditingController(text: auth.currentUser?.email);
    final phoneCtrl = TextEditingController(text: auth.currentUser?.phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        nameCtrl: nameCtrl,
        emailCtrl: emailCtrl,
        phoneCtrl: phoneCtrl,
        auth: auth,
        initialPhotoPath: auth.currentUser?.photoPath,
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final AuthProvider auth;
  final String? initialPhotoPath;

  const _EditProfileSheet({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.auth,
    this.initialPhotoPath,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  String? _photoPath;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Редактировать профиль', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null
                        ? Text(
                            widget.nameCtrl.text.isNotEmpty
                                ? widget.nameCtrl.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _pickPhoto,
              child: const Text('Изменить фото'),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(label: 'Полное имя', controller: widget.nameCtrl, prefixIcon: Icons.person_outline),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email',
            controller: widget.emailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Телефон',
            controller: widget.phoneCtrl,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Сохранить изменения',
            loading: _loading,
            onTap: () async {
              setState(() {
                _loading = true;
                _error = null;
              });
              final success = await widget.auth.updateProfile(
                name: widget.nameCtrl.text,
                email: widget.emailCtrl.text,
                phone: widget.phoneCtrl.text,
                photoPath: _photoPath,
              );
              if (!success) {
                if (context.mounted) {
                  setState(() {
                    _loading = false;
                    _error = widget.auth.error ?? 'Не удалось сохранить изменения';
                  });
                }
                return;
              }
              if (context.mounted) {
                setState(() => _loading = false);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    ),
  );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatBox({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = highlight ? AppColors.accent : (isDark ? AppColors.textDark : AppColors.primary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
