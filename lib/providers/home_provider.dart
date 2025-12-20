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
  int _filterDays =
      30; // 7, 30, 90 (3 bulan), 180 (6 bulan), 365 (1 tahun), -1 (All Time)
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
        // Sort descending (terbaru di atas)
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

    // Map untuk menyimpan CASHFLOW harian (Income - Expense)
    Map<DateTime, double> dailyCashflowMap = {};

    // 1. Hitung Saldo Total (Real-time dari akun)
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

    DateTime now = DateTime.now();
    DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Normalisasi hari ini (jam 00:00)

    // Tentukan range filter (Start Date)
    DateTime? startDate;
    if (_filterDays != -1 && _selectedMonth == null) {
      // Jika filter 7 hari, kita mau H-6 sampai H-0 (total 7 hari)
      startDate = today.subtract(Duration(days: _filterDays - 1));
    }

    // 2. Loop Semua Transaksi
    for (var tx in _allTransactions) {
      bool matchAccount =
          _selectedAccountId == null || tx.accountName == selectedAccountName;
      DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      bool matchDate = true;
      if (_selectedMonth != null) {
        matchDate =
            tx.date.month == _selectedMonth!.month &&
            tx.date.year == _selectedMonth!.year;
      } else if (startDate != null) {
        matchDate = !txDate.isBefore(startDate);
      }

      if (matchAccount && matchDate) {
        _filteredTransactions.add(tx);

        double amount = tx.amount;

        // --- LOGIC BARU: HITUNG CASHFLOW ---
        // Jika Income: Tambah (+), Jika Expense: Kurang (-)
        double cashflowValue = (tx.type == 'Income') ? amount : -amount;

        if (tx.type == 'Income') {
          _displayedIncome += amount;
        } else {
          _displayedExpense += amount;
          // Pie Chart hanya untuk Expense
          if (_chartData.containsKey(tx.categoryName)) {
            _chartData[tx.categoryName] = _chartData[tx.categoryName]! + amount;
          } else {
            _chartData[tx.categoryName] = amount;
          }
        }

        // Simpan ke Map Cashflow
        if (_selectedMonth == null) {
          if (dailyCashflowMap.containsKey(txDate)) {
            dailyCashflowMap[txDate] =
                dailyCashflowMap[txDate]! + cashflowValue;
          } else {
            dailyCashflowMap[txDate] = cashflowValue;
          }
        }
      }
    }

    _recentTransactions = _filteredTransactions.take(5).toList();

    // 3. Generate Spot Grafik (Net Cashflow)
    _trendSpots = [];
    _maxTrendValue = 10;
    _minTrendValue = 0;

    if (_selectedMonth == null) {
      int range = (_filterDays == -1) ? 30 : _filterDays;
      if (_filterDays == -2) range = 30;

      // Loop mundur dari range-1 sampai 0
      for (int i = range - 1; i >= 0; i--) {
        DateTime checkDate = today.subtract(Duration(days: i));

        // Ambil nilai cashflow (bisa positif atau negatif)
        double val = dailyCashflowMap[checkDate] ?? 0;

        // Update Max/Min untuk skala grafik
        if (val > _maxTrendValue) _maxTrendValue = val;
        if (val < _minTrendValue) _minTrendValue = val;

        // X-Axis
        double xPos = (range - 1 - i).toDouble();
        _trendSpots.add(FlSpot(xPos, val));
      }
    }
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
        body: jsonEncode({
          'name': name,
          'type': type,
          'user_id': prefs.getString('userId'), // Asumsi ID user dibutuhkan
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
}
