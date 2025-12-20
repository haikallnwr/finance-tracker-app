import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
// Import Halaman Detail Baru
import '../detail/expense_detail_screen.dart';
import '../detail/trend_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IconData _getAccountIcon(String accountName) {
    final name = accountName.toLowerCase();
    if (name.contains("cash")) {
      return Icons.money;
    } else if (name.contains("wallet") ||
        name.contains("dompet") ||
        name.contains("dana") ||
        name.contains("ovo") ||
        name.contains("gopay")) {
      return Icons.account_balance_wallet;
    } else if (name.contains("all accounts")) {
      return Icons.select_all_rounded;
    } else if (name.contains("bank") ||
        name.contains("bca") ||
        name.contains("mandiri") ||
        name.contains("bri")) {
      return Icons.account_balance;
    } else {
      return Icons.account_balance_wallet;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<HomeProvider>(context, listen: false).fetchData(),
    );
  }

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'Cash';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['Cash', 'Bank', 'E-wallet'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Initial Balance'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final provider = Provider.of<HomeProvider>(
                        context,
                        listen: false,
                      );
                      double? balance = double.tryParse(balanceController.text);
                      if (nameController.text.isNotEmpty && balance != null) {
                        await provider.addAccount(
                          nameController.text,
                          selectedType,
                          balance,
                        );
                        Navigator.pop(context);
                      }
                      setState(() => isLoading = false);
                    },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToExpenseDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseDetailScreen()),
    );
  }

  void _navigateToTrendDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrendDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<AuthProvider>(context).username ?? 'User';

    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, username),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBalanceCard(context, provider),
                              const SizedBox(height: 20),

                              // Filter Section (Updated Style)
                              _buildFilterSection(provider),
                              const SizedBox(height: 20),

                              const Text(
                                "Balance Trend",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildLineChart(context, provider),

                              const SizedBox(height: 24),
                              const Text(
                                "Expenses Structure",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildPieChartSection(context, provider),

                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Recent Transactions",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildRecentTransactions(provider),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, HomeProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: provider.selectedAccountId,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: Colors.white,
                    selectedItemBuilder: (BuildContext context) {
                      final List<String?> allIds = [
                        null,
                        ...provider.accounts.map((e) => e.id),
                      ];
                      return allIds.map<Widget>((String? id) {
                        String text = 'All Accounts';
                        IconData icon = Icons.select_all_rounded;

                        if (id != null) {
                          try {
                            final acc = provider.accounts.firstWhere(
                              (e) => e.id == id,
                            );
                            text = acc.name;
                            icon = _getAccountIcon(text);
                          } catch (_) {}
                        }

                        return Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    onChanged: (String? newValue) =>
                        provider.selectAccount(newValue),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.select_all_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text("All Accounts"),
                          ],
                        ),
                      ),
                      ...provider.accounts
                          .map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id,
                              child: Row(
                                children: [
                                  Icon(
                                    _getAccountIcon(account.name),
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(account.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showAddAccountDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            formatRupiah(provider.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildIncomeExpenseLabel(
                Icons.arrow_downward,
                'Income',
                formatRupiah(provider.totalIncome),
              ),
              const SizedBox(width: 24),
              _buildIncomeExpenseLabel(
                Icons.arrow_upward,
                'Expense',
                formatRupiah(provider.totalExpense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseLabel(IconData icon, String label, String amount) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12)
      greeting = 'Good Morning,';
    else if (hour < 18)
      greeting = 'Good Afternoon,';
    else
      greeting = 'Good Evening,';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                username,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  // --- UPDATED FILTER SECTION ---
  Widget _buildFilterSection(HomeProvider provider) {
    // List opsi jangka panjang (tanpa All Time)
    final List<int> longTermOptions = [90, 180, 365];

    // Cek apakah filter saat ini adalah salah satu opsi jangka panjang
    bool isLongTermSelected = longTermOptions.contains(provider.filterDays);

    // Helper untuk label
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
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip("7 Days", 7, provider),
          const SizedBox(width: 10),
          _filterChip("30 Days", 30, provider),
          const SizedBox(width: 10),

          // DROPDOWN FILTER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isLongTermSelected ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLongTermSelected
                    ? AppColors.accent
                    : Colors.grey.shade200,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: isLongTermSelected ? provider.filterDays : null,
                hint: Text(
                  dropdownLabel,
                  style: TextStyle(
                    color: isLongTermSelected ? Colors.white : Colors.black,
                    fontWeight: isLongTermSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isLongTermSelected ? Colors.white : Colors.black54,
                ),
                isDense: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),

                // Builder untuk tampilan tombol saat tertutup -> PUTIH jika aktif
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
                  DropdownMenuItem(value: 90, child: Text("3 Months")),
                  DropdownMenuItem(value: 180, child: Text("6 Months")),
                  DropdownMenuItem(value: 365, child: Text("1 Year")),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildRecentTransactions(HomeProvider provider) {
    if (provider.recentTransactions.isEmpty) {
      return const Center(child: Text("No recent transactions"));
    }
    return Column(
      children: provider.recentTransactions.map((tx) {
        bool isIncome = tx.type == 'Income';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CategoryIconHelper.getIcon(tx.categoryName),
                  color: isIncome ? AppColors.success : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(tx.date),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'} ${formatRupiah(tx.amount)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.success : AppColors.error,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(BuildContext context, HomeProvider provider) {
    if (provider.trendSpots.isEmpty ||
        provider.trendSpots.every((spot) => spot.y == 0)) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "No transaction data for this period",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    double rangeY = provider.maxTrendValue - provider.minTrendValue;
    if (rangeY == 0) rangeY = 10;
    double intervalY = rangeY / 4;
    double minY = provider.minTrendValue - (intervalY * 0.5);
    double maxY = provider.maxTrendValue + (intervalY * 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: intervalY,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0)
                      return FlLine(color: Colors.black26, strokeWidth: 2);
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval:
                          (provider.filterDays == -1
                              ? 30
                              : provider.filterDays) /
                          5,
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
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
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
                        if (value == 0)
                          return const Text(
                            "0",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        String text;
                        if (value.abs() >= 1000000)
                          text = '${(value / 1000000).toStringAsFixed(1)}M';
                        else if (value.abs() >= 1000)
                          text = '${(value / 1000).toStringAsFixed(0)}k';
                        else
                          text = value.toInt().toString();
                        return Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (provider.filterDays == -1 ? 30 : provider.filterDays)
                    .toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.trendSpots,
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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
                        final color = val >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent;
                        return LineTooltipItem(
                          "$prefix${formatRupiah(val)}",
                          TextStyle(color: color, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _navigateToTrendDetail(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Show Detail",
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(BuildContext context, HomeProvider provider) {
    if (provider.chartData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "0% Pengeluaran",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _generateChartSections(provider.chartData),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: provider.chartData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      formatRupiah(entry.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _navigateToExpenseDetail(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Show Detail",
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
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
