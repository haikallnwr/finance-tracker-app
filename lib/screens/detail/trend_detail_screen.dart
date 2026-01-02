// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';

class TrendDetailScreen extends StatelessWidget {
  const TrendDetailScreen({super.key});

  IconData _getAccountIcon(String accountName, String accountType) {
    final name = accountName.toLowerCase();
    final type = accountType.toLowerCase();

    if (name.contains("cash") || type.contains("cash")) {
      return Icons.money;
    } else if (name.contains("wallet") ||
        name.contains("dompet") ||
        type.contains("e-wallet")) {
      return Icons.account_balance_wallet;
    } else if (name.contains("bank") || type.contains("bank")) {
      return Icons.account_balance;
    } else {
      return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Balance Trend Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          double averageExpense = 0;

          if (provider.filterDays > 0) {
            final now = DateTime.now();
            final startDate = now.subtract(
              Duration(days: provider.filterDays - 1),
            );

            // Filter expense transaksi sesuai range hari
            final expenseTxs = provider.allTransactions.where((tx) {
              final txDate = tx.date.toLocal();
              return tx.type == 'Expense' &&
                  txDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  txDate.isBefore(now.add(const Duration(days: 1)));
            }).toList();

            double totalExpense = 0;
            for (var tx in expenseTxs) {
              totalExpense += tx.amount;
            }

            averageExpense = totalExpense / provider.filterDays;
          }

          // dropdown filter days logic
          final List<int> longTermOptions = [90, 180, 365]; // Removed -1
          bool isLongTermSelected = longTermOptions.contains(
            provider.filterDays,
          );

          String getLabel(int days) {
            if (days == 90) return "3 Months";
            if (days == 180) return "6 Months";
            if (days == 365) return "1 Year";
            return "";
          }

          String dropdownLabel = "More";
          if (isLongTermSelected) {
            dropdownLabel = getLabel(provider.filterDays);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Waktu
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("7 Day", 7, provider),
                      const SizedBox(width: 8),
                      _filterChip("30 Day", 30, provider),
                      const SizedBox(width: 8),

                      // DROPDOWN FILTER
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLongTermSelected
                              ? AppColors.accent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isLongTermSelected
                                ? AppColors.accent
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: isLongTermSelected
                                ? provider.filterDays
                                : null,
                            hint: Text(
                              dropdownLabel,
                              style: TextStyle(
                                color: isLongTermSelected
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: isLongTermSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isLongTermSelected
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                            isDense: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black),

                            // Builder untuk Tampilan Tombol saat TERTUTUP -> PUTIH
                            selectedItemBuilder: (BuildContext context) {
                              return longTermOptions.map<Widget>((int value) {
                                return Center(
                                  child: Text(
                                    getLabel(value),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList();
                            },

                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                provider.setFilterDays(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 90,
                                child: Text("3 Months"),
                              ),
                              DropdownMenuItem(
                                value: 180,
                                child: Text("6 Months"),
                              ),
                              DropdownMenuItem(
                                value: 365,
                                child: Text("1 Year"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (provider.filterDays > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Average Daily Expense",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(averageExpense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  height: 350,
                  padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _buildLineChart(provider),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Current Account Balances",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...provider.accounts.map((account) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getAccountIcon(account.name, ""),
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        account.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(account.currentBalance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, int days, HomeProvider provider) {
    bool isSelected = provider.filterDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) provider.setFilterDays(days);
      },
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildLineChart(HomeProvider provider) {
    if (provider.trendSpots.isEmpty ||
        provider.trendSpots.every((spot) => spot.y == 0)) {
      return const Center(child: Text("No data available"));
    }

    double rangeY = provider.maxTrendValue - provider.minTrendValue;
    if (rangeY == 0) rangeY = 10;

    double intervalY = rangeY / 5;
    double minY = provider.minTrendValue - (intervalY * 0.5);
    double maxY = provider.maxTrendValue + (intervalY * 0.5);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(color: Colors.black26, strokeWidth: 2);
            }
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval:
                  (provider.filterDays == -1 ? 30 : provider.filterDays) / 5,
              getTitlesWidget: (value, meta) {
                int totalDays = provider.filterDays == -1
                    ? 30
                    : provider.filterDays;
                int daysAgo = totalDays - value.toInt();
                DateTime date = DateTime.now().subtract(
                  Duration(days: daysAgo),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('d MMM').format(date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text(
                    "0",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }

                String text;
                if (value.abs() >= 1000000) {
                  text = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value.abs() >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(0)}k';
                } else {
                  text = value.toInt().toString();
                }
                return Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (provider.filterDays == -1 ? 30 : provider.filterDays).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: provider.trendSpots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final val = barSpot.y;
                final prefix = val > 0 ? "+" : "";
                final color = val >= 0 ? Colors.greenAccent : Colors.redAccent;
                final formatter = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                );

                return LineTooltipItem(
                  "$prefix${formatter.format(val)}",
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}
