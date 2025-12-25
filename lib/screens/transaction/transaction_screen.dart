import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Filter Tanggal Custom
  DateTimeRange? _selectedDateRange;

  // Function untuk memilih range tanggal
  void _pickDateRange(BuildContext context, HomeProvider provider) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      // Kita perlu custom filter di UI level atau update provider untuk support custom range
      // SEMENTARA: Kita filter manual list yang didapat dari provider di widget build
      // karena provider saat ini hanya support filterDays (int) atau selectedMonth (DateTime)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        List<dynamic> transactions = provider.filteredTransactions;

        // LOGIC FILTER TANGGAL MANUAL (SEARCH)
        if (_selectedDateRange != null) {
          transactions = transactions.where((tx) {
            // Normalisasi jam agar inklusif
            DateTime txDate = tx.date;
            DateTime start = _selectedDateRange!.start;
            DateTime end = _selectedDateRange!.end
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1));
            return txDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(end);
          }).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Transactions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => provider.fetchData(),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- SEARCH / FILTER BAR ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    // Search Box (Trigger Date Picker)
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDateRange(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDateRange == null
                                      ? "Search by Date..."
                                      : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                                  style: TextStyle(
                                    color: _selectedDateRange == null
                                        ? Colors.grey
                                        : AppColors.primary,
                                    fontWeight: _selectedDateRange == null
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_selectedDateRange != null)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDateRange = null; // Reset filter
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Quick Filter Dropdown (Pengganti All Time & Chips)
                    // Menggunakan logic provider filterDays
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ), // Adjust vertical padding for alignment
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: provider.filterDays,
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              provider.setFilterDays(newValue);
                              // Reset custom date range jika quick filter dipilih agar tidak bentrok
                              setState(() {
                                _selectedDateRange = null;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 7, child: Text("7 Days")),
                            DropdownMenuItem(value: 30, child: Text("30 Days")),
                            DropdownMenuItem(
                              value: 90,
                              child: Text("3 Months"),
                            ),
                            DropdownMenuItem(
                              value: 180,
                              child: Text("6 Months"),
                            ),
                            DropdownMenuItem(value: 365, child: Text("1 Year")),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- LIST TRANSAKSI ---
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No transactions found",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedDateRange != null)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selectedDateRange = null),
                                child: const Text("Clear Search"),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isIncome = tx.type == 'Income';
                          final categoryColor = CategoryIconHelper.getIconColor(
                            tx.categoryName,
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CategoryIconHelper.getIcon(tx.categoryName),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tx.categoryName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (tx.description.isNotEmpty)
                                    Text(
                                      tx.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(tx.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tx.accountName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
