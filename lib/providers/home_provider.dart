import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class HomeProvider with ChangeNotifier {
  bool _isLoading = true;

  // Data Summary
  double _displayedBalance = 0;
  double _displayedIncome = 0;
  double _displayedExpense = 0;

  // Data Lists
  List<TransactionModel> _allTransactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  Map<String, double> _chartData = {};

  // Processed Data
  List<TransactionModel> _recentTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<FlSpot> _trendSpots = [];
  double _maxTrendValue = 100;
  double _minTrendValue = 0;

  // Filter State
  String? _selectedAccountId;
  int _filterDays = 30; // 7, 30, 90, 180, 365, -1
  DateTime? _selectedMonth; // Filter Bulan Spesifik

  // Getters
  bool get isLoading => _isLoading;
  double get totalBalance => _displayedBalance;
  double get totalIncome => _displayedIncome;
  double get totalExpense => _displayedExpense;
  Map<String, double> get chartData => _chartData;
  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  String? get selectedAccountId => _selectedAccountId;

  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  List<TransactionModel> get allTransactions => _allTransactions;
  List<FlSpot> get trendSpots => _trendSpots;
  double get maxTrendValue => _maxTrendValue;
  double get minTrendValue => _minTrendValue;
  int get filterDays => _filterDays;
  DateTime? get selectedMonth => _selectedMonth;

  String get selectedAccountName {
    if (_selectedAccountId == null) return "All Accounts";
    try {
      return _accounts.firstWhere((acc) => acc.id == _selectedAccountId).name;
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Accounts
      final accountRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/account'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (accountRes.statusCode == 200) {
        List<dynamic> accJson = jsonDecode(accountRes.body);
        _accounts = accJson.map((json) => AccountModel.fromJson(json)).toList();
      }

      // 2. Fetch Transactions
      final transRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (transRes.statusCode == 200) {
        List<dynamic> transJson = jsonDecode(transRes.body);
        _allTransactions = transJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        // PENTING: Sort descending (terbaru di atas) untuk memudahkan perhitungan mundur
        _allTransactions.sort((a, b) => b.date.compareTo(a.date));
      }

      // 3. Fetch Categories
      final catRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/category'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (catRes.statusCode == 200) {
        List<dynamic> catJson = jsonDecode(catRes.body);
        _categories = catJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      }

      _recalculateData();
    } catch (e) {
      print("Error fetching data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- FILTER ACTIONS ---
  void selectAccount(String? accountId) {
    _selectedAccountId = accountId;
    _recalculateData();
    notifyListeners();
  }

  void setFilterDays(int days) {
    _filterDays = days;
    _selectedMonth = null;
    _recalculateData();
    notifyListeners();
  }

  void setFilterMonth(DateTime month) {
    _selectedMonth = month;
    _filterDays = -2; // Kode khusus mode bulan
    _recalculateData();
    notifyListeners();
  }

  void _recalculateData() {
    _displayedBalance = 0;
    _displayedIncome = 0;
    _displayedExpense = 0;
    _chartData = {};
    _recentTransactions = [];
    _filteredTransactions = [];

    // 1. Hitung Saldo Total Saat Ini (Real-time dari akun)
    // Ini akan menjadi titik awal (hari ini) untuk perhitungan mundur grafik
    if (_selectedAccountId == null) {
      _displayedBalance = _accounts.fold(
        0,
        (sum, item) => sum + item.currentBalance,
      );
    } else {
      if (_accounts.isNotEmpty) {
        final selectedAccount = _accounts.firstWhere(
          (acc) => acc.id == _selectedAccountId,
          orElse: () => _accounts[0],
        );
        _displayedBalance = selectedAccount.currentBalance;
      }
    }

    // --- SETUP FILTER & HITUNG SUMMARY DATA ---
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime? startDate;
    if (_filterDays != -1 && _selectedMonth == null) {
      startDate = today.subtract(Duration(days: _filterDays - 1));
    }

    // List transaksi khusus untuk perhitungan grafik (hanya akun terpilih)
    List<TransactionModel> accountSpecificTransactions = [];

    for (var tx in _allTransactions) {
      bool matchAccount =
          _selectedAccountId == null || tx.accountName == selectedAccountName;

      if (matchAccount) {
        // Simpan untuk perhitungan grafik nanti
        accountSpecificTransactions.add(tx);

        // --- Filter Tanggal untuk Summary Income/Expense & List Transaksi ---
        DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        bool matchDate = true;

        if (_selectedMonth != null) {
          matchDate =
              tx.date.month == _selectedMonth!.month &&
              tx.date.year == _selectedMonth!.year;
        } else if (startDate != null) {
          matchDate = !txDate.isBefore(startDate);
        }

        if (matchDate) {
          _filteredTransactions.add(tx);

          if (tx.type == 'Income') {
            _displayedIncome += tx.amount;
          } else {
            _displayedExpense += tx.amount;
            // Pie Chart Data (Hanya Expense)
            if (_chartData.containsKey(tx.categoryName)) {
              _chartData[tx.categoryName] =
                  _chartData[tx.categoryName]! + tx.amount;
            } else {
              _chartData[tx.categoryName] = tx.amount;
            }
          }
        }
      }
    }

    _recentTransactions = _filteredTransactions.take(5).toList();

    // --- 3. GENERATE BALANCE TREND (LOGIKA MUNDUR) ---
    // Kita mulai dari _displayedBalance (Saldo Hari Ini) dan mundur ke belakang.
    // Rumus Mundur: Saldo Kemarin = Saldo Hari Ini - Income Hari Ini + Expense Hari Ini

    _trendSpots = [];
    double runningBalance = _displayedBalance;

    // Inisialisasi Min/Max dengan saldo saat ini
    double tempMin = runningBalance;
    double tempMax = runningBalance;

    if (_selectedMonth == null) {
      int range = (_filterDays == -1)
          ? 30
          : _filterDays; // Default 30 jika All Time untuk grafik
      if (_filterDays == -2) range = 30;

      int txIndex = 0; // Pointer untuk list transaksi (sudah sort desc/terbaru)

      // Loop dari Hari Ini (0) mundur ke masa lalu (range-1)
      for (int i = 0; i < range; i++) {
        // Tanggal yang sedang dicek
        DateTime targetDate = today.subtract(Duration(days: i));

        // Simpan titik grafik untuk hari ini (Saldo Akhir Hari tersebut)
        // X = range - 1 - i.
        // i=0 (Hari ini) -> X paling kanan.
        // i=range-1 (Hari terlama) -> X paling kiri (0).
        double xPos = (range - 1 - i).toDouble();
        _trendSpots.add(FlSpot(xPos, runningBalance));

        // Update Min/Max
        if (runningBalance > tempMax) tempMax = runningBalance;
        if (runningBalance < tempMin) tempMin = runningBalance;

        // Proses transaksi pada tanggal targetDate untuk mengembalikan saldo ke awal hari (atau akhir hari kemarin)
        // Karena list transaksi urut dari Baru ke Lama, kita tinggal cek index selanjutnya
        while (txIndex < accountSpecificTransactions.length) {
          TransactionModel tx = accountSpecificTransactions[txIndex];
          DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

          // Jika transaksi lebih baru dari targetDate (masa depan), skip (seharusnya tidak terjadi jika logic benar)
          if (txDate.isAfter(targetDate)) {
            txIndex++;
            continue;
          }

          // Jika transaksi terjadi pada targetDate, kita "batalkan" efeknya untuk mendapatkan saldo sebelum transaksi
          if (txDate.isAtSameMomentAs(targetDate)) {
            if (tx.type == 'Income') {
              runningBalance -= tx.amount; // Kurangi Income untuk mundur
            } else {
              runningBalance += tx.amount; // Tambah Expense untuk mundur
            }
            txIndex++;
          } else {
            // Transaksi lebih tua dari targetDate, berhenti loop transaksi hari ini
            break;
          }
        }
      }

      // Karena kita add dari kanan ke kiri (terbaru ke terlama), kita perlu reverse urutannya untuk FlChart?
      // Tidak perlu reverse listnya karena kita sudah hitung xPos dengan benar:
      // i=0 (Hari ini), xPos=Max -> Add pertama.
      // i=Max (Lama), xPos=0 -> Add terakhir.
      // FlChart biasanya pintar mengurutkan, tapi untuk amannya kita sort spots berdasarkan X.
      _trendSpots.sort((a, b) => a.x.compareTo(b.x));
    }

    _maxTrendValue = tempMax;
    _minTrendValue = tempMin;
  }

  // --- CRUD FUNCTIONS (Sama) ---
  Future<bool> addAccount(String name, String type, double initBalance) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConstants.baseUrl}/account');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'type': type,
          'init_balance': initBalance,
        }),
      );
      if (response.statusCode == 201) {
        await fetchData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAccount(String id, String name, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConstants.baseUrl}/account/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'type': type}),
      );
      if (response.statusCode == 201) {
        await fetchData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConstants.baseUrl}/account/$id');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await fetchData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addTransaction({
    required String accountId,
    required String categoryId,
    required String type,
    required double amount,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'account_id': accountId,
          'category_id': categoryId,
          'type': type,
          'amount': amount,
          'description': description,
          'date': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 201) {
        await fetchData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCategory(String name, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'type': type}),
      );
      if (response.statusCode == 201) {
        await fetchData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConstants.baseUrl}/category/$categoryId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchData(); // Refresh list kategori
        return true;
      }
      return false;
    } catch (e) {
      print("Delete Category Error: $e");
      return false;
    }
  }
}
