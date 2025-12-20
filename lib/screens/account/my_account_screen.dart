import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';
import '../../models/account_model.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  // Helper Ikon (Sama seperti di TrendDetail)
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
    } else if (name.contains("bank") ||
        name.contains("bca") ||
        name.contains("mandiri") ||
        name.contains("bri")) {
      return Icons.account_balance;
    } else {
      return Icons.account_balance_wallet;
    }
  }

  void _showEditDialog(BuildContext context, AccountModel account) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = 'Cash';
    // Simple logic deteksi tipe awal
    if (account.name.toLowerCase().contains('bank'))
      selectedType = 'Bank';
    else if (account.name.toLowerCase().contains('wallet'))
      selectedType = 'E-wallet';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Account Name"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                'Cash',
                'Bank',
                'E-wallet',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => selectedType = v!,
              decoration: const InputDecoration(labelText: "Type"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await Provider.of<HomeProvider>(
                  context,
                  listen: false,
                ).updateAccount(account.id, nameController.text, selectedType);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Accounts"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.accounts.length,
            itemBuilder: (context, index) {
              final account = provider.accounts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      // MENGGUNAKAN HELPER IKON
                      child: Icon(
                        _getAccountIcon(account.name),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(account.currentBalance),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(context, account),
                    ),
                    if (!account.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Account?"),
                              content: const Text(
                                "This will delete all transactions associated with this account.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm) {
                            await provider.deleteAccount(account.id);
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
