import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String proUnlockProductId = 'insysout_anpr_pro_unlock';
const String proUnlockFallbackPrice = 'USD 2';

final proUnlockControllerProvider = StateNotifierProvider<ProUnlockController, ProUnlockState>(
  (ref) => ProUnlockController(),
);

@immutable
class ProUnlockState {
  final bool isAvailable;
  final bool isUnlocked;
  final bool isLoading;
  final String? price;
  final String? message;
  final ProductDetails? product;

  const ProUnlockState({
    this.isAvailable = false,
    this.isUnlocked = false,
    this.isLoading = false,
    this.price,
    this.message,
    this.product,
  });

  ProUnlockState copyWith({
    bool? isAvailable,
    bool? isUnlocked,
    bool? isLoading,
    String? price,
    String? message,
    ProductDetails? product,
    bool clearMessage = false,
  }) {
    return ProUnlockState(
      isAvailable: isAvailable ?? this.isAvailable,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isLoading: isLoading ?? this.isLoading,
      price: price ?? this.price,
      message: clearMessage ? null : (message ?? this.message),
      product: product ?? this.product,
    );
  }
}

class ProUnlockController extends StateNotifier<ProUnlockState> {
  ProUnlockController() : super(const ProUnlockState(isLoading: true)) {
    _init();
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUnlocked = prefs.getBool('pro_unlocked') ?? false;

    final available = await _iap.isAvailable();
    if (!available) {
      state = ProUnlockState(
        isAvailable: false,
        isUnlocked: storedUnlocked,
        isLoading: false,
        price: proUnlockFallbackPrice,
        message: storedUnlocked ? null : 'In-App Purchase is not available on this device yet.',
      );
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        state = state.copyWith(isLoading: false, message: error.toString());
      },
    );

    final response = await _iap.queryProductDetails({proUnlockProductId});
    final product = response.productDetails.isEmpty ? null : response.productDetails.first;

    state = ProUnlockState(
      isAvailable: true,
      isUnlocked: storedUnlocked,
      isLoading: false,
      price: product?.price ?? proUnlockFallbackPrice,
      product: product,
      message: response.notFoundIDs.isNotEmpty
          ? 'Pro purchase is not configured in App Store Connect yet.'
          : null,
    );
  }

  Future<void> buyPro() async {
    final product = state.product;
    if (state.isUnlocked) return;
    if (product == null) {
      state = state.copyWith(message: 'Pro purchase is not ready. Check the App Store Connect product ID.');
      return;
    }

    state = state.copyWith(isLoading: true, clearMessage: true);
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != proUnlockProductId) continue;

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        // For this app, the Pro unlock is a non-consumable feature unlock.
        // No server-side validation is used in this lightweight first release.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pro_unlocked', true);
        state = state.copyWith(
          isUnlocked: true,
          isLoading: false,
          message: 'Pro unlocked. Unlimited events are now available.',
        );
      } else if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          isLoading: false,
          message: purchase.error?.message ?? 'Purchase failed.',
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(isLoading: false, message: 'Purchase cancelled.');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
