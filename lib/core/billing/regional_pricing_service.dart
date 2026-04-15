import 'dart:io';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';

/// Regional pricing configuration
class RegionalPricingConfig {
  final String countryCode;
  final String currencyCode;
  final double discountMultiplier; // e.g., 0.5 for 50% discount

  const RegionalPricingConfig({
    required this.countryCode,
    required this.currencyCode,
    required this.discountMultiplier,
  });
}

/// Service for regional pricing based on purchasing power parity (PPP)
class RegionalPricingService {
  final AppConfig _appConfig;

  RegionalPricingService({required AppConfig appConfig}) : _appConfig = appConfig;

  // Countries eligible for 50% discount
  static const Set<String> _discountCountries = {
    // South Asia
    'IN', // India
    'BD', // Bangladesh
    'PK', // Pakistan
    'LK', // Sri Lanka
    'NP', // Nepal
    'BT', // Bhutan
    // Southeast Asia
    'PH', // Philippines
    'ID', // Indonesia
    'VN', // Vietnam
    'MM', // Myanmar
    'KH', // Cambodia
    'LA', // Laos
    // Africa
    'NG', // Nigeria
    'KE', // Kenya
    'GH', // Ghana
    'ET', // Ethiopia
    'TZ', // Tanzania
    'UG', // Uganda
    'EG', // Egypt
    'MA', // Morocco
    // Latin America
    'BO', // Bolivia
    'HN', // Honduras
    'NI', // Nicaragua
    'SV', // El Salvador
    'GT', // Guatemala
    // Others
    'UA', // Ukraine
    'UZ', // Uzbekistan
  };

  // Default discount countries (fallback if _discountCountries is empty)
  static const Set<String> _defaultDiscountCountries = {
    'IN', 'BD', 'PK', 'LK', 'NP', 'BT',
    'PH', 'ID', 'VN', 'MM', 'KH', 'LA',
    'NG', 'KE', 'GH', 'ET', 'TZ', 'UG', 'EG', 'MA',
    'BO', 'HN', 'NI', 'SV', 'GT',
    'UA', 'UZ',
  };

  // Currency codes for discount countries (simplified mapping)
  static const Map<String, String> _countryToCurrency = {
    'IN': 'INR',
    'BD': 'BDT',
    'PK': 'PKR',
    'LK': 'LKR',
    'NP': 'NPR',
    'BT': 'BTN',
    'PH': 'PHP',
    'ID': 'IDR',
    'VN': 'VND',
    'MM': 'MMK',
    'KH': 'KHR',
    'LA': 'LAK',
    'NG': 'NGN',
    'KE': 'KES',
    'GH': 'GHS',
    'ET': 'ETB',
    'TZ': 'TZS',
    'UG': 'UGX',
    'EG': 'EGP',
    'MA': 'MAD',
    'BO': 'BOB',
    'HN': 'HNL',
    'NI': 'NIO',
    'SV': 'USD',
    'GT': 'GTQ',
    'UA': 'UAH',
    'UZ': 'UZS',
  };

  // Base prices in USD
  static const double _baseMonthlyPrice = 1.99;
  static const double _baseYearlyPrice = 9.99;
  static const double _baseLifetimePrice = 49.99;

  // Discount multiplier for PPP countries
  static const double _discountMultiplier = 0.5;

  /// Get the user's country code
  /// Note: This is a simplified implementation. In production, you would use:
  /// - For iOS: DeviceRegion from device_info_plus or locale
  /// - For Android: Play Billing's country code from purchase details
  /// - Or use a backend geolocation service
  Future<String> getCountryCode() async {
    try {
      // Simplified: Use device locale
      final locale = Platform.localeName;
      final countryCode = locale.split('_')[1];
      return countryCode.toUpperCase();
    } catch (e) {
      AppLogger.error('Failed to get country code', e);
      return 'US'; // Default to US
    }
  }

  /// Check if country is eligible for PPP discount
  bool isDiscountEligible(String countryCode) {
    final countries = _discountCountries.isNotEmpty ? _discountCountries : _defaultDiscountCountries;
    return countries.contains(countryCode.toUpperCase());
  }

  /// Get regional pricing configuration
  Future<RegionalPricingConfig> getRegionalPricingConfig() async {
    final countryCode = await getCountryCode();
    final isEligible = _appConfig.subscriptionDiscountEnabled && isDiscountEligible(countryCode);
    
    return RegionalPricingConfig(
      countryCode: countryCode,
      currencyCode: _countryToCurrency[countryCode.toUpperCase()] ?? 'USD',
      discountMultiplier: isEligible ? _discountMultiplier : 1.0,
    );
  }

  /// Get adjusted monthly price
  Future<double> getMonthlyPrice() async {
    final config = await getRegionalPricingConfig();
    return _baseMonthlyPrice * config.discountMultiplier;
  }

  /// Get adjusted yearly price
  Future<double> getYearlyPrice() async {
    final config = await getRegionalPricingConfig();
    return _baseYearlyPrice * config.discountMultiplier;
  }

  /// Get adjusted lifetime price
  Future<double> getLifetimePrice() async {
    final config = await getRegionalPricingConfig();
    return _baseLifetimePrice * config.discountMultiplier;
  }

  /// Format price with currency symbol
  String formatPrice(double price, String currencyCode) {
    // Simplified currency formatting
    final currencySymbols = {
      'USD': '\$',
      'INR': '₹',
      'BDT': '৳',
      'PKR': '₨',
      'LKR': 'Rs',
      'NPR': '₨',
      'BTN': 'Nu.',
      'PHP': '₱',
      'IDR': 'Rp',
      'VND': '₫',
      'MMK': 'K',
      'KHR': '៛',
      'LAK': '₭',
      'NGN': '₦',
      'KES': 'KSh',
      'GHS': 'GH₵',
      'ETB': 'Br',
      'TZS': 'TSh',
      'UGX': 'USh',
      'EGP': 'E£',
      'MAD': 'DH',
      'BOB': 'Bs',
      'HNL': 'L',
      'NIO': 'C\$',
      'GTQ': 'Q',
      'UAH': '₴',
      'UZS': 'so\'m',
    };

    final symbol = currencySymbols[currencyCode] ?? '\$';
    return '$symbol${price.toStringAsFixed(2)}';
  }

  /// Get pricing for display (with currency)
  Future<Map<String, String>> getPricingForDisplay() async {
    final config = await getRegionalPricingConfig();
    final monthly = await getMonthlyPrice();
    final yearly = await getYearlyPrice();
    final lifetime = await getLifetimePrice();

    return {
      'monthly': formatPrice(monthly, config.currencyCode),
      'yearly': formatPrice(yearly, config.currencyCode),
      'lifetime': formatPrice(lifetime, config.currencyCode),
      'currency': config.currencyCode,
      'hasDiscount': config.discountMultiplier < 1.0 ? 'true' : 'false',
    };
  }

  /// Get product ID for regional pricing
  /// Note: Google Play Billing handles regional pricing automatically
  /// You configure different prices for different countries in Play Console
  /// This method returns the appropriate product ID based on region
  String getRegionalProductId(String baseProductId, String countryCode) {
    if (!isDiscountEligible(countryCode)) {
      return baseProductId;
    }

    // For discount countries, use regional product IDs
    // These would be configured in Play Console with lower prices
    if (baseProductId.contains('monthly')) {
      return 'com.cover.subscription.monthly.discount';
    } else if (baseProductId.contains('yearly')) {
      return 'com.cover.subscription.yearly.discount';
    } else if (baseProductId.contains('lifetime')) {
      return 'com.cover.lifetime.discount';
    }

    return baseProductId;
  }
}
