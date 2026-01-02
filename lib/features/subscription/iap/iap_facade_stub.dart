class IapProduct {
  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final String price;
}

enum IapPurchaseStatus { pending, purchased, restored, error, canceled }

class IapPurchase {
  const IapPurchase({
    required this.productId,
    required this.status,
    this.verificationData,
    this.errorMessage,
  });

  final String productId;
  final IapPurchaseStatus status;
  final String? verificationData;
  final String? errorMessage;
}

abstract class IapFacade {
  bool get isSupported => false;

  Future<List<IapProduct>> queryProducts(Set<String> productIds) async => const [];

  Stream<List<IapPurchase>> get purchaseStream => const Stream.empty();

  Future<void> buyNonConsumable(String productId) async {
    throw UnsupportedError('In-app purchases are not supported on this platform.');
  }

  Future<void> restorePurchases() async {}
}

IapFacade createIapFacade() => _StubIapFacade();

class _StubIapFacade implements IapFacade {
  @override
  bool get isSupported => false;

  @override
  Stream<List<IapPurchase>> get purchaseStream => const Stream.empty();

  @override
  Future<List<IapProduct>> queryProducts(Set<String> productIds) async => const [];

  @override
  Future<void> buyNonConsumable(String productId) async {
    throw UnsupportedError('In-app purchases are not supported on this platform.');
  }

  @override
  Future<void> restorePurchases() async {}
}

