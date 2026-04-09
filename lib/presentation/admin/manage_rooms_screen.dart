import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/room_provider.dart';
import '../../data/models/room_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 2000;
  String? _selectedCategory;
  List<String> _selectedAmenities = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int? _guestCount;

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredRooms = _filterRooms(roomProvider.allRooms);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление номерами'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: roomProvider.load,
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
      body: roomProvider.allRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined, size: 64, color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(height: 12),
                  Text('Номеров пока нет', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Добавить первый номер',
                    fullWidth: false,
                    icon: Icons.add,
                    onTap: () => _showRoomForm(context, null),
                  ),
                ],
              ),
            )
          : Column(
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
                          onPressed: () => _showFilterSheet(context, roomProvider),
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
                // Rooms list
                Expanded(
                  child: filteredRooms.isEmpty
                      ? Center(
                          child: Text('Номеров не найдено',
                              style: Theme.of(context).textTheme.bodyMedium),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRooms.length,
                          itemBuilder: (ctx, i) {
                            final room = filteredRooms[i];
                            return _AdminRoomCard(
                              room: room,
                              onEdit: () => _showRoomForm(context, room),
                              onDelete: () => _confirmDelete(context, room),
                              onToggle: () => roomProvider.toggleAvailability(room.id),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoomForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить номер', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    return rooms.where((room) {
      // Search by name
      if (_searchQuery.isNotEmpty &&
          !room.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Filter by price
      if (room.price < _minPrice || room.price > _maxPrice) {
        return false;
      }

      // Filter by category
      if (_selectedCategory != null && room.category != _selectedCategory) {
        return false;
      }

      // Filter by capacity
      if (_guestCount != null && room.capacity < _guestCount!) {
        return false;
      }

      // Filter by amenities
      if (_selectedAmenities.isNotEmpty) {
        final roomAmenities =
            room.amenities.map((a) => a.toLowerCase()).toSet();
        final selectedLower =
            _selectedAmenities.map((a) => a.toLowerCase()).toSet();
        if (!selectedLower.every((amenity) => roomAmenities.contains(amenity))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterSheet(BuildContext context, RoomProvider roomProvider) {
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
                        children: roomProvider.allAmenities.map((amenity) {
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
                                  _minPrice = 0;
                                  _maxPrice = 2000;
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedAmenities = [];
                                  _guestCount = null;
                                  selectedCategory = null;
                                  checkIn = null;
                                  checkOut = null;
                                  selectedAmenities = [];
                                  guestCount = 1;
                                  minPriceCtrl.text = '0';
                                  maxPriceCtrl.text = '2000';
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
                                  _minPrice = minPriceCtrl.text.isNotEmpty ? double.tryParse(minPriceCtrl.text) ?? 0 : 0;
                                  _maxPrice = maxPriceCtrl.text.isNotEmpty ? double.tryParse(maxPriceCtrl.text) ?? 2000 : 2000;
                                  _startDate = checkIn;
                                  _endDate = checkOut;
                                  _selectedAmenities = selectedAmenities;
                                  _guestCount = guestCount;
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

  void _showRoomForm(BuildContext context, RoomModel? room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomFormSheet(room: room),
    );
  }

  void _confirmDelete(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomDeleteSheet(room: room),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final String? selectedCategory;
  final List<String> selectedAmenities;
  final Function(double) onMinPriceChanged;
  final Function(double) onMaxPriceChanged;
  final Function(String?) onCategoryChanged;
  final Function(List<String>) onAmenitiesChanged;

  const _FilterSheet({
    required this.minPrice,
    required this.maxPrice,
    required this.selectedCategory,
    required this.selectedAmenities,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    required this.onCategoryChanged,
    required this.onAmenitiesChanged,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  late String? _selectedCategory;
  late List<String> _selectedAmenities;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;

  final categories = ['deluxe', 'suite', 'standard', 'presidential'];
  final categoryLabels = {
    'deluxe': 'Делюкс',
    'suite': 'Люкс',
    'standard': 'Стандарт',
    'presidential': 'Президентский',
  };

  @override
  void initState() {
    super.initState();
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _selectedCategory = widget.selectedCategory;
    _selectedAmenities = List.from(widget.selectedAmenities);
    _minPriceCtrl = TextEditingController(text: _minPrice.toStringAsFixed(0));
    _maxPriceCtrl = TextEditingController(text: _maxPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amenities = context.read<RoomProvider>().allAmenities;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Text('Фильтры', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              // Categories
              Text('Категория', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(categoryLabels[cat] ?? cat),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedCategory = v ? cat : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Price range
              Text('Цена', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceCtrl,
                      onChanged: (v) {
                        setState(() {
                          _minPrice = double.tryParse(v) ?? 0;
                        });
                      },
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
                      controller: _maxPriceCtrl,
                      onChanged: (v) {
                        setState(() {
                          _maxPrice = double.tryParse(v) ?? 2000;
                        });
                      },
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
              // Amenities
              Text('Удобства', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
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
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _minPrice = 0;
                          _maxPrice = 2000;
                          _selectedCategory = null;
                          _selectedAmenities.clear();
                          _minPriceCtrl.text = '0';
                          _maxPriceCtrl.text = '2000';
                        });
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
                        widget.onMinPriceChanged(_minPrice);
                        widget.onMaxPriceChanged(_maxPrice);
                        widget.onCategoryChanged(_selectedCategory);
                        widget.onAmenitiesChanged(_selectedAmenities);
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
  }
}

class _RoomDeleteSheet extends StatelessWidget {
  final RoomModel room;

  const _RoomDeleteSheet({required this.room});

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
            Text('Удалить номер?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Удалить "${room.name}"? Это нельзя отменить.', style: theme.textTheme.bodyMedium),
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
                      await context.read<RoomProvider>().deleteRoom(room.id);
                      Navigator.pop(context);
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

class _AdminRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AdminRoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Mini image / gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: room.imagePaths.isNotEmpty
                  ? (room.imagePaths.first.startsWith('assets/')
                      ? Image.asset(room.imagePaths.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _miniGradient(room.category))
                      : Image.file(File(room.imagePaths.first), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _miniGradient(room.category)))
                  : _miniGradient(room.category),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${room.categoryLabel} • ₽${room.price.toStringAsFixed(0)}/ночь • ${room.capacity} ${room.capacity == 1 ? 'гость' : 'гостей'}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (room.isAvailable ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              room.isAvailable ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: room.isAvailable ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room.isAvailable ? 'Доступен' : 'Недоступен',
                              style: TextStyle(
                                fontSize: 11,
                                color: room.isAvailable ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  foregroundColor: AppColors.info,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniGradient(String category) {
    final colors = _colors(category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(_icon(category), color: Colors.white.withValues(alpha: 0.8), size: 28),
      alignment: Alignment.center,
    );
  }

  List<Color> _colors(String c) {
    switch (c) {
      case 'presidential': return [const Color(0xFF2C1810), const Color(0xFF8B4513)];
      case 'suite': return [const Color(0xFF1A1A3E), const Color(0xFF6366F1)];
      case 'deluxe': return [const Color(0xFF0F2027), const Color(0xFF2C5364)];
      default: return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    }
  }

  IconData _icon(String c) {
    switch (c) {
      case 'presidential': return Icons.stars_rounded;
      case 'suite': return Icons.hotel_rounded;
      case 'deluxe': return Icons.king_bed_rounded;
      default: return Icons.bed_rounded;
    }
  }
}

class _RoomFormSheet extends StatefulWidget {
  final RoomModel? room;
  const _RoomFormSheet({this.room});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _capacityCtrl;
  List<String> _selectedAmenities = [];
  String _category = 'standard';
  List<String> _imagePaths = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _priceCtrl = TextEditingController(text: r?.price.toStringAsFixed(0) ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _capacityCtrl = TextEditingController(text: '${r?.capacity ?? 2}');
    _category = r?.category ?? 'standard';
    _imagePaths = List.from(r?.imagePaths ?? []);

    if (r != null) {
      _selectedAmenities = List.from(r.amenities);
    } else {
      final selectedAmenities = context.read<RoomProvider>().selectedAmenities;
      _selectedAmenities = List.from(selectedAmenities);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePaths = [picked.path]);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final amenities = List<String>.from(_selectedAmenities);
    final capacity = int.tryParse(_capacityCtrl.text) ?? 2;
    final price = double.tryParse(_priceCtrl.text) ?? 0;

    final provider = context.read<RoomProvider>();

    if (widget.room == null) {
      await provider.createRoom(
        name: _nameCtrl.text.trim(),
        category: _category,
        price: price,
        description: _descCtrl.text.trim(),
        imagePaths: _imagePaths,
        amenities: amenities,
        capacity: capacity,
      );
    } else {
      await provider.updateRoom(
        widget.room!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _category,
          price: price,
          description: _descCtrl.text.trim(),
          imagePaths: _imagePaths,
          amenities: amenities,
          capacity: capacity,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
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
        return 'Стандарт';
    }
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textSecondary),
            SizedBox(height: 10),
            Text('Добавьте фото номера', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('Нажмите, чтобы выбрать', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final rooms = context.watch<RoomProvider>();
    final isEdit = widget.room != null;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(isEdit ? 'Редактировать номер' : 'Добавить новый номер', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Название номера',
                  controller: _nameCtrl,
                  prefixIcon: Icons.hotel_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Введите название номера' : null,
                ),
                const SizedBox(height: 14),
                // Category
                Text('Категория', style: theme.textTheme.labelLarge?.copyWith(color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['standard', 'deluxe', 'suite', 'presidential'].map((cat) {
                    final sel = _category == cat;
                    return FilterChip(
                      label: Text(cat[0].toUpperCase() + cat.substring(1)),
                      selected: sel,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Цена/ночь (₽)',
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Введите корректную цену' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Количество гостей',
                        controller: _capacityCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.people_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Описание',
                  controller: _descCtrl,
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Введите описание' : null,
                ),
                const SizedBox(height: 14),
                Text('Удобства', style: theme.textTheme.labelLarge?.copyWith(color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                Builder(builder: (_) {
                  final amenityOptions = {...rooms.allAmenities, ..._selectedAmenities}.toList();
                  if (amenityOptions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                      ),
                      child: const Text(
                        'Пока нет готовых удобств. Выберите их в фильтрах номеров, когда они появятся.',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenityOptions.map((amenity) {
                      final selected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                    label: Text(amenity),
                    selected: selected,
                    onSelected: (active) {
                      setState(() {
                        if (active) {
                          if (!_selectedAmenities.contains(amenity)) {
                            _selectedAmenities.add(amenity);
                          }
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 14),
                // Photo
                Text('Фото', style: theme.textTheme.labelLarge?.copyWith(color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _imagePaths.isNotEmpty
                          ? (_imagePaths.first.startsWith('assets/')
                              ? Image.asset(
                                  _imagePaths.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) {
                                    return _buildPhotoPlaceholder();
                                  },
                                )
                              : Image.file(
                                  File(_imagePaths.first),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) {
                                    return _buildPhotoPlaceholder();
                                  },
                                ))
                          : _buildPhotoPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: isEdit ? 'Сохранить изменения' : 'Создать номер',
                  onTap: _save,
                  loading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _ImageThumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80, height: 80,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: path.startsWith('assets/')
                ? Image.asset(path, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.divider))
                : Image.file(File(path), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.divider)),
          ),
        ),
        if (!path.startsWith('assets/'))
          Positioned(
            top: 2, right: 10,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
