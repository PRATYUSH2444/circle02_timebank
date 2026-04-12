import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_provider.dart';
import '../../../utils/time_utils.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          "Activity",
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () => ref.invalidate(activityProvider),
          ),
        ],
      ),
      body: activityAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history, color: Colors.white24, size: 52),
                  SizedBox(height: 14),
                  Text(
                    "No activity yet\nBook a session to get started!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, height: 1.6),
                  ),
                ],
              ),
            );
          }

          // ── Token balance summary ────────────────────────────────────
          final totalEarned = list
              .where((a) => a['type'] == 'credit')
              .fold<int>(0, (sum, a) => sum + (a['amount'] as int? ?? 0));
          final totalSpent = list
              .where((a) => a['type'] == 'debit')
              .fold<int>(0, (sum, a) => sum + ((a['amount'] as int? ?? 0).abs()));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [

              // ── Summary cards ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: "Earned",
                      value: "+$totalEarned",
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: "Spent",
                      value: "-$totalSpent",
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: "Net",
                      value: "${totalEarned - totalSpent}",
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "History",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // ── Activity list ──────────────────────────────────────────
              ...list.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;

                // Date separator
                final showDate = i == 0 ||
                    !TimeUtils.isSameDay(
                      list[i - 1]['created_at']?.toString(),
                      a['created_at']?.toString(),
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          TimeUtils.formatDateLabel(
                              a['created_at']?.toString()),
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    _ActivityTile(activity: a),
                  ],
                );
              }),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const _ActivitySkeleton(),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Activity tile ────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityTile({required this.activity});

  IconData _icon() {
    switch (activity['icon']) {
      case 'book': return Icons.calendar_today_rounded;
      case 'check': return Icons.check_circle_rounded;
      case 'star': return Icons.star_rounded;
      case 'cancel': return Icons.cancel_rounded;
      default: return Icons.circle_outlined;
    }
  }

  Color _color() {
    switch (activity['type']) {
      case 'credit': return Colors.greenAccent;
      case 'debit': return Colors.redAccent;
      case 'refund': return Colors.orangeAccent;
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final amount = activity['amount'] as int? ?? 0;
    final amountStr = amount > 0 ? '+$amount' : '$amount';
    final createdAt = activity['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                if (activity['subtitle'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    activity['subtitle'],
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  createdAt != null
                      ? "${TimeUtils.formatDateLabel(createdAt)} • ${TimeUtils.formatClock(createdAt)}"
                      : '',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Amount badge
          if (amount != 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: color.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.token_rounded, color: color, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    amountStr,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 160,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 10, width: 100,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          Container(height: 28, width: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }
}