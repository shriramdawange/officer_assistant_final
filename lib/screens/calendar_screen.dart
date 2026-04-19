// ============================================================
// screens/calendar_screen.dart
// Calendar view — letters by date (in-memory, no Supabase)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_provider.dart';
import '../core/theme.dart';
import '../models/letter_model.dart';
import 'editor_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load after first frame so Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLettersForDate(_selectedDate);
    });
  }

  void _loadLettersForDate(DateTime date) {
    // Letters are derived reactively from LetterProvider in build()
    // Just update the selected date and let build() re-filter
    setState(() => _selectedDate = date);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-filter whenever letters change
    final provider = context.watch<LetterProvider>();
    final dayLetters = provider.letters.where((l) {
      return l.createdAt.year == _selectedDate.year &&
          l.createdAt.month == _selectedDate.month &&
          l.createdAt.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppTheme.navyBlue,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Calendar Widget ───────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _previousMonth,
                      color: AppTheme.navyBlue,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      color: AppTheme.navyBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Day headers
                Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar grid
                _buildCalendarGrid(provider.letters),
              ],
            ),
          ),

          // ── Selected Date Letters ─────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Letters on ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Expanded(
                  child: dayLetters.isEmpty
                      ? _EmptyDay()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dayLetters.length,
                          itemBuilder: (_, i) =>
                              _DayLetterTile(letter: dayLetters[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<LetterModel> allLetters) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday % 7;
    final today = DateTime.now();

    // Build a set of days that have letters for dot indicators
    final daysWithLetters = allLetters
        .where(
          (l) =>
              l.createdAt.year == _focusedMonth.year &&
              l.createdAt.month == _focusedMonth.month,
        )
        .map((l) => l.createdAt.day)
        .toSet();

    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected =
          date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;
      final isToday =
          date.day == today.day &&
          date.month == today.month &&
          date.year == today.year;
      final hasLetters = daysWithLetters.contains(day);

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.navyBlue
                  : isToday
                  ? AppTheme.navyBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppTheme.navyBlue, width: 1.5)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppTheme.navyBlue
                          : AppTheme.textDark,
                    ),
                  ),
                ),
                // Dot indicator for days with letters
                if (hasLetters && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

// ── Day Letter Tile ───────────────────────────────────────────
class _DayLetterTile extends StatelessWidget {
  final LetterModel letter;

  const _DayLetterTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.navyBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.description_rounded,
            color: AppTheme.navyBlue,
            size: 20,
          ),
        ),
        title: Text(
          letter.subject,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('hh:mm a').format(letter.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMuted,
        ),
        onTap: () {
          context.read<LetterProvider>().setCurrentLetter(letter);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
        },
      ),
    );
  }
}

// ── Empty Day ─────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: AppTheme.navyBlue.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No letters on this day',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
