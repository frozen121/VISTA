import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../widgets/room_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categories = ['all', 'standard', 'deluxe', 'suite', 'presidential'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rooms = context.watch<RoomProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = auth.currentUser;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Доброе ${_greeting()}!',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.name.split(' ').first ?? 'Guest',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((user?.loyaltyPoints ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, size: 16, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${user!.loyaltyPoints} баллов',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Найдите идеальный отдых',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SearchBar(onChanged: rooms.setSearch),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: () => _showFilterSheet(context, rooms),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = rooms.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => rooms.setCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : (isDark ? AppColors.cardDark : AppColors.surface),
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? null
                            : Border.all(
                                color: isDark ? AppColors.dividerDark : AppColors.divider,
                              ),
                      ),
                      child: Text(
                        _categoryLabel(cat),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? (isDark ? AppColors.primary : Colors.white)
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${rooms.filteredRooms.length} номеров доступно',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: rooms.filteredRooms.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 56,
                              color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(height: 12),
                          Text('Номеров не найдено', style: theme.textTheme.titleMedium),
                          Text('Попробуйте другую категорию или поиск',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: rooms.filteredRooms.length,
                    itemBuilder: (context, i) {
                      final room = rooms.filteredRooms[i];
                      return RoomCard(
                        room: room,
                        onTap: () => context.push('/user/room/${room.id}'),
                        onAbout: () => context.push('/user/room/${room.id}'),
                        onBook: () => context.push('/user/room/${room.id}?book=true'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, RoomProvider rooms) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minPriceCtrl = TextEditingController(text: rooms.minPrice?.toString());
    final maxPriceCtrl = TextEditingController(text: rooms.maxPrice?.toString());
    final selectedAmenities = List<String>.from(rooms.selectedAmenities);
    int guestCount = rooms.guestCount ?? 1;
    DateTime? checkIn = rooms.checkIn;
    DateTime? checkOut = rooms.checkOut;

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

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
                  child: SingleChildScrollView(
                    controller: scrollController,
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
                        const SizedBox(height: 20),
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
                                  color: isDark ? AppColors.cardDark : AppColors.background,
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
                                          guestCount -= 1;
                                          setState(() {});
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
                                        guestCount += 1;
                                        setState(() {});
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
                            final selected = rooms.selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(_categoryLabel(cat)),
                              selected: selected,
                              onSelected: (_) {
                                rooms.setCategory(cat);
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: const Text('Только доступные'),
                          value: rooms.availableOnly,
                          onChanged: (value) {
                            rooms.setAvailableOnly(value);
                            setState(() {});
                          },
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  rooms.setCategory('all');
                                  rooms.setAvailableOnly(false);
                                  rooms.setPriceRange(null, null);
                                  rooms.setSelectedAmenities([]);
                                  rooms.setDateRange(null, null);
                                  rooms.setGuestCount(null);
                                  guestCount = 1;
                                  checkIn = null;
                                  checkOut = null;
                                  setState(() {});
                                },
                                child: const Text('Сбросить'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final minPrice = minPriceCtrl.text.isNotEmpty ? double.tryParse(minPriceCtrl.text) : null;
                                  final maxPrice = maxPriceCtrl.text.isNotEmpty ? double.tryParse(maxPriceCtrl.text) : null;
                                  rooms.setPriceRange(minPrice, maxPrice);
                                  rooms.setSelectedAmenities(selectedAmenities);
                                  rooms.setDateRange(checkIn, checkOut);
                                  rooms.setGuestCount(guestCount);
                                  Navigator.pop(context);
                                },
                                child: const Text('Применить'),
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
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'утро';
    if (h < 18) return 'день';
    return 'вечер';
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
        return 'Все';
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
