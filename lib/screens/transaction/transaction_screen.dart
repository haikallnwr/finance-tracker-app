import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart'; // Import Constants untuk CategoryIconHelper
import '../../providers/home_provider.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Month Picker Dialog
  void _showMonthPicker(BuildContext context, HomeProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText:
          "SELECT MONTH (Pick any day)", // Flutter date picker default pilih hari
    );
    if (picked != null) {
      provider.setFilterMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // Menggunakan filteredTransactions agar menampilkan SEMUA data (bukan cuma 5)
        final transactions = provider.filteredTransactions;

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
              // Tombol Reset Filter ke "All Time" jika sedang mode Bulan
              if (provider.selectedMonth != null)
                TextButton(
                  onPressed: () => provider.setFilterDays(-1), // Reset
                  child: const Text("Show All"),
                ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                ),
                onPressed: () => _showMonthPicker(context, provider),
              ),
              IconButton(
                onPressed: () => provider.fetchData(),
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. REKAPAN PERBULAN (SUMMARY CARD) - Hanya muncul jika filter bulan aktif
              if (provider.selectedMonth != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Recap: ${DateFormat('MMMM yyyy').format(provider.selectedMonth!)}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                "Income",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(provider.totalIncome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.white24,
                          ),
                          Column(
                            children: [
                              const Text(
                                "Expense",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(provider.totalExpense),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Net: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(provider.totalIncome - provider.totalExpense)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Filter Chips Biasa
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  child: SingleChildScrollView(
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
                ),

              // 2. LIST TRANSAKSI LENGKAP
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "No transactions found",
                              style: TextStyle(color: Colors.grey),
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align top biar rapi kalau deskripsi panjang
                                children: [
                                  // ICON DINAMIS DARI HELPER
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isIncome
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CategoryIconHelper.getIcon(
                                        tx.categoryName,
                                      ), // <--- PAKAI HELPER
                                      color: isIncome
                                          ? AppColors.success
                                          : AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // INFO TEXT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nama Kategori
                                        Text(
                                          tx.categoryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        // Deskripsi (Muncul jika ada)
                                        if (tx.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4.0,
                                            ),
                                            child: Text(
                                              tx.description,
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                        // Akun & Tanggal
                                        Text(
                                          "${tx.accountName} • ${DateFormat('dd MMM yyyy, HH:mm').format(tx.date)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // AMOUNT
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

  Widget _filterChip(String label, int days, HomeProvider provider) {
    bool isSelected =
        provider.filterDays == days && provider.selectedMonth == null;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) provider.setFilterDays(days);
      },
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
