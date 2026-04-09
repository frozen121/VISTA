import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../data/models/booking_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/snackbar_util.dart';
import '../widgets/booking_card.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  double? _minPrice;
  double? _maxPrice;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _guestCount;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  List<String> _selectedAmenities = [];
  static const _categories = ['all', 'standard', 'deluxe', 'suite', 'presidential'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();
    final rooms = context.watch<RoomProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userId = auth.currentUser?.id ?? 0;
    final userBookings = bookings.getUserBookings(userId);

    List<BookingModel> filterBookings(List<BookingModel> bookings) {
      return bookings.where((b) {
        if (_selectedCategory != 'all' && b.roomCategory != _selectedCategory) return false;
        if (_minPrice != null && b.totalPrice < _minPrice!) return false;
        if (_maxPrice != null && b.totalPrice > _maxPrice!) return false;
        if (_startDate != null && b.checkIn.isBefore(_startDate!)) return false;
        if (_endDate != null && b.checkOut.isAfter(_endDate!)) return false;
        if (_guestCount != null) {
          try {
            final room = rooms.allRooms.firstWhere((r) => r.id == b.roomId);
            if (room.capacity < _guestCount!) return false;
          } catch (e) {
            return false;
          }
        }
        if (_searchQuery.isNotEmpty && !b.roomName.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
        
        if (_selectedAmenities.isNotEmpty) {
          try {
            final room = rooms.allRooms.firstWhere((r) => r.id == b.roomId);
            final hasAllAmenities = _selectedAmenities.every((amenity) => room.amenities.contains(amenity));
            if (!hasAllAmenities) return false;
          } catch (e) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }

    final active = filterBookings(userBookings.where((b) => ['confirmed', 'pending'].contains(b.status)).toList());
    final completed = filterBookings(userBookings.where((b) => b.status == 'completed').toList());
    final cancelled = filterBookings(userBookings.where((b) => b.status == 'cancelled').toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои бронирования'),
        bottom: TabBar(
          controller: _tab,
          labelColor: isDark ? AppColors.accent : AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: isDark ? AppColors.accent : AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Активные'),
          Tab(text: 'Завершенные'),
          Tab(text: 'Отмененные'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SearchBar(onChanged: (query) => setState(() => _searchQuery = query)),
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
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookingList(bookings: active, onCancel: (id) => _cancelBooking(context, id, userId)),
                _BookingList(bookings: completed),
                _BookingList(bookings: cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final rooms = context.read<RoomProvider>();
    final minPriceCtrl = TextEditingController(text: _minPrice?.toString());
    final maxPriceCtrl = TextEditingController(text: _maxPrice?.toString());
    DateTime? checkIn = _startDate;
    DateTime? checkOut = _endDate;
    int guestCount = _guestCount ?? 1;
    String selectedCategory = _selectedCategory;
    List<String> selectedAmenities = List<String>.from(_selectedAmenities);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          width: 40, height: 4,
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
                        children: _categories.map((cat) {
                          final selected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(_categoryLabel(cat)),
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
                                  _selectedCategory = 'all';
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _guestCount = null;
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedAmenities = [];
                                  selectedCategory = 'all';
                                  checkIn = null;
                                  checkOut = null;
                                  selectedAmenities = [];
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

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'standard':
        return 'Стандарт';
      case 'deluxe':
        return 'Делюкс';
      case 'suite':
        return 'Сюит';
      case 'presidential':
        return 'Президентский';
      default:
        return 'Все';
    }
  }

  void _cancelBooking(BuildContext context, int bookingId, int userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelBookingSheet(
        bookingId: bookingId,
        userId: userId,
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final void Function(int)? onCancel;

  const _BookingList({required this.bookings, this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(height: 16),
            Text('Здесь пока нет бронирований', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Ваши бронирования появятся здесь',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final b = bookings[i];
        return BookingCard(
          booking: b,
          onTap: () => _showDetails(context, b),
        );
      },
    );
  }

  void _showDetails(BuildContext context, BookingModel b) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Детали бронирования', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _DetailRow('Номер', b.roomName),
            _DetailRow('Категория', _categoryLabel(b.roomCategory)),
            _DetailRow('Заезд', DateUtil.formatDate(b.checkIn)),
            _DetailRow('Выезд', DateUtil.formatDate(b.checkOut)),
            _DetailRow('Ночей', '${b.nights}'),
            _DetailRow('Гости', _guestCountLabel(context, b)),
            _DetailRow('Итого', '₽${b.totalPrice.toStringAsFixed(0)}'),
            _DetailRow('Баллы', '+${b.pointsEarned} баллов'),
            _DetailRow('Статус', _statusLabel(b.status)),
            _DetailRow('Дата бронирования', DateUtil.formatDate(b.createdAt)),

            if (onCancel != null && ['confirmed', 'pending'].contains(b.status)) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel!(b.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Отменить'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

String _statusLabel(String s) {
  switch (s) {
    case 'confirmed': return 'Подтверждено';
    case 'pending': return 'В ожидании';
    case 'cancelled': return 'Отменено';
    case 'completed': return 'Завершено';
    default: return s;
  }
}

String _guestCountLabel(BuildContext context, BookingModel booking) {
  try {
    final room = context.read<RoomProvider>().allRooms.firstWhere((r) => r.id == booking.roomId);
    return '${room.capacity} ${room.capacity == 1 ? 'гость' : 'гостей'}';
  } catch (_) {
    return '—';
  }
}

String _categoryLabel(String cat) {
  switch (cat) {
    case 'standard':
      return 'Стандарт';
    case 'deluxe':
      return 'Делюкс';
    case 'suite':
      return 'Люкс';
    case 'presidential':
      return 'Президентский';
    default:
      return cat;
  }
}

class _CancelBookingSheet extends StatefulWidget {
  final int bookingId;
  final int userId;

  const _CancelBookingSheet({
    required this.bookingId,
    required this.userId,
  });

  @override
  State<_CancelBookingSheet> createState() => _CancelBookingSheetState();
}

class _CancelBookingSheetState extends State<_CancelBookingSheet> {
  bool _loading = false;

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
            Text('Отменить бронирование?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Вы уверены, что хотите отменить эту бронь? Это действие невозможно отменить.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Оставить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
                            ),
                          )
                        : const Text('Отменить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancel() async {
    setState(() => _loading = true);
    try {
      await context.read<BookingProvider>().cancelBooking(widget.bookingId, widget.userId);
      await context.read<AuthProvider>().refreshCurrentUser();
      if (context.mounted) {
        Navigator.pop(context);
        SnackBarUtil.showError(context, 'Бронирование отменено');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtil.showError(context, 'Ошибка при отмене бронирования');
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}

class _SearchBar extends StatelessWidget {
  final void Function(String) onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextField(
                onChanged: onChanged,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Поиск номера',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
