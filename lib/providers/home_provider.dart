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
  List<TransactionModel> _recentTransactions = []; // Top 5 untuk Home
  List<TransactionModel> _filteredTransactions =
      []; // Full list untuk Transaction Page
  List<FlSpot> _trendSpots = [];
  double _maxTrendValue = 100;

  // Filter State
  String? _selectedAccountId;
  int _filterDays = 30;
  DateTime? _selectedMonth; // Filter baru: Bulan Spesifik

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
  List<TransactionModel> get filteredTransactions =>
      _filteredTransactions; // Getter baru
  List<FlSpot> get trendSpots => _trendSpots;
  double get maxTrendValue => _maxTrendValue;
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
    _selectedMonth = null; // Reset filter bulan jika filter hari dipakai
    _recalculateData();
    notifyListeners();
  }

  void setFilterMonth(DateTime month) {
    _selectedMonth = month;
    _filterDays = -2; // Code khusus untuk menandakan mode "Bulan"
    _recalculateData();
    notifyListeners();
  }

  void _recalculateData() {
    _displayedBalance = 0;
    _displayedIncome = 0;
    _displayedExpense = 0;
    _chartData = {};
    _recentTransactions = [];
    _filteredTransactions = []; // Reset full list

    Map<int, double> dailyTotals = {};

    // 1. Balance Logic (Selalu real-time dari akun)
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
    DateTime? startDate;

    // Tentukan Range Filter
    if (_selectedMonth != null) {
      // Filter Bulan Spesifik
      // Tidak perlu startDate, logicnya nanti check bulan & tahun
    } else if (_filterDays != -1) {
      // Filter Hari (7 / 30 hari)
      startDate = now.subtract(Duration(days: _filterDays));
    }

    for (var tx in _allTransactions) {
      bool matchAccount =
          _selectedAccountId == null || tx.accountName == selectedAccountName;
      bool matchDate = true;

      if (_selectedMonth != null) {
        // Cek Bulan & Tahun
        matchDate =
            tx.date.month == _selectedMonth!.month &&
            tx.date.year == _selectedMonth!.year;
      } else if (startDate != null) {
        // Cek Hari kebelakang
        matchDate = tx.date.isAfter(startDate);
      }

      if (matchAccount && matchDate) {
        _filteredTransactions.add(tx); // Masukkan ke list filtered

        if (tx.type == 'Income') {
          _displayedIncome += tx.amount;
        } else {
          _displayedExpense += tx.amount;

          // Chart Pie Data
          if (_chartData.containsKey(tx.categoryName)) {
            _chartData[tx.categoryName] =
                _chartData[tx.categoryName]! + tx.amount;
          } else {
            _chartData[tx.categoryName] = tx.amount;
          }

          // Chart Line Data (Hanya jika mode filter hari, kalau mode bulan agak kompleks grafiknya jadi kita skip atau pakai logic tanggal)
          if (_selectedMonth == null) {
            int daysAgo = now.difference(tx.date).inDays;
            if (daysAgo >= 0 && (_filterDays == -1 || daysAgo <= _filterDays)) {
              dailyTotals[daysAgo] = (dailyTotals[daysAgo] ?? 0) + tx.amount;
            }
          }
        }
      }
    }

    _recentTransactions = _filteredTransactions.take(5).toList();

    // Generate Trend Spots (Hanya valid jika Filter Hari aktif)
    _trendSpots = [];
    _maxTrendValue = 100;
    if (_selectedMonth == null) {
      int range = (_filterDays == -1) ? 30 : _filterDays;
      if (_filterDays == -2) range = 30; // Fallback

      for (int i = range; i >= 0; i--) {
        double val = dailyTotals[i] ?? 0;
        if (val > _maxTrendValue) _maxTrendValue = val;
        _trendSpots.add(FlSpot((range - i).toDouble(), val));
      }
    }
  }

  // --- CRUD ACCOUNT ---
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

  // --- CRUD TRANSACTION & CATEGORY (Same as before) ---
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
}
