import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'POS System';
  static const String appVersion = '1.0.0';
  static const String companyName = 'POS Company';
  static const String companyAddress = '123 Business Street, City, Country';
  static const String companyPhone = '+1 234 567 890';
  static const String companyEmail = 'info@pos.com';

  // Supabase Configuration (Replace with actual values)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Tax Settings
  static const double defaultTaxRate = 0.0; // 0% default tax
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String receiptDateFormat = 'MMM dd, yyyy';
  static const String receiptTimeFormat = 'hh:mm a';

  // Image Placeholders
  static const String defaultProductImage =
      'https://via.placeholder.com/150?text=No+Image';
  static const String defaultAvatarImage =
      'https://via.placeholder.com/100?text=User';

  // Order Number Prefix
  static const String orderPrefix = 'ORD';

  // Receipt Settings
  static const double receiptWidth = 300.0;
  static const int receiptMaxItemNameLength = 20;
}

class AppColors {
  // Modern Palette (Indigo & Slate)
  // Primary - Vibrant Indigo
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryBg = Color(0xFFEEF2FF); // Indigo 50

  // Secondary - Soft Teal/Emerald
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color secondaryLight = Color(0xFF34D399); // Emerald 400
  static const Color secondaryDark = Color(0xFF059669); // Emerald 600
  static const Color secondaryBg = Color(0xFFECFDF5); // Emerald 50

  // Neutral / Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Sidebar
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color sidebarText = Color(0xFF334155); // Slate 700
  static const Color sidebarActiveItem = Color(0xFFEEF2FF); // Indigo 50
  static const Color sidebarActiveIcon = Color(0xFF4F46E5); // Indigo 600
  static const Color sidebarInactiveIcon = Color(0xFF94A3B8); // Slate 400
  static const Color sidebarInactiveText = Color(0xFF64748B); // Slate 500

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Order Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Category Colors
  static const Color categoryAll = Color(0xFF4F46E5);
  static const Color categoryCoffee = Color(0xFF8B5CF6); // Violet
  static const Color categoryTea = Color(0xFF10B981); // Emerald
  static const Color categoryPastries = Color(0xFFF59E0B); // Amber

  // Border Colors
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // Shadow Colors
  static const Color shadow = Color(0x0D000000); // Very subtle shadow

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Prices
  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );
}

class AppDimensions {
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Margin
  static const double marginSM = 8.0;

  // Radius
  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusRound = 999.0;

  // Icon Sizes
  static const double iconSM = 18.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Button sizes
  static const double buttonHeightLG = 56.0;

  // Layout
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 80.0;
  static const double orderPanelWidth = 380.0;

  // Card
  static const double cardElevation = 0;
}

class AppCategories {
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Coffee':
        return Icons.coffee;
      case 'Tea':
        return Icons.emoji_food_beverage;
      case 'Pastries':
        return Icons.cake;
      case 'Snacks':
        return Icons.lunch_dining;
      case 'All':
        return Icons.apps;
      default:
        return Icons.fastfood;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Coffee':
        return AppColors.categoryCoffee;
      case 'Tea':
        return AppColors.categoryTea;
      case 'Pastries':
        return AppColors.categoryPastries;
      case 'All':
        return AppColors.categoryAll;
      default:
        return AppColors.primary;
    }
  }
}

class AppShadows {
  static final BoxShadow cardShadow = BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.04),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static final BoxShadow elevatedShadow = BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 8),
  );

  static final List<BoxShadow> cardShadowList = [cardShadow];
  static final List<BoxShadow> elevatedShadowList = [elevatedShadow];
  static final List<BoxShadow> dialogShadow = elevatedShadowList;
}
