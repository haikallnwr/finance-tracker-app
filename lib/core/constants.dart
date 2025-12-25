import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Pastikan sudah diinstall

class AppColors {
  static const Color primary = Color(0xFF2A2D3E);
  static const Color accent = Color(0xFF1C4D8D);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color error = Color.fromARGB(255, 161, 44, 44);
  static const Color success = Color.fromARGB(255, 24, 120, 29);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF9CA3AF);
}

class ApiConstants {
  static const String baseUrl = "http://10.0.2.2:3000/api";
}

// icon
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
      return Icons.movie_rounded;
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
    if (name.contains('food')) return Color(0xFF7A5C3E);
    if (name.contains('transport')) return Color(0xFF2F4A66);
    if (name.contains('shop')) return Color(0xFF5A3F4D);
    if (name.contains('bill')) return Color(0xFF3A3A3A);
    if (name.contains('entertain')) return Color(0xFF3E3A5C);
    if (name.contains('health')) return Color(0xFF3E5C4A);
    if (name.contains('salary')) return Color(0xFF2F5C5A);
    if (name.contains('bonus')) return Color(0xFF5C4A3E);
    if (name.contains('gift')) return Color(0xFF5C3E4A);
    if (name.contains('freelance')) return Color(0xFF4A5C3E);
    return AppColors.primary;
  }
}
