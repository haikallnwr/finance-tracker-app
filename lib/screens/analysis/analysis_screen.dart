// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Helper Format Rupiah
  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            'Monthly Analysis',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          // --- LOGIKA PERHITUNGAN ANALISIS (CLIENT SIDE) ---

          final now = DateTime.now();

          // 1. Filter Data Bulan Ini
          // Menggunakan toLocal() untuk memastikan zona waktu sesuai dengan 'now'
          final currentMonthTxs = provider.allTransactions.where((tx) {
            final txDate = tx.date.toLocal();
            return txDate.month == now.month && txDate.year == now.year;
          }).toList();

          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> categoryExpense = {};

          for (var tx in currentMonthTxs) {
            if (tx.type == 'Income') {
              totalIncome += tx.amount;
            } else {
              totalExpense += tx.amount;
              categoryExpense[tx.categoryName] =
                  (categoryExpense[tx.categoryName] ?? 0) + tx.amount;
            }
          }

          // Financial Mood Calculation
          double cashflow = totalIncome - totalExpense;
          double savingRate = totalIncome > 0 ? (cashflow / totalIncome) : 0;

          Widget moodCard;
          // Placeholder Ilustrasi
          IconData moodIcon;
          String moodTitle;
          String moodMessage;
          Color moodColor;

          if (totalExpense > totalIncome) {
            moodTitle = "Living on the Edge? 💸";
            moodMessage =
                "Uh-oh! Your expenses exceeded your income this month. It's time to review your budget and plug those spending leaks!";
            moodIcon = Icons.money_off_rounded;
            moodColor = const Color(0xFFB56A6A);
          } else if (savingRate > 0.30) {
            moodTitle = "Financial Rockstar!";
            moodMessage =
                "You're crushing it! Saving over 30% is impressive. Consider investing this surplus for your future goals.";
            moodIcon = Icons.rocket_launch_rounded;
            moodColor = const Color(0xFF5F8FA8);
          } else if (savingRate >= 0.20) {
            moodTitle = "Healthy & Balanced";
            moodMessage =
                "Great job! You're saving a healthy amount (20%+). Keep building that emergency fund!";
            moodIcon = Icons.verified_user_outlined;
            moodColor = const Color(0xFF6F9E87);
          } else if (savingRate > 0) {
            moodTitle = "Cutting it Close";
            moodMessage =
                "You're in the green, but barely. Try trimming some non-essential expenses to boost your savings buffer.";
            moodIcon = Icons.timelapse_rounded;
            moodColor = const Color(0xFFC2A15F);
          } else {
            moodTitle = "Just Getting By";
            moodMessage =
                "You broke even this month. No savings means no safety net. Let's try to save at least 5% next month!";
            moodIcon = Icons.balance;
            moodColor = const Color(0xFF7A8A99);
          }

          moodCard = _buildIllustrationCard(
            title: moodTitle,
            message: moodMessage,
            icon: moodIcon,
            color: moodColor,
            isMain: true,
          );

          //Top Category Expense
          Widget topCategoryCard = const SizedBox();
          if (categoryExpense.isNotEmpty) {
            var sortedKeys = categoryExpense.keys.toList(growable: false)
              ..sort(
                (k1, k2) =>
                    categoryExpense[k2]!.compareTo(categoryExpense[k1]!),
              );
            String topCat = sortedKeys.first;
            double topVal = categoryExpense[topCat]!;
            double percentage = totalExpense > 0
                ? (topVal / totalExpense) * 100
                : 0;

            String catMsg =
                "Heads up! $topCat took a big bite (${percentage.toStringAsFixed(0)}%) out of your wallet. Is this aligning with your priorities?";
            IconData catIcon = Icons.pie_chart;
            Color catColor = Color(0xFF6B8FA3);

            if (percentage > 50) {
              catMsg =
                  "Whoa! Over half your budget went to $topCat. Unless it's rent/bills, you might want to rethink this spending.";
              catColor = Color(0xFFB77A7A);
              catIcon = Icons.warning_rounded;
            }

            topCategoryCard = _buildIllustrationCard(
              title: "Top Spender: $topCat",
              message: catMsg,
              icon: catIcon,
              color: catColor,
            );
          }

          // Trend Analysis with Last Month Comparison

          // Tentukan bulan & tahun lalu
          final lastMonthDate = DateTime(now.year, now.month - 1);

          // Ambil semua transaksi bulan lalu
          final lastMonthTxs = provider.allTransactions.where((tx) {
            final txDate = tx.date.toLocal();
            return txDate.month == lastMonthDate.month &&
                txDate.year == lastMonthDate.year;
          }).toList();

          // Cek apakah ada expense bulan lalu
          final hasExpenseLastMonth = lastMonthTxs.any(
            (tx) => tx.type == 'Expense',
          );

          // Hitung total expense bulan lalu
          double totalExpenseLastMonth = 0;
          for (var tx in lastMonthTxs) {
            if (tx.type == 'Expense') {
              totalExpenseLastMonth += tx.amount;
            }
          }

          Widget trendCard;

          if (!hasExpenseLastMonth) {
            trendCard = _buildIllustrationCard(
              title: "Not Enough Data",
              message:
                  "We need last month's expense data to compare your progress. Keep tracking!",
              icon: Icons.analytics_outlined,
              color: Colors.grey,
            );
          } else {
            double diff = totalExpense - totalExpenseLastMonth;
            double percentDiff = (diff / totalExpenseLastMonth) * 100;

            if (diff <= 0) {
              // Lebih hemat
              trendCard = _buildIllustrationCard(
                title: "Thrifty Mode On!",
                message:
                    "Nice! You spent ${percentDiff.abs().toStringAsFixed(1)}% less than last month. Keep it up!",
                icon: Icons.thumb_up_alt_rounded,
                color: const Color(0xFF6F9E87),
              );
            } else {
              // Lebih boros
              trendCard = _buildIllustrationCard(
                title: "Spending Alert!",
                message:
                    "Careful! Your spending increased by ${percentDiff.toStringAsFixed(1)}% compared to last month.",
                icon: Icons.trending_up,
                color: const Color(0xFFC28A6B),
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMMM yyyy').format(now),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Mood Card
                moodCard,
                const SizedBox(height: 20),

                // 2. Top Category
                if (categoryExpense.isNotEmpty) ...[
                  topCategoryCard,
                  const SizedBox(height: 20),
                ],

                // 3. Trend Analysis
                trendCard,
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // widget card
  Widget _buildIllustrationCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    bool isMain = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // AREA GAMBAR ILUSTRASI (Placeholder)
          Container(
            height: isMain ? 120 : 80,
            width: isMain ? 120 : 80,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            // Ganti icon ini dengan [Image of <Illustration Name>] nanti
            child: Icon(icon, size: isMain ? 60 : 40, color: Colors.white),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: isMain ? 20 : 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
