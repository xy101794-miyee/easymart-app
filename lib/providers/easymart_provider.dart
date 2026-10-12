import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../data/models.dart';
import '../data/database.dart';

class EasymartProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  EasymartProvider(this.prefs);

  bool isLoading = false;
  AppUser? currentUser;
  List<CategoryModel> categories = [];
  List<ProductModel> products = [];
  List<CartEntry> cartItems = [];
  List<OrderModel> userOrders = [];
  List<AddressModel> addresses = [];
  bool isAdmin = false;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    categories = await AppDatabase.instance.fetchCategories();
    products = await AppDatabase.instance.fetchProducts();

    final userId = prefs.getInt('logged_in_user_id');
    if (userId != null) {
      currentUser = await AppDatabase.instance.getUserById(userId);
      if (currentUser != null) {
        isAdmin = currentUser!.role == 'Admin';
        addresses = await AppDatabase.instance.fetchAddresses(currentUser!.id);
        userOrders = await AppDatabase.instance.fetchOrdersForUser(currentUser!.id);
        cartItems = await AppDatabase.instance.fetchCart(currentUser!.id);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<AppUser?> login({required String email, required String password}) async {
    final user = await AppDatabase.instance.loginUser(email, password);
    if (user == null) {
      return null;
    }

    currentUser = user;
    isAdmin = user.role == 'Admin';
    await prefs.setInt('logged_in_user_id', user.id);
    await prefs.setString('logged_in_role', user.role);
    addresses = await AppDatabase.instance.fetchAddresses(user.id);
    userOrders = await AppDatabase.instance.fetchOrdersForUser(user.id);
    cartItems = await AppDatabase.instance.fetchCart(user.id);
    notifyListeners();
    return user;
  }

  Future<AppUser?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final user = await AppDatabase.instance.registerUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    if (user == null) return null;
    currentUser = user;
    isAdmin = false;
    await prefs.setInt('logged_in_user_id', user.id);
    await prefs.setString('logged_in_role', user.role);
    addresses = await AppDatabase.instance.fetchAddresses(user.id);
    userOrders = await AppDatabase.instance.fetchOrdersForUser(user.id);
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    currentUser = null;
    isAdmin = false;
    cartItems.clear();
    userOrders.clear();
    addresses.clear();
    await prefs.remove('logged_in_user_id');
    await prefs.remove('logged_in_role');
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    products = await AppDatabase.instance.fetchProducts();
    notifyListeners();
  }

  Future<void> refreshCategories() async {
    categories = await AppDatabase.instance.fetchCategories();
    notifyListeners();
  }

  Future<void> refreshCart() async {
    if (currentUser == null) return;
    cartItems = await AppDatabase.instance.fetchCart(currentUser!.id);
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    if (currentUser == null) return;
    userOrders = await AppDatabase.instance.fetchOrdersForUser(currentUser!.id);
    notifyListeners();
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    if (currentUser == null) return;
    final available = product.stock;
    if (quantity > available) {
      throw FlutterError('Requested quantity exceeds available stock.');
    }
    await AppDatabase.instance.addToCart(
      userId: currentUser!.id,
      productId: product.id,
      quantity: quantity,
    );
    await refreshCart();
  }

  Future<void> updateCartItemQuantity(int productId, int newQuantity) async {
    if (currentUser == null) return;
    await AppDatabase.instance.updateCartQuantity(
      userId: currentUser!.id,
      productId: productId,
      quantity: newQuantity,
    );
    await refreshCart();
  }

  Future<void> removeCartItem(int productId) async {
    if (currentUser == null) return;
    await AppDatabase.instance.removeFromCart(currentUser!.id, productId);
    await refreshCart();
  }

  double get subtotal {
    return cartItems.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  double get deliveryFee => cartItems.isEmpty ? 0 : 35.0;

  double get discount => 0.0;

  double get total => subtotal + deliveryFee - discount;

  Future<int> placeOrder({
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String deliveryInstructions,
    required String paymentMethod,
  }) async {
    if (currentUser == null) return -1;
    if (cartItems.isEmpty) return -1;

    for (final item in cartItems) {
      final matchingProduct = products.firstWhere(
        (element) => element.id == item.productId,
        orElse: () => ProductModel(
          id: 0,
          categoryId: 0,
          name: '',
          description: '',
          price: 0,
          unit: '',
          stock: 0,
          imagePath: 'assets/images/product_generic.svg',
          featured: false,
          available: true,
        ),
      );
      if (matchingProduct.stock < item.quantity) {
        throw FlutterError('Stock issue for ${matchingProduct.name}.');
      }
    }

    final orderId = await AppDatabase.instance.createOrder(
      userId: currentUser!.id,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      items: cartItems,
    );

    cartItems.clear();
    await refreshCart();
    await refreshProducts();
    await refreshOrders();
    notifyListeners();
    return orderId;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await AppDatabase.instance.updateOrderStatus(orderId, status);
    if (currentUser != null) {
      userOrders = await AppDatabase.instance.fetchOrdersForUser(currentUser!.id);
    }
    notifyListeners();
  }

  Future<void> saveAddress({required String label, required String address}) async {
    if (currentUser == null) return;
    await AppDatabase.instance.saveAddress(
      userId: currentUser!.id,
      label: label,
      fullAddress: address,
    );
    addresses = await AppDatabase.instance.fetchAddresses(currentUser!.id);
    notifyListeners();
  }

  Future<List<OrderModel>> fetchAllOrders() async {
    final allOrders = await AppDatabase.instance.fetchAllOrders();
    return allOrders;
  }

  Future<void> adminRefresh() async {
    categories = await AppDatabase.instance.fetchCategories();
    products = await AppDatabase.instance.fetchProducts();
    notifyListeners();
  }
}
