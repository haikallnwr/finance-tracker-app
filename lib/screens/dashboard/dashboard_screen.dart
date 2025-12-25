import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';
import '../home/home_screen.dart';
import '../analysis/analysis_screen.dart'; // Screen Baru
import '../category/category_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const AnalysisScreen(),
    const CategoryScreen(),
    const ProfileScreen(),
  ];

  void _showAddTransactionDialog(BuildContext context) {
    // ... (Logic Add Transaction SAMA SEPERTI SEBELUMNYA, Copy Paste Saja) ...
    // START COPY
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'Expense';
    String? selectedAccountId;
    String? selectedCategoryId;
    bool isLoading = false;
    final provider = Provider.of<HomeProvider>(context, listen: false);
    if (provider.accounts.isNotEmpty) {
      selectedAccountId = provider.accounts.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final filteredCategories = provider.categories
              .where((cat) => cat.type == type)
              .toList();

          return AlertDialog(
            title: const Text('New Transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Expense")),
                          selected: type == 'Expense',
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                type = 'Expense';
                                selectedCategoryId = null;
                              });
                            }
                          },
                          selectedColor: AppColors.error,
                          labelStyle: TextStyle(
                            color: type == 'Expense'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Income")),
                          selected: type == 'Income',
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                type = 'Income';
                                selectedCategoryId = null;
                              });
                            }
                          },
                          selectedColor: AppColors.success,
                          labelStyle: TextStyle(
                            color: type == 'Income'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.accounts.map((acc) {
                      return DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedAccountId = val),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Select Category"),
                    items: filteredCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => selectedCategoryId = val),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
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
                        if (selectedAccountId == null ||
                            selectedCategoryId == null ||
                            amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all fields"),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        double? amount = double.tryParse(amountController.text);
                        if (amount != null) {
                          bool success = await provider.addTransaction(
                            accountId: selectedAccountId!,
                            categoryId: selectedCategoryId!,
                            type: type,
                            amount: amount,
                            description: descriptionController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Transaction Added!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to add transaction"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                        setState(() => isLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Add Transaction"),
              ),
            ],
          );
        },
      ),
    );
    // END COPY
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_card_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: const FixedCenterDockedLocation(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              // Ikon Chart Pie untuk Analysis
              icon: FaIcon(FontAwesomeIcons.chartPie, size: 20),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              label: 'Category',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class FixedCenterDockedLocation extends FloatingActionButtonLocation {
  const FixedCenterDockedLocation();
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;
    final double fabY =
        scaffoldGeometry.contentBottom -
        (scaffoldGeometry.floatingActionButtonSize.height / 2.0);
    return Offset(fabX, fabY);
  }
}
