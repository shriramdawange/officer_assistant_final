// ============================================================
// screens/dashboard_screen.dart
// Executive Dashboard — Namaste greeting + action cards
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/letter_model.dart';
import '../models/user_profile.dart';
import '../widgets/premium_action_card.dart';
import '../widgets/shimmer_loaders.dart';
import 'recorder_screen.dart';
import 'history_screen.dart';
import 'calendar_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    HistoryScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Home Tab ────────────────────────────────────────
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LetterProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final letters = context.watch<LetterProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.navyBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.navyGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Greeting
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                        '${AppConstants.greetingPrefix} ${profile.firstName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(color: Colors.white),
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms)
                                      .slideX(begin: -0.2, end: 0),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.designation,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            // Avatar
                            GestureDetector(
                              onTap: () => _showProfileMenu(context, auth),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: profile.avatarUrl != null
                                    ? NetworkImage(profile.avatarUrl!)
                                    : null,
                                child: profile.avatarUrl == null
                                    ? Text(
                                        profile.firstName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Date & stats row
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppTheme.gold,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                              ).format(DateTime.now()),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${letters.letters.length} Letters',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.goldLight,
                                      fontWeight: FontWeight.w600,
                                    ),
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
          ),

          // ── Date Picker Strip ─────────────────────────
          SliverToBoxAdapter(
            child: _DatePickerStrip(
              selectedDate: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
          ),

          // ── Action Cards Grid ─────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),

                  // Primary 2-column grid
                  Row(
                    children: [
                      Expanded(
                        child: PremiumActionCard(
                          icon: Icons.mic_rounded,
                          title: AppConstants.newLetter,
                          subtitle: 'Speak in Marathi',
                          onTap: () => _navigateToRecorder(context),
                          isPrimary: true,
                          animationIndex: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumActionCard(
                          icon: Icons.document_scanner_rounded,
                          title: AppConstants.scanDocument,
                          subtitle: 'OCR & reformat',
                          onTap: () => _navigateToScan(context),
                          iconColor: const Color(0xFF00897B),
                          animationIndex: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Secondary wide cards
                  WideActionCard(
                    icon: Icons.history_rounded,
                    title: AppConstants.viewHistory,
                    subtitle: 'Browse all your letters',
                    onTap: () {
                      // Switch to history tab
                      final state = context
                          .findAncestorStateOfType<_DashboardScreenState>();
                      state?.setState(() => state._selectedIndex = 1);
                    },
                    color: AppTheme.navyBlue,
                    animationIndex: 2,
                  ),
                  const SizedBox(height: 8),
                  WideActionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendar View',
                    subtitle: 'Letters by date',
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<_DashboardScreenState>();
                      state?.setState(() => state._selectedIndex = 2);
                    },
                    color: const Color(0xFF6A1B9A),
                    animationIndex: 3,
                  ),
                ],
              ),
            ),
          ),

          // ── Recent Letters ────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Letters',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            final state = context
                                .findAncestorStateOfType<
                                  _DashboardScreenState
                                >();
                            state?.setState(() => state._selectedIndex = 1);
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                  if (letters.isLoadingHistory)
                    const Column(
                      children: [LetterCardShimmer(), LetterCardShimmer()],
                    )
                  else if (letters.letters.isEmpty)
                    _EmptyState()
                  else
                    ...letters.letters
                        .take(3)
                        .map((l) => _RecentLetterCard(letter: l)),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRecorder(context),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('New Letter'),
        backgroundColor: AppTheme.navyBlue,
      ),
    );
  }

  void _navigateToRecorder(BuildContext context) {
    context.read<LetterProvider>().reset();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecorderScreen()),
    );
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileSheet(profile: auth.profile),
    );
  }
}

// ── Date Picker Strip ─────────────────────────────────────────
class _DatePickerStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerStrip({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      color: AppTheme.navyBlue,
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: dates.length,
          itemBuilder: (_, i) {
            final date = dates[i];
            final isSelected =
                date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;
            final isToday =
                date.day == now.day &&
                date.month == now.month &&
                date.year == now.year;

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                width: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: isToday && !isSelected
                      ? Border.all(color: AppTheme.gold, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date).substring(0, 3),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.navyBlue
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.navyBlue : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Recent Letter Card ────────────────────────────────────────
class _RecentLetterCard extends StatelessWidget {
  final LetterModel letter;

  const _RecentLetterCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.navyBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.description_rounded,
            color: AppTheme.navyBlue,
            size: 22,
          ),
        ),
        title: Text(
          letter.subject,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          letter.shortDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(letter.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            letter.status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _statusColor(letter.status),
            ),
          ),
        ),
        onTap: () {
          context.read<LetterProvider>().setCurrentLetter(letter);
          Navigator.pushNamed(context, '/editor');
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'final':
        return AppTheme.successGreen;
      case 'exported':
        return AppTheme.navyBlue;
      default:
        return Colors.orange;
    }
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 56,
            color: AppTheme.navyBlue.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No letters yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the mic button to create your first letter',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Profile Bottom Sheet ──────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final UserProfile profile;

  const _ProfileSheet({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.navyBlue.withValues(alpha: 0.1),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.firstName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navyBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            profile.designation,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          Text(profile.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.navyBlue,
            ),
            title: const Text('Rajpatra AI v1.0'),
            subtitle: const Text('Gen Solution — Government of Maharashtra'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.navyBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.navyBlue : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.navyBlue : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
