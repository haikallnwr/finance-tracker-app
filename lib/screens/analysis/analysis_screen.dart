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
        title: const Text(
          'Financial Analysis',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          // --- LOGIKA PERHITUNGAN ANALISIS (CLIENT SIDE) ---

          final now = DateTime.now();
          final currentMonthTxs = provider.allTransactions
              .where(
                (tx) => tx.date.month == now.month && tx.date.year == now.year,
              )
              .toList();

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

          // --- 1. MOOD KEUANGAN (Financial Sentiment) ---
          double cashflow = totalIncome - totalExpense;
          double savingRate = totalIncome > 0 ? (cashflow / totalIncome) : 0;

          Widget moodCard;
          // Placeholder Ilustrasi
          IconData moodIcon;
          String moodTitle;
          String moodMessage;
          Color moodColor;

          if (totalExpense > totalIncome) {
            // Defisit (Living beyond means)
            moodTitle = "Living on the Edge? 💸";
            moodMessage =
                "Uh-oh! Your expenses exceeded your income this month. It's time to review your budget and plug those spending leaks!";
            moodIcon = Icons.money_off_rounded;
            moodColor = AppColors.error;
          } else if (savingRate > 0.30) {
            // Excellent (>30% savings) - Financial Freedom path
            moodTitle = "Financial Rockstar! 🚀";
            moodMessage =
                "You're crushing it! Saving over 30% is impressive. Consider investing this surplus for your future goals.";
            moodIcon = Icons.rocket_launch_rounded;
            moodColor = Colors.purpleAccent;
          } else if (savingRate >= 0.20) {
            // Good (20-30% savings) - 50/30/20 Rule compliant
            moodTitle = "Healthy & Balanced 🌱";
            moodMessage =
                "Great job! You're saving a healthy amount (20%+). Keep building that emergency fund!";
            moodIcon = Icons.verified_user_outlined;
            moodColor = AppColors.success;
          } else if (savingRate > 0) {
            // Warning (0-20% savings) - Paycheck to paycheck risk
            moodTitle = "Cutting it Close ⚠️";
            moodMessage =
                "You're in the green, but barely. Try trimming some non-essential expenses to boost your savings buffer.";
            moodIcon = Icons.timelapse_rounded;
            moodColor = Colors.orange;
          } else {
            // Break Even (0% savings)
            moodTitle = "Just Getting By 😐";
            moodMessage =
                "You broke even this month. No savings means no safety net. Let's try to save at least 5% next month!";
            moodIcon = Icons.balance;
            moodColor = Colors.blueGrey;
          }

          moodCard = _buildIllustrationCard(
            title: moodTitle,
            message: moodMessage,
            icon: moodIcon,
            color: moodColor,
            isMain: true,
          );

          // --- 2. DETEKTIF KATEGORI (Top Spending) ---
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
            Color catColor = Colors.blueAccent;

            if (percentage > 50) {
              catMsg =
                  "Whoa! Over half your budget went to $topCat. Unless it's rent/bills, you might want to rethink this spending.";
              catColor = Colors.redAccent;
              catIcon = Icons.warning_rounded;
            }

            topCategoryCard = _buildIllustrationCard(
              title: "Top Spender: $topCat",
              message: catMsg,
              icon: catIcon,
              color: catColor,
            );
          }

          // --- 3. PERBANDINGAN TREN (vs Bulan Lalu) ---
          // ... (Logic tanggal tetap sama) ...
          final startLastMonth = DateTime(now.year, now.month - 1, 1);
          int lastDayOfLastMonth = DateTime(now.year, now.month, 0).day;
          int compareDay = now.day > lastDayOfLastMonth
              ? lastDayOfLastMonth
              : now.day;
          final limitLastMonth = DateTime(
            now.year,
            now.month - 1,
            compareDay,
            23,
            59,
            59,
          );

          final lastMonthTxs = provider.allTransactions
              .where(
                (tx) =>
                    tx.date.isAfter(
                      startLastMonth.subtract(const Duration(seconds: 1)),
                    ) &&
                    tx.date.isBefore(limitLastMonth),
              )
              .toList();

          double totalExpenseLastMonth = 0;
          for (var tx in lastMonthTxs) {
            if (tx.type == 'Expense') totalExpenseLastMonth += tx.amount;
          }

          Widget trendCard;
          if (totalExpenseLastMonth == 0) {
            trendCard = _buildIllustrationCard(
              title: "Not Enough Data",
              message:
                  "We need last month's data to compare your progress. Keep tracking!",
              icon: Icons.analytics_outlined,
              color: Colors.grey,
            );
          } else {
            double diff = totalExpense - totalExpenseLastMonth;
            double percentDiff = (diff / totalExpenseLastMonth) * 100;

            if (diff <= 0) {
              // LEBIH HEMAT
              trendCard = _buildIllustrationCard(
                title: "Thrifty Mode On! 📉",
                message:
                    "High five! 🙌 You spent ${percentDiff.abs().toStringAsFixed(1)}% less than this time last month. Your wallet thanks you!",
                icon: Icons.thumb_up_alt_rounded,
                color: Colors.teal,
              );
            } else {
              // LEBIH BOROS
              trendCard = _buildIllustrationCard(
                title: "Spending Alert! 📈",
                message:
                    "Careful! Your spending is up ${percentDiff.toStringAsFixed(1)}% vs last month. Watch out for impulse buys!",
                icon: Icons.trending_up,
                color: Colors.deepOrangeAccent,
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(now),
                  style: TextStyle(color: Colors.grey[600]),
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

  // --- WIDGET KARTU ILUSTRASI ---
  Widget _buildIllustrationCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    bool isMain = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isMain
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        children: [
          // AREA GAMBAR ILUSTRASI (Placeholder)
          Container(
            height: isMain ? 120 : 80,
            width: isMain ? 120 : 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            // Ganti icon ini dengan [Image of <Illustration Name>] nanti
            child: Icon(icon, size: isMain ? 60 : 40, color: color),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
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
