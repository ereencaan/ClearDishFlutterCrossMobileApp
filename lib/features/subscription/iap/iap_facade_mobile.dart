import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

export 'iap_facade_stub.dart'
    show IapFacade, IapProduct, IapPurchase, IapPurchaseStatus;

import 'iap_facade_stub.dart'
    show IapFacade, IapProduct, IapPurchase, IapPurchaseStatus;

class MobileIapFacade implements IapFacade {
  MobileIapFacade._();
  static final MobileIapFacade _instance = MobileIapFacade._();
  static MobileIapFacade instance() => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  bool get isSupported => true;

  @override
  Stream<List<IapPurchase>> get purchaseStream =>
      _iap.purchaseStream.map((purchases) {
        return purchases.map(_mapPurchase).toList(growable: false);
      });

  @override
  Future<List<IapProduct>> queryProducts(Set<String> productIds) async {
    final resp = await _iap.queryProductDetails(productIds);
    return resp.productDetails
        .map((p) {
          return IapProduct(
            id: p.id,
            title: p.title,
            description: p.description,
            price: p.price,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> buyNonConsumable(String productId) async {
    final resp = await _iap.queryProductDetails({productId});
    final details = resp.productDetails.isNotEmpty
        ? resp.productDetails.first
        : null;
    if (details == null) {
      throw StateError('Product not found: $productId');
    }
    final param = PurchaseParam(productDetails: details);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  IapPurchase _mapPurchase(PurchaseDetails p) {
    final status = switch (p.status) {
      PurchaseStatus.pending => IapPurchaseStatus.pending,
      PurchaseStatus.purchased => IapPurchaseStatus.purchased,
      PurchaseStatus.restored => IapPurchaseStatus.restored,
      PurchaseStatus.error => IapPurchaseStatus.error,
      PurchaseStatus.canceled => IapPurchaseStatus.canceled,
    };
    return IapPurchase(
      productId: p.productID,
      status: status,
      verificationData: p.verificationData.serverVerificationData,
      errorMessage: p.error?.message,
    );
  }
}

IapFacade createIapFacade() => MobileIapFacade.instance();
