import 'package:flutter/material.dart';
import '../../data/models/booking_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final bool showUser;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(booking.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.roomName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14,
                    color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 6),
                Text(
                  DateUtil.formatDateRange(booking.checkIn, booking.checkOut),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 12),
                Icon(Icons.nights_stay_outlined, size: 14,
                    color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 4),
                Text(
                  '${booking.nights} ночей',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₽${booking.totalPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (booking.pointsEarned > 0)
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        '+${booking.pointsEarned} баллов',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (booking.paymentMethod != null || booking.notes != null) ...[
              const SizedBox(height: 8),
              if (booking.paymentMethod != null)
                Row(
                  children: [
                    Icon(Icons.payment_outlined, size: 14,
                        color: theme.textTheme.bodyMedium?.color),
                    const SizedBox(width: 6),
                    Text(
                      booking.paymentMethod == 'card' ? 'Карта' : 'Наличные',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              if (booking.notes != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_outlined, size: 14,
                        color: theme.textTheme.bodyMedium?.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return AppColors.statusConfirmed;
      case 'pending': return AppColors.statusPending;
      case 'cancelled': return AppColors.statusCancelled;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'confirmed':
        return 'Подтверждено';
      case 'completed':
        return 'Завершено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'confirmed': return AppColors.statusConfirmed;
      case 'pending': return AppColors.statusPending;
      case 'cancelled': return AppColors.statusCancelled;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
  }
}
