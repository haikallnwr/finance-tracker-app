import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/home_provider.dart';
import '../../models/category_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC TAMBAH KATEGORI ---
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String type = _tabController.index == 0
        ? 'Expense'
        : 'Income'; // Default sesuai tab aktif
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name (e.g. Vacation, Investment)',
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Expense")),
                      selected: type == 'Expense',
                      onSelected: (val) {
                        if (val) setState(() => type = 'Expense');
                      },
                      selectedColor: AppColors.error,
                      labelStyle: TextStyle(
                        color: type == 'Expense' ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Income")),
                      selected: type == 'Income',
                      onSelected: (val) {
                        if (val) setState(() => type = 'Income');
                      },
                      selectedColor: AppColors.success,
                      labelStyle: TextStyle(
                        color: type == 'Income' ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
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
                      if (nameController.text.isEmpty) return;
                      setState(() => isLoading = true);

                      final provider = Provider.of<HomeProvider>(
                        context,
                        listen: false,
                      );
                      bool success = await provider.addCategory(
                        nameController.text,
                        type,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Category Added!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to add category"),
                            ),
                          );
                        }
                      }
                      setState(() => isLoading = false);
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(),
                    )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final expenseCategories = provider.categories
            .where((c) => c.type == 'Expense')
            .toList();
        final incomeCategories = provider.categories
            .where((c) => c.type == 'Income')
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Categories',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.accent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.accent,
              tabs: const [
                Tab(text: "Expense"),
                Tab(text: "Income"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories, Colors.redAccent),
              _buildCategoryList(incomeCategories, Colors.green),
            ],
          ),
          // FAB Khusus Halaman Kategori (Untuk tambah kategori)
          // FAB Global (Tambah Transaksi) tetap ada di Dashboard, tapi di halaman ini kita bisa override
          // atau tambahkan tombol secondary.
          // Sesuai request user "ada tombol buat kategori baru", kita taruh di AppBar actions atau FloatingActionButton
          // Karena di dashboard sudah ada FAB center docked, kita pakai tombol di AppBar saja supaya tidak bentrok layoutnya.
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCategoryDialog(context),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.playlist_add),
          ),
          // Agar tidak menutupi FAB global di dashboard, kita geser sedikit ke atas (optional)
          // Tapi karena CategoryScreen ada di dalam Tab Dashboard, scaffold ini jadi child.
          // Dashboard punya FAB sendiri. Hati-hati bentrok.
          // *SOLUSI:* Kita tidak pakai Scaffold di sini, atau kita pakai FAB yang posisinya 'endFloat' (pojok kanan)
          // sedangkan FAB Dashboard 'centerDocked'. Jadi aman.
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, Color iconColor) {
    if (categories.isEmpty) {
      return const Center(child: Text("No categories found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              // PAKAI HELPER DI SINI
              child: Icon(
                CategoryIconHelper.getIcon(cat.name),
                color: iconColor,
                size: 20,
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
