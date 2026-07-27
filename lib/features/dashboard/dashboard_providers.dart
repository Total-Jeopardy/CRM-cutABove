import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cut_above/features/shops/data/shop_model.dart';
import 'package:cut_above/features/shops/presentation/shops_providers.dart';

class DashboardAreaStats {
  const DashboardAreaStats({required this.total, required this.enrolled});

  final int total;
  final int enrolled;
}

class DashboardRepStats {
  const DashboardRepStats({
    required this.visited,
    required this.committed,
    required this.enrolled,
  });

  final int visited;
  final int committed;
  final int enrolled;
}

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.hot,
    required this.warm,
    required this.nurture,
    required this.cold,
    required this.committed,
    required this.enrolled,
    required this.overdueFollowups,
    required this.byArea,
    required this.byRep,
    required this.byOutreach,
    required this.visited,
    required this.interested,
    required this.demoBooked,
    required this.funnelCommitted,
    required this.funnelEnrolled,
  });

  final int total;
  final int hot;
  final int warm;
  final int nurture;
  final int cold;
  final int committed;
  final int enrolled;
  final int overdueFollowups;
  final Map<String, DashboardAreaStats> byArea;
  final Map<String, DashboardRepStats> byRep;
  final Map<String, int> byOutreach;

  final int visited;
  final int interested;
  final int demoBooked;
  final int funnelCommitted;
  final int funnelEnrolled;

  double get conversionRate => total == 0 ? 0 : (enrolled / total * 100);
}

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  return ref.watch(shopsListProvider).whenData((shops) {
    final byArea = <String, DashboardAreaStats>{};
    final byRep = <String, DashboardRepStats>{};
    final byOutreach = <String, int>{};
    for (final s in shops) {
      final area = s.area ?? 'Unknown';
      final current =
          byArea[area] ?? const DashboardAreaStats(total: 0, enrolled: 0);
      byArea[area] = DashboardAreaStats(
        total: current.total + 1,
        enrolled: current.enrolled + (s.isEnrolled ? 1 : 0),
      );

      final rep = s.createdByName ?? 'Unknown';
      final repCurrent =
          byRep[rep] ??
          const DashboardRepStats(visited: 0, committed: 0, enrolled: 0);
      byRep[rep] = DashboardRepStats(
        visited: repCurrent.visited + 1,
        committed: repCurrent.committed + (s.status == 'Committed' ? 1 : 0),
        enrolled: repCurrent.enrolled + (s.isEnrolled ? 1 : 0),
      );

      final type = s.outreachType;
      byOutreach[type] = (byOutreach[type] ?? 0) + 1;
    }
    return DashboardStats(
      total: shops.length,
      hot: shops.where((s) => s.scoreTier == 'Hot').length,
      warm: shops.where((s) => s.scoreTier == 'Warm').length,
      nurture: shops.where((s) => s.scoreTier == 'Nurture').length,
      cold: shops.where((s) => s.scoreTier == 'Cold').length,
      committed: shops.where((s) => s.status == 'Committed').length,
      enrolled: shops.where((s) => s.isEnrolled).length,
      overdueFollowups: shops.where((s) => s.isFollowupOverdue).length,
      byArea: byArea,
      byRep: byRep,
      byOutreach: byOutreach,
      visited: shops.where((s) => s.status == 'Visited').length,
      interested: shops.where((s) => s.status == 'Interested').length,
      demoBooked: shops.where((s) => s.status == 'Demo Booked').length,
      funnelCommitted: shops.where((s) => s.status == 'Committed').length,
      funnelEnrolled: shops.where((s) => s.isEnrolled).length,
    );
  });
});

final overdueShopsProvider = Provider<AsyncValue<List<ShopModel>>>((ref) {
  return ref
      .watch(shopsListProvider)
      .whenData((shops) => shops.where((s) => s.isFollowupOverdue).toList());
});
