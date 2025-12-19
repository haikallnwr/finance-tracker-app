import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expense Analysis',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          // Logic Top 5 Expense Categories
          final sortedEntries = provider.chartData.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Sort besar ke kecil
          final top5 = sortedEntries.take(5).toList();

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
                      _filterChip("7 Days", 7, provider),
                      const SizedBox(width: 8),
                      _filterChip("30 Days", 30, provider),
                      const SizedBox(width: 8),
                      _filterChip("All Time", -1, provider),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Chart Besar
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: _generateChartSections(provider.chartData),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "Top Expenses Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // List Top 5
                ...top5.map((entry) {
                  double total = provider.totalExpense;
                  double percentage = total == 0 ? 0 : (entry.value / total);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade100,
                          color: _getColor(entry.key),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${(percentage * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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
      showCheckmark: false,
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, double> data) {
    double total = data.values.fold(0, (sum, item) => sum + item);
    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _getColor(String category) {
    switch (category) {
      case "Food & Drink":
        return Colors.orange;
      case "Transport":
        return Colors.blue;
      case "Shopping":
        return Colors.pinkAccent;
      case "Bills":
        return Colors.redAccent;
      case "Entertainment":
        return Colors.purpleAccent;
      case "Health":
        return Colors.green;
      case "Salary":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
