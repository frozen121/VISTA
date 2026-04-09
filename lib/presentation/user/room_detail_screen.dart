import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../data/models/room_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../widgets/custom_button.dart';

class RoomDetailScreen extends StatelessWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final room = context.read<RoomProvider>().getById(roomId);
    final auth = context.watch<AuthProvider>();
    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Номер не найден')),
      );
    }
    return _RoomDetailView(room: room, isAdmin: auth.isAdmin);
  }
}

class _RoomDetailView extends StatefulWidget {
  final RoomModel room;
  final bool isAdmin;
  const _RoomDetailView({required this.room, required this.isAdmin});

  @override
  State<_RoomDetailView> createState() => _RoomDetailViewState();
}

class _RoomDetailViewState extends State<_RoomDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final book = uri.queryParameters['book'] == 'true';
      if (book && !widget.isAdmin) {
        _showBookingSheet(context, widget.room);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(widget.room),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.room.name, style: theme.textTheme.headlineLarge),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₽${widget.room.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                          Text('за ночь', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.hotel_rounded, label: widget.room.categoryLabel),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.people_outline, label: '${widget.room.capacity} гости'),
                      if (!widget.room.isAvailable) ...[
                        const SizedBox(width: 8),
                        const _InfoChip(
                          icon: Icons.block_rounded,
                          label: 'Недоступно',
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Описание', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(widget.room.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
                  if (widget.room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Удобства', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.room.amenities.map((a) => _AmenityTile(label: a)).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (widget.room.isAvailable)
                    PrimaryButton(
                      label: 'Забронировать',
                      icon: Icons.calendar_month_rounded,
                      onTap: () => _showBookingSheet(context, widget.room),
                    )
                  else
                    OutlineButton(
                      label: 'Временно недоступно',
                      color: AppColors.error,
                    ),
                  // Admin controls
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(widget.room.isAvailable ? Icons.lock_outline : Icons.lock_open_rounded, size: 20),
                        label: Text(widget.room.isAvailable ? 'Заблокировать' : 'Разблокировать'),
                        onPressed: () async {
                          final updated = widget.room.copyWith(isAvailable: !widget.room.isAvailable);
                          await context.read<RoomProvider>().updateRoom(updated);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        label: const Text('Удалить'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Удалить номер?'),
                              content: Text('Удалить "${widget.room.name}"? Это действие нельзя отменить.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                                TextButton(
                                  onPressed: () async {
                                    await context.read<RoomProvider>().deleteRoom(widget.room.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      context.pop();
                                    }
                                  },
                                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppColors.error.withValues(alpha: 0.1),
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(RoomModel room) {
    if (room.imagePaths.isNotEmpty) {
      return Image.file(
        File(room.imagePaths.first),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientBg(room),
      );
    }
    return _gradientBg(room);
  }

  Widget _gradientBg(RoomModel room) {
    final colors = _categoryGradient(room.category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(_categoryIcon(room.category), size: 80, color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }

  List<Color> _categoryGradient(String cat) {
    switch (cat) {
      case 'presidential': return [const Color(0xFF2C1810), const Color(0xFF8B4513)];
      case 'suite': return [const Color(0xFF1A1A3E), const Color(0xFF6366F1)];
      case 'deluxe': return [const Color(0xFF0F2027), const Color(0xFF203A43)];
      default: return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'presidential': return Icons.stars_rounded;
      case 'suite': return Icons.hotel_rounded;
      case 'deluxe': return Icons.king_bed_rounded;
      default: return Icons.bed_rounded;
    }
  }

  void _showBookingSheet(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: _BookingSheet(room: room),
          ),
        );
      },
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final RoomModel room;

  const _BookingSheet({required this.room});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  String? _paymentMethod;
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _cardExpiryCtrl = TextEditingController();
  final TextEditingController _cardCvvCtrl = TextEditingController();
  final TextEditingController _cardNameCtrl = TextEditingController();
  final TextEditingController _commentsCtrl = TextEditingController();
  // Фокус для поля комментариев: если клавиатуру скрывают, сбрасываем фокус.
  final FocusNode _commentsFocusNode = FocusNode();
  bool _loading = false;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _checkIn = null;
    _checkOut = null;
    _rangeStart = null;
    _rangeEnd = null;
    _focusedDay = DateTime.now();
  }

  Future<void> _pickDateRange() async {
    DateTime? tempRangeStart = _checkIn;
    DateTime? tempRangeEnd = _checkOut;
    DateTime tempFocusedDay = _focusedDay;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.84,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 40, height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Выберите даты', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tempRangeStart == null
                          ? 'Сначала выберите дату заезда.'
                          : tempRangeEnd == null
                              ? 'Затем выберите дату выезда.'
                              : 'Проверьте выбранный период и примените.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (tempRangeStart != null && tempRangeEnd != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${DateUtil.formatDate(tempRangeStart!)} - ${DateUtil.formatDate(tempRangeEnd!)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: TableCalendar(
                        locale: 'ru_RU',
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: tempFocusedDay,
                        rangeStartDay: tempRangeStart,
                        rangeEndDay: tempRangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        daysOfWeekHeight: 30,
                        onRangeSelected: (start, end, focusedDay) {
                          setModalState(() {
                            tempRangeStart = start;
                            tempRangeEnd = end;
                            tempFocusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setModalState(() {
                            tempFocusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          rangeStartDecoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          rangeHighlightColor: AppColors.accent.withOpacity(0.3),
                          todayDecoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Сбросить', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (tempRangeStart != null && tempRangeEnd != null) {
                                setState(() {
                                  _checkIn = tempRangeStart;
                                  _checkOut = tempRangeEnd;
                                  _error = null;
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Применить', style: TextStyle(fontWeight: FontWeight.w600)),
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
      },
    );
  }

  Future<void> _book() async {
    if (_checkIn == null || _checkOut == null) {
      setState(() => _error = 'Пожалуйста, выберите даты');
      return;
    }
    if (_checkOut!.difference(_checkIn!).inDays < 1) {
      setState(() => _error = 'Минимум 1 ночь');
      return;
    }
    if (_paymentMethod == null) {
      setState(() => _error = 'Пожалуйста, выберите способ оплаты');
      return;
    }
    if (_paymentMethod == 'card') {
      final rawNumber = _cardNumberCtrl.text.replaceAll(' ', '');
      final expiry = _cardExpiryCtrl.text;
      final cvv = _cardCvvCtrl.text;
      final holder = _cardNameCtrl.text.trim();

      if (!RegExp(r'^\d{16}$').hasMatch(rawNumber)) {
        setState(() => _error = 'Введите корректный 16-значный номер карты');
        return;
      }
      if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(expiry)) {
        setState(() => _error = 'Введите срок действия в формате MM/YY');
        return;
      }
      if (!RegExp(r'^\d{3}$').hasMatch(cvv)) {
        setState(() => _error = 'Введите корректный 3-значный CVV');
        return;
      }
      if (holder.isEmpty) {
        setState(() => _error = 'Введите имя держателя карты');
        return;
      }
    }

    setState(() { _loading = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final bookings = context.read<BookingProvider>();
    final roomProvider = context.read<RoomProvider>();

    if (!bookings.isRoomAvailable(widget.room.id, _checkIn!, _checkOut!)) {
      setState(() {
        _error = 'Номер недоступен на выбранные даты';
        _loading = false;
      });
      return;
    }

    try {
      await bookings.createBooking(
        userId: auth.currentUser!.id,
        room: widget.room,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        paymentMethod: _paymentMethod,
        notes: _commentsCtrl.text.isNotEmpty ? _commentsCtrl.text : null,
      );
      roomProvider.load();
      await auth.refreshCurrentUser();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final theme = Theme.of(dialogContext);
            final isDarkDialog = theme.brightness == Brightness.dark;
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  width: min(MediaQuery.of(dialogContext).size.width * 0.92, 960),
                  decoration: BoxDecoration(
                    color: isDarkDialog ? AppColors.cardDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDarkDialog ? AppColors.dividerDark.withOpacity(0.45) : AppColors.divider.withOpacity(0.75),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkDialog ? Colors.black.withOpacity(0.28) : Colors.black.withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 520,
                      maxWidth: 960,
                      maxHeight: 700,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Бронирование',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ваше бронирование успешно создано. Вы можете просмотреть его в разделе "Мои бронирования".',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 58),
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                context.go('/user');
                              },
                              child: const Text('Главная', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 58),
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                context.go('/user/bookings');
                              },
                              child: const Text('Мои бронирования', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          );
        },
      );
    }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _cardNameCtrl.dispose();
    _commentsCtrl.dispose();
    _commentsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nights = _checkIn != null && _checkOut != null
        ? DateUtil.nightsBetween(_checkIn!, _checkOut!)
        : 0;
    final total = nights * widget.room.price;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Забронировать ${widget.room.name}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '₽${widget.room.price.toStringAsFixed(0)} за ночь',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Date picker
          Text('Выберите даты', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_checkIn != null && _checkOut != null)
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : (isDark ? AppColors.dividerDark : AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (_checkIn != null && _checkOut != null)
                          ? '${DateUtil.formatDate(_checkIn!)} - ${DateUtil.formatDate(_checkOut!)}'
                          : 'Выберите даты заезда и выезда',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          if (nights > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Итого', style: theme.textTheme.bodyMedium),
                      Text(
                        '₽${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Вы получаете', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '+${(total / 10).round()} баллов',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Способ оплаты', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPaymentOption(theme, 'card', 'Карта')),
                const SizedBox(width: 12),
                Expanded(child: _buildPaymentOption(theme, 'cash', 'Наличные')),
              ],
            ),
            if (_paymentMethod == 'card') ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Данные карты', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(19),
                        CardNumberInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Номер карты',
                        hintText: '1234 5678 9012 3456',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cardExpiryCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryDateInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Срок действия',
                              hintText: 'ММ/ГГ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cardCvvCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Имя держателя',
                        hintText: 'Иван Иванов',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 24),
            Text('Комментарии (необязательно)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _commentsCtrl,
              focusNode: _commentsFocusNode,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => _commentsFocusNode.unfocus(),
              maxLength: 256,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Особые пожелания или заметки...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: nights > 0 ? 'Подтвердить бронь — ₽${total.toStringAsFixed(0)}' : 'Выберите даты',
              onTap: nights > 0 ? _book : _pickDateRange,
              loading: _loading,
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildPaymentOption(ThemeData theme, String value, String label) {
    final selected = _paymentMethod == value;
    final activeColor = theme.colorScheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.14) : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? activeColor : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? activeColor : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final String label;
  const _AmenityTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
