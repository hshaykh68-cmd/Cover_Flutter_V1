import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/presentation/widgets/apple_style_top_bar.dart';
import 'package:cover/core/billing/subscription_service.dart';
import 'package:cover/core/di/di_container.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  String? _monthlyPrice;
  String? _yearlyPrice;
  String? _lifetimePrice;
  bool _hasRegionalDiscount = false;
  bool _isLoadingPricing = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    final appConfig = ref.read(appConfigProvider);
    final regionalPricingService = ref.read(regionalPricingServiceProvider);
    
    // Apply regional pricing if enabled
    if (appConfig.subscriptionDiscountEnabled) {
      final pricing = await regionalPricingService.getPricingForDisplay();
      
      setState(() {
        _monthlyPrice = pricing['monthly'];
        _yearlyPrice = pricing['yearly'];
        _lifetimePrice = pricing['lifetime'];
        _hasRegionalDiscount = pricing['hasDiscount'] == 'true';
        _isLoadingPricing = false;
      });
    } else {
      // Load base prices from config
      setState(() {
        _monthlyPrice = '\$${appConfig.subscriptionMonthlyPriceUsd.toStringAsFixed(2)}';
        _yearlyPrice = '\$${appConfig.subscriptionYearlyPriceUsd.toStringAsFixed(2)}';
        _lifetimePrice = '\$${appConfig.subscriptionLifetimePriceUsd.toStringAsFixed(2)}';
        _isLoadingPricing = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppleStyleTopBar(
            title: 'Premium',
            showBackButton: true,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    _buildProBadge(),
                    const SizedBox(height: 24),
                    const Text(
                      'Unlock the Full Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Get unlimited access to all premium features',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildFeatureCard(
                      CupertinoIcons.infinity,
                      'Unlimited Storage',
                      'Store as many photos, videos, files, and notes as you want',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      CupertinoIcons.xmark_circle,
                      'No Ads',
                      'Enjoy an ad-free experience throughout the app',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      CupertinoIcons.cloud,
                      'Cloud Backup',
                      'Securely backup your vault to the cloud',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      CupertinoIcons.lock_shield,
                      'Advanced Security',
                      'Get additional security features and priority support',
                    ),
                    const SizedBox(height: 40),
                    if (_isLoadingPricing)
                      const Center(
                        child: CupertinoActivityIndicator(),
                      )
                    else
                      _buildPricingCards(),
                    const SizedBox(height: 32),
                    _buildRestorePurchasesButton(),
                    const SizedBox(height: 16),
                    _buildTermsButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.systemOrange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.star_fill,
            color: Colors.black,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'COVER PRO',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.systemOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.systemOrange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.2),
            Colors.teal.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.tag_fill,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Special pricing available for your region! 50% discount applied.',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    if (_monthlyPrice == null || _yearlyPrice == null || _lifetimePrice == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        _buildPricingCard(
          'Monthly',
          _monthlyPrice!,
          'per month',
          false,
        ),
        const SizedBox(height: 12),
        _buildPricingCard(
          'Yearly',
          _yearlyPrice!,
          'per year - Save 58%',
          true,
        ),
        const SizedBox(height: 12),
        _buildPricingCard(
          'Lifetime',
          _lifetimePrice!,
          'one-time',
          false,
        ),
      ],
    );
  }

  Widget _buildPricingCard(String title, String price, String period, bool isPopular) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Handle purchase
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPopular ? AppTheme.systemOrange.withOpacity(0.15) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? AppTheme.systemOrange : Colors.white.withOpacity(0.08),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isPopular ? AppTheme.systemOrange : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.systemOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestorePurchasesButton() {
    return TextButton(
      onPressed: () async {
        HapticFeedback.lightImpact();
        final subscriptionService = ref.read(subscriptionServiceProvider);
        await subscriptionService.restorePurchases();
      },
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTermsButton() {
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        // Show terms
      },
      child: Text(
        'Terms & Privacy Policy',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
    );
  }
}
