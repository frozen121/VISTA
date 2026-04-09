import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../widgets/stat_card.dart';
import '../widgets/booking_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rooms = context.watch<RoomProvider>();
    final bookings = context.watch<BookingProvider>();
    final loyalty = context.watch<LoyaltyProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalUsers = loyalty.getAllUsers().length;
    final totalRevenue = bookings.totalRevenue;
    final statusCounts = bookings.getStatusCounts();
    final popularRoomIds = bookings.getPopularRoomIds();
    final recentBookings = bookings.allBookings.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Панель управления', style: TextStyle(fontSize: 24)),
            Text(
              DateUtil.formatDate(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: isDark ? AppColors.cardDark : AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                auth.currentUser?.name[0].toUpperCase() ?? 'A',
                style: TextStyle(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue card (large)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Общий доход',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '₽${totalRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _RevenueChip(
                        label: 'Подтверждено',
                        count: statusCounts['confirmed'] ?? 0,
                        color: AppColors.statusConfirmed,
                      ),
                      const SizedBox(width: 8),
                      _RevenueChip(
                        label: 'Завершено',
                        count: statusCounts['completed'] ?? 0,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.95,
              children: [
                StatCard(
                  title: 'Номера',
                  value: '${rooms.allRooms.length}',
                  icon: Icons.hotel_rounded,
                  color: AppColors.info,
                  centerValue: true,
                ),
                StatCard(
                  title: 'Пользователи',
                  value: '$totalUsers',
                  icon: Icons.people_rounded,
                  color: AppColors.success,
                  centerValue: true,
                ),
                StatCard(
                  title: 'Бронирования',
                  value: '${bookings.allBookings.length}',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.warning,
                  centerValue: true,
                ),
                StatCard(
                  title: 'Отменено',
                  value: '${statusCounts['cancelled'] ?? 0}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  centerValue: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Popular rooms
            if (popularRoomIds.isNotEmpty) ...[
              Text('Популярные номера', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...popularRoomIds.map((entry) {
                final room = rooms.getById(entry.key);
                if (room == null) return const SizedBox.shrink();
                return _PopularRoomTile(
                  name: room.name,
                  category: room.categoryLabel,
                  bookings: entry.value,
                  price: room.price,
                  isDark: isDark,
                );
              }),
              const SizedBox(height: 24),
            ],
            // Recent bookings
            if (recentBookings.isNotEmpty) ...[
              Text('Недавние бронирования', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...recentBookings.map((b) => BookingCard(booking: b)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevenueChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RevenueChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PopularRoomTile extends StatelessWidget {
  final String name;
  final String category;
  final int bookings;
  final double price;
  final bool isDark;

  const _PopularRoomTile({
    required this.name, required this.category, required this.bookings,
    required this.price, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hotel_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$bookings бронирований',
                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
              Text('₽${price.toStringAsFixed(0)}/ночь',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
