import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';

/// Displays real-time reward eligibility for a patient and lets frontdesk/admin
/// claim an eligible reward on their behalf (deducting points immediately and
/// marking reward history as completed).
class EligibleRewardsPanel extends StatefulWidget {
  final String userId;
  final String patientName;
  final int currentPoints;
  final int projectedPoints;
  final ValueChanged<int> onPointsUpdated;
  final bool compact;

  const EligibleRewardsPanel({
    super.key,
    required this.userId,
    required this.patientName,
    required this.currentPoints,
    int? projectedPoints,
    required this.onPointsUpdated,
    this.compact = false,
  }) : projectedPoints = projectedPoints ?? currentPoints;

  @override
  State<EligibleRewardsPanel> createState() => _EligibleRewardsPanelState();
}

class _EligibleRewardsPanelState extends State<EligibleRewardsPanel> {
  bool _loading = false;
  String? _claimingRewardId;
  List<EligibleRewardItem> _rewards = [];

  @override
  void initState() {
    super.initState();
    _fetchEligible();
  }

  @override
  void didUpdateWidget(covariant EligibleRewardsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchEligible();
    }
  }

  Future<void> _fetchEligible() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _rewards = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final res = await RewardController.getEligibleForPatient(context, widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (responseCode(res.code) && res.data != null) {
        _rewards = res.data!.rewards;
      } else {
        _rewards = [];
      }
    });
  }

  Future<void> _confirmAndClaim(EligibleRewardItem reward) async {
    if (_claimingRewardId != null) return;
    final remainingPts = widget.currentPoints - reward.rewardPoint;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Claim Reward for Patient?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${widget.patientName}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Reward: ${reward.rewardName}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Points Deducted: -${reward.rewardPoint} pts',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Balance After Claim: ${widget.currentPoints} pts → $remainingPts pts',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reward history will be auto-marked as Completed.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Claim', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _claimingRewardId = reward.rewardId);
    final res = await RewardController.claimForPatient(
      context,
      userId: widget.userId,
      rewardId: reward.rewardId,
    );
    if (!mounted) return;

    setState(() => _claimingRewardId = null);

    if (responseCode(res.code) && res.data != null) {
      final result = res.data!;
      setState(() {
        _rewards.removeWhere((r) => r.rewardId == reward.rewardId);
      });
      widget.onPointsUpdated(result.newTotalPoints);
      AppToast.snackbar(
        context,
        'Claimed "${result.rewardName}" (-${result.pointsDeducted} pts). New balance: ${result.newTotalPoints} pts.',
      );
    } else {
      AppToast.snackbar(context, res.message ?? 'Failed to claim reward.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || widget.userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final claimableNow = _rewards.where((r) => r.rewardPoint <= widget.currentPoints).toList();
    final unlockingAfterPay = _rewards
        .where((r) => r.rewardPoint > widget.currentPoints && r.rewardPoint <= widget.projectedPoints)
        .toList();

    if (claimableNow.isEmpty && unlockingAfterPay.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (claimableNow.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.only(top: widget.compact ? 8 : 10),
            padding: EdgeInsets.all(widget.compact ? 10 : 12),
            decoration: BoxDecoration(
              color: appIsDarkMode ? const Color(0xFF292011) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, size: 15, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Eligible Rewards (${claimableNow.length}) — Ask patient if they want to claim:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: appIsDarkMode ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...claimableNow.map((reward) {
                  final isClaiming = _claimingRewardId == reward.rewardId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: appSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: appBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.rewardName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: appInkPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${reward.rewardPoint} pts${reward.remaining != null ? ' · ${reward.remaining} left' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: appInkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: _claimingRewardId != null ? null : () => _confirmAndClaim(reward),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: isClaiming
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Claim',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (unlockingAfterPay.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'After this payment (${widget.projectedPoints} pts), unlocks: ${unlockingAfterPay.map((r) => '${r.rewardName} (${r.rewardPoint} pts)').join(', ')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
