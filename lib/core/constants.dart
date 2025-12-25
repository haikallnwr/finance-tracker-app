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

  static Color getIconColor(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('food')) return const Color(0xFF9B7B5E);

    if (name.contains('transport')) return const Color(0xFF4F6B88);

    if (name.contains('shop')) return const Color(0xFF8A5F6D);

    if (name.contains('bill')) return const Color(0xFF6A6A6A);

    if (name.contains('entertain'))
      return const Color(0xFF6A66A3); // soft indigo

    if (name.contains('health')) return const Color(0xFF5F8A75); // calm green

    if (name.contains('salary')) return const Color(0xFF4F8F8B); // teal lembut

    if (name.contains('bonus')) return const Color(0xFF8A6A5A); // clay brown

    if (name.contains('gift'))
      return const Color(0xFF8A5F78); // muted pink-purple

    if (name.contains('freelance'))
      return const Color(0xFF6F8F5F); // olive soft

    return AppColors.primary;
  }
}
