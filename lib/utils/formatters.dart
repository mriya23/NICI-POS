import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  // Currency Formatters
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormatter =
      NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 2);

  static final NumberFormat _numberFormatter = NumberFormat('#,##0.00');

  static final NumberFormat _integerFormatter = NumberFormat('#,##0');

  // Date Formatters
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _receiptDateFormatter = DateFormat('MMM dd, yyyy');
  static final DateFormat _receiptTimeFormatter = DateFormat('hh:mm a');
  static final DateFormat _fullDateFormatter = DateFormat(
    'EEEE, MMMM dd, yyyy',
  );
  static final DateFormat _shortDateFormatter = DateFormat('MMM dd');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _dayFormatter = DateFormat('EEE');
  static final DateFormat _isoFormatter = DateFormat('yyyy-MM-dd');

  // Currency formatting methods
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatCompactCurrency(double amount) {
    return _compactCurrencyFormatter.format(amount);
  }

  static String formatNumber(double number) {
    return _numberFormatter.format(number);
  }

  static String formatInteger(int number) {
    return _integerFormatter.format(number);
  }

  static String formatPrice(double price) {
    if (price < 0) {
      return '-\$${_numberFormatter.format(price.abs())}';
    }
    return '\$${_numberFormatter.format(price)}';
  }

  // Date formatting methods
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatReceiptDate(DateTime date) {
    return _receiptDateFormatter.format(date);
  }

  static String formatReceiptTime(DateTime time) {
    return _receiptTimeFormatter.format(time);
  }

  static String formatFullDate(DateTime date) {
    return _fullDateFormatter.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  static String formatDay(DateTime date) {
    return _dayFormatter.format(date);
  }

  static String formatIsoDate(DateTime date) {
    return _isoFormatter.format(date);
  }

  // Relative time formatting
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Order number formatting
  static String formatOrderNumber(String orderNumber) {
    return '#$orderNumber';
  }

  // Transaction ID formatting
  static String formatTransactionId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 8)}...';
    }
    return id;
  }

  // Stock formatting
  static String formatStock(int stock) {
    if (stock <= 0) {
      return 'Out of stock';
    } else if (stock < 10) {
      return 'Low stock ($stock)';
    }
    return '$stock in stock';
  }

  // Percentage formatting
  static String formatPercentage(double value, {int decimalDigits = 1}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  // Phone number formatting
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11) {
      return '+${digits.substring(0, 1)} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      // Remove currency symbol and commas
      final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Only allow digits
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse loop to handle rapid typing or deletions
    double value = double.tryParse(newText) ?? 0;

    // Format
    final formatter = NumberFormat('#,###', 'id_ID');
    String formatted = formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
