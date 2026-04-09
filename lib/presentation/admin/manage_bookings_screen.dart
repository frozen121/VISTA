import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/booking_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/room_provider.dart';
import '../../data/models/booking_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../widgets/booking_card.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String? _statusFilter;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  int? _guestCount;
  List<String> _selectedAmenities = [];

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
        return status;
    }
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    final roomProvider = context.read<RoomProvider>();
    return bookings.where((booking) {
      if (_searchQuery.isNotEmpty &&
          !booking.roomName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_statusFilter != null && booking.status != _statusFilter) {
        return false;
      }

      if (_selectedCategory != null && booking.roomCategory != _selectedCategory) {
        return false;
      }

      if (_minPrice != null && booking.totalPrice < _minPrice!) {
        return false;
      }

      if (_maxPrice != null && booking.totalPrice > _maxPrice!) {
        return false;
      }

      if (_startDate != null && booking.checkIn.isBefore(_startDate!)) {
        return false;
      }

      if (_endDate != null && booking.checkOut.isAfter(_endDate!)) {
        return false;
      }

      if (_guestCount != null) {
        try {
          final room = roomProvider.allRooms.firstWhere((r) => r.id == booking.roomId);
          if (room.capacity < _guestCount!) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      if (_selectedAmenities.isNotEmpty) {
        try {
          final room = roomProvider.allRooms.firstWhere((r) => r.id == booking.roomId);
          final roomAmenities = room.amenities.map((e) => e.toLowerCase()).toSet();
          if (!_selectedAmenities
              .map((e) => e.toLowerCase())
              .every(roomAmenities.contains)) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredBookings = _filterBookings(bookingProvider.allBookings);

    return Scaffold(
      appBar: AppBar(
        title: Text('Бронирования (${bookingProvider.allBookings.length})'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: bookingProvider.load,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          // Search bar and filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Поиск по названию номера',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: () => _showFilterSheet(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(0),
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Icon(Icons.filter_alt_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Все',
                    selected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...['pending', 'confirmed', 'completed', 'cancelled'].map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: _statusLabel(s),
                        selected: _statusFilter == s,
                        onTap: () => setState(() => _statusFilter = s),
                        color: _statusColor(s),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredBookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 56,
                            color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(height: 12),
                        Text('Бронирований не найдено', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (ctx, i) {
                      final b = filteredBookings[i];
                      return BookingCard(
                        booking: b,
                        onTap: () => _showBookingDetails(context, b),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final rooms = context.read<RoomProvider>();
    final minPriceCtrl = TextEditingController();
    final maxPriceCtrl = TextEditingController();
    DateTime? checkIn = _startDate;
    DateTime? checkOut = _endDate;
    String? selectedCategory = _selectedCategory;
    List<String> selectedAmenities = List<String>.from(_selectedAmenities);
    int guestCount = _guestCount ?? 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['standard', 'deluxe', 'suite', 'presidential'];
    final categoryLabels = {
      'standard': 'Стандарт',
      'deluxe': 'Делюкс',
      'suite': 'Люкс',
      'presidential': 'Президентский',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickDates() async {
              DateTime? tempRangeStart = checkIn;
              DateTime? tempRangeEnd = checkOut;
              DateTime tempFocusedDay = checkIn ?? DateTime.now();

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return SafeArea(
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.78,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                                      width: 40,
                                      height: 6,
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
                              const SizedBox(height: 16),
                              Expanded(
                                child: TableCalendar(
                                  locale: 'ru_RU',
                                  firstDay: DateTime(2020),
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
                                    defaultDecoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    weekendDecoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    outsideDecoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    disabledDecoration: const BoxDecoration(
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
                                        checkIn = tempRangeStart;
                                        checkOut = tempRangeEnd;
                                        setState(() {});
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

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
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
                      const SizedBox(height: 16),
                      Text('Фильтры', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      Text('Цена', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minPriceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Мин. цена',
                                prefixText: '₽ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxPriceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Макс. цена',
                                prefixText: '₽ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Даты', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickDates,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: checkIn != null
                                  ? (isDark ? AppColors.accent : AppColors.primary)
                                  : (isDark ? AppColors.dividerDark : AppColors.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: checkIn != null && checkOut != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateUtil.formatDateRange(checkIn!, checkOut!),
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Text(
                                            '${DateUtil.nightsBetween(checkIn!, checkOut!)} ночь${DateUtil.nightsBetween(checkIn!, checkOut!) == 1 ? '' : 'ей'}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Выберите даты заезда и выезда',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Гости', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (guestCount > 1) {
                                        setState(() {
                                          guestCount -= 1;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    '$guestCount',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        guestCount += 1;
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Категория', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final selected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(categoryLabels[cat] ?? cat),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Удобства', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: rooms.allAmenities.map((amenity) {
                          final selected = selectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: selected,
                            onSelected: (value) {
                              if (value) {
                                selectedAmenities.add(amenity);
                              } else {
                                selectedAmenities.remove(amenity);
                              }
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error.withOpacity(0.1),
                                foregroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _guestCount = null;
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedAmenities = [];
                                  selectedCategory = null;
                                  guestCount = 1;
                                  checkIn = null;
                                  checkOut = null;
                                  selectedAmenities = [];
                                  minPriceCtrl.text = '';
                                  maxPriceCtrl.text = '';
                                });
                                Navigator.pop(context);
                              },
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
                                setState(() {
                                  _selectedCategory = selectedCategory;
                                  _minPrice = minPriceCtrl.text.isNotEmpty ? double.tryParse(minPriceCtrl.text) : null;
                                  _maxPrice = maxPriceCtrl.text.isNotEmpty ? double.tryParse(maxPriceCtrl.text) : null;
                                  _guestCount = guestCount;
                                  _startDate = checkIn;
                                  _endDate = checkOut;
                                  _selectedAmenities = selectedAmenities;
                                });
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
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.statusConfirmed;
      case 'pending': return AppColors.statusPending;
      case 'cancelled': return AppColors.statusCancelled;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(booking: booking),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? AppColors.accent : AppColors.primary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : (isDark ? AppColors.cardDark : AppColors.surface),
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  const _BookingDetailSheet({required this.booking});

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.booking.status;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final b = widget.booking;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Бронь #${b.id}', style: theme.textTheme.titleLarge)),
              _StatusBadge(status: _status),
            ],
          ),
          const SizedBox(height: 20),
          _Row('Номер', b.roomName),
          _Row('Категория', b.roomCategory[0].toUpperCase() + b.roomCategory.substring(1)),
          _Row('Пользователь', '#${b.userId}'),
          _Row('Заезд', DateUtil.formatDate(b.checkIn)),
          _Row('Выезд', DateUtil.formatDate(b.checkOut)),
          _Row('Ночей', '${b.nights}'),
          _Row('Итого', '₽${b.totalPrice.toStringAsFixed(0)}'),
          _Row('Тип оплаты', b.paymentMethod == null ? 'Не указано' : b.paymentMethod == 'card' ? 'Карта' : 'Наличные'),
          _Row('Статус оплаты', b.paymentMethod != null ? 'Оплачено' : 'Не оплачено'),
          _Row('Баллы', '+${b.pointsEarned} баллов'),
          _Row('Создано', DateUtil.formatDate(b.createdAt)),
          const SizedBox(height: 20),
          Text('Обновить статус', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['pending', 'confirmed', 'completed', 'cancelled'].map((s) {
              final sel = _status == s;
              final color = _statusColor(s);
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(s),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _status == b.status ? null : () async {
                await context.read<BookingProvider>().updateStatus(b.id, _status);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Применить статус'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed': return 'Подтверждено';
      case 'pending': return 'В ожидании';
      case 'cancelled': return 'Отменено';
      case 'completed': return 'Завершено';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.statusConfirmed;
      case 'pending': return AppColors.statusPending;
      case 'cancelled': return AppColors.statusCancelled;
      case 'completed': return AppColors.statusCompleted;
      default: return AppColors.textSecondary;
    }
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
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
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
