import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserModel> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final repo = context.read<UserRepository>();
    setState(() => _users = repo.getAll().where((u) => !u.isAdmin).toList());
  }

  List<UserModel> get _filteredUsers => _users.where((u) =>
    u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    u.email.toLowerCase().contains(_searchQuery.toLowerCase())
  ).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Пользователи (${_filteredUsers.length})'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: _loadUsers,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(0),
                  minimumSize: const Size(48, 48),
                ),
                child: const Icon(Icons.refresh_rounded, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              height: 48,
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(child: Text('Пользователей не найдено', style: theme.textTheme.titleMedium))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (ctx, i) {
                      final user = _filteredUsers[i];
                      return _UserTile(
                        user: user,
                        onTap: () => _showUserDetails(context, user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user, onChanged: _loadUsers),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.loyaltyPoints}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateUtil.formatDate(user.createdAt),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onChanged;

  const _UserDetailSheet({required this.user, required this.onChanged});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final repo = context.read<UserRepository>();
    final loyalty = context.read<LoyaltyProvider>();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: theme.textTheme.titleLarge),
                        Text(user.email, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Row('Телефон', user.phone ?? '—'),
              _Row('Баллы лояльности', '${user.loyaltyPoints}'),
              _Row('Статус', user.isBlocked ? 'Заблокирован' : 'Активен'),
              _Row('Дата регистрации', DateUtil.formatDate(user.createdAt)),
              const SizedBox(height: 20),
              Text('Изменить данные', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person, size: 20),
                  label: const Text('Изменить имя'),
                  onPressed: _editName,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email, size: 20),
                  label: const Text('Изменить email'),
                  onPressed: _editEmail,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock, size: 20),
                  label: const Text('Изменить пароль'),
                  onPressed: _editPassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_outline, size: 20),
                  label: const Text('Управление баллами'),
                  onPressed: () => _showLoyaltyDialog(context, loyalty),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    user.isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline,
                    size: 20,
                  ),
                  label: Text(user.isBlocked ? 'Разблокировать' : 'Заблокировать'),
                  onPressed: () async {
                    setState(() {
                      user = user.copyWith(isBlocked: !user.isBlocked);
                    });
                    await repo.save(user);
                    widget.onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: user.isBlocked
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: user.isBlocked
                        ? AppColors.success
                        : AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_rounded, size: 20),
                  label: const Text('Удалить пользователя'),
                  onPressed: () => _confirmDelete(context, repo),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFieldSheet({
    required String title,
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required Future<void> Function() onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await onSave();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editName() {
    final controller = TextEditingController(text: user.name);
    _showEditFieldSheet(
      title: 'Изменить имя',
      label: 'Новое имя',
      controller: controller,
      onSave: () async {
        if (controller.text.trim().isNotEmpty) {
          setState(() {
            user = user.copyWith(name: controller.text.trim());
          });
          await context.read<UserRepository>().save(user);
          widget.onChanged();
        }
      },
    );
  }

  void _editEmail() {
    final controller = TextEditingController(text: user.email);
    _showEditFieldSheet(
      title: 'Изменить email',
      label: 'Новый email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      onSave: () async {
        if (controller.text.trim().isNotEmpty) {
          setState(() {
            user = user.copyWith(email: controller.text.trim());
          });
          await context.read<UserRepository>().save(user);
          widget.onChanged();
        }
      },
    );
  }

  void _editPassword() {
    final controller = TextEditingController();
    _showEditFieldSheet(
      title: 'Изменить пароль',
      label: 'Новый пароль',
      controller: controller,
      obscureText: true,
      onSave: () async {
        if (controller.text.trim().isNotEmpty) {
          setState(() {
            user = user.copyWith(passwordHash: controller.text.trim());
          });
          await context.read<UserRepository>().save(user);
          widget.onChanged();
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, UserRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmDeleteSheet(
        user: user,
        repo: repo,
        onChanged: widget.onChanged,
      ),
    );
  }

  void _showLoyaltyDialog(BuildContext context, LoyaltyProvider loyalty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoyaltyAdjustSheet(
        user: user,
        loyalty: loyalty,
        onChanged: widget.onChanged,
        onPointsChanged: (newPoints) {
          setState(() {
            user = user.copyWith(loyaltyPoints: newPoints);
          });
        },
      ),
    );
  }
}

class _ConfirmDeleteSheet extends StatelessWidget {
  final UserModel user;
  final UserRepository repo;
  final VoidCallback onChanged;

  const _ConfirmDeleteSheet({
    required this.user,
    required this.repo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Удалить пользователя?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Удалить ${user.name}? Все их данные будут удалены.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await repo.delete(user.id);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      onChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyAdjustSheet extends StatefulWidget {
  final UserModel user;
  final LoyaltyProvider loyalty;
  final VoidCallback onChanged;
  final Function(int) onPointsChanged;

  const _LoyaltyAdjustSheet({
    required this.user,
    required this.loyalty,
    required this.onChanged,
    required this.onPointsChanged,
  });

  @override
  State<_LoyaltyAdjustSheet> createState() => _LoyaltyAdjustSheetState();
}

class _LoyaltyAdjustSheetState extends State<_LoyaltyAdjustSheet> {
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pts = int.tryParse(_pointsController.text);
    final canApply = pts != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Настроить баллы лояльности', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Текущий баланс: ${widget.user.loyaltyPoints} баллов', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 18),
            TextField(
              controller: _pointsController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Баллы (используйте - для списания)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canApply
                        ? () async {
                            final desc = _reasonController.text.isEmpty ? 'Ручная настройка' : _reasonController.text;
                            final newPoints = widget.user.loyaltyPoints + pts!;
                            widget.onPointsChanged(newPoints);
                            await widget.loyalty.adminAdjust(
                              userId: widget.user.id,
                              points: pts!,
                              description: desc,
                            );
                            Navigator.pop(context);
                            widget.onChanged();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
