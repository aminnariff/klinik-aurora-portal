import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PointsHistoryPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const PointsHistoryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final totalPoint = data['totalPoint'] ?? 0;
    final nextExpiry = data['nextExpiry'];
    final history = data['history'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("My Points")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [_buildSummaryCard(totalPoint, nextExpiry), const SizedBox(height: 20), _buildHistoryList(history)],
        ),
      ),
    );
  }

  // --- SUMMARY CARD ---
  Widget _buildSummaryCard(int totalPoint, dynamic nextExpiry) {
    final formatter = DateFormat('dd MMM yyyy');
    String expiryText = nextExpiry != null ? formatter.format(DateTime.parse(nextExpiry)) : "No upcoming expiries";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Total Points
            Text(
              "$totalPoint pts",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 6),
            const Text("Total Points", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),

            // Next Expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Next Expiry", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  expiryText,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HISTORY LIST ---
  Widget _buildHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return const Center(child: Text("No points history available."));
    }

    return Column(children: history.map((item) => _buildHistoryItem(item)).toList());
  }

  Widget _buildHistoryItem(dynamic item) {
    final formatter = DateFormat('dd MMM yyyy • hh:mm a');

    final isNegative = (item['points'] ?? 0) < 0;
    final isExpired = item['pointType'] == 5;

    final color = isExpired ? Colors.red : (isNegative ? Colors.orangeAccent : Colors.green);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${item['points']}",
                  style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatter.format(DateTime.parse(item['date'])),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(item['description'] ?? "", style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 10),

            // Breakdown if exists
            if (item['breakdown'] != null && (item['breakdown'] as List).isNotEmpty)
              _buildBreakdownList(item['breakdown']),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownList(List<dynamic> breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: breakdown.map((b) {
        final sourceLabel = _sourceTypeToLabel(b['source_point_type']);
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right, size: 16),
              const SizedBox(width: 6),
              Text("$sourceLabel: ${b['used_point']} pts"),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _sourceTypeToLabel(int type) {
    switch (type) {
      case 1:
        return "Referral";
      case 2:
        return "Voucher";
      case 3:
        return "Reward";
      case 4:
        return "Spending";
      case 5:
        return "Expired";
      default:
        return "Unknown";
    }
  }
}
