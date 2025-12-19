import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Pastikan sudah diinstall

class AppColors {
  static const Color primary = Color(0xFF2A2D3E);
  static const Color accent = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF9CA3AF);
}

class ApiConstants {
  // Ganti IP sesuai environment (10.0.2.2 untuk Emulator Android)
  static const String baseUrl = "http://10.0.2.2:3000/api";
}

// --- HELPER UNTUK IKON KONSISTEN ---
class CategoryIconHelper {
  static IconData getIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    // Logic pemetaan nama ke Ikon
    if (name.contains('food') || name.contains('makan')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('drink') || name.contains('minum')) {
      return Icons.local_cafe_rounded;
    }
    if (name.contains('transport') ||
        name.contains('ojek') ||
        name.contains('bensin')) {
      return FontAwesomeIcons.car;
    }
    if (name.contains('shop') ||
        name.contains('belanja') ||
        name.contains('groceries')) {
      return FontAwesomeIcons.bagShopping;
    }
    if (name.contains('bill') ||
        name.contains('tagihan') ||
        name.contains('listrik')) {
      return FontAwesomeIcons.fileInvoiceDollar;
    }
    if (name.contains('entertain') ||
        name.contains('nonton') ||
        name.contains('game')) {
      return FontAwesomeIcons.gamepad;
    }
    if (name.contains('health') ||
        name.contains('obat') ||
        name.contains('dokter')) {
      return FontAwesomeIcons.heartPulse;
    }
    if (name.contains('salary') || name.contains('gaji')) {
      return FontAwesomeIcons.moneyBillWave;
    }
    if (name.contains('bonus') || name.contains('thr')) {
      return FontAwesomeIcons.coins;
    }
    if (name.contains('gift') || name.contains('hadiah')) {
      return FontAwesomeIcons.gift;
    }
    if (name.contains('invest')) return FontAwesomeIcons.chartLine;
    if (name.contains('education') || name.contains('sekolah')) {
      return FontAwesomeIcons.graduationCap;
    }

    // Default Icon
    return Icons.category_rounded;
  }

  // Helper untuk warna background ikon (Opsional, biar lebih cantik)
  static Color getIconColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food')) return Colors.orange;
    if (name.contains('transport')) return Colors.blue;
    if (name.contains('shop')) return Colors.pink;
    if (name.contains('bill')) return Colors.red;
    if (name.contains('entertain')) return Colors.purple;
    if (name.contains('health')) return Colors.green;
    if (name.contains('salary')) return Colors.teal;
    return Colors.grey;
  }
}
