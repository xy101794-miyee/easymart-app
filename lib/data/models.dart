import 'dart:convert';

class AppUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      role: map['role'] as String? ?? 'User',
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final String unit;
  final int stock;
  final String imagePath;
  final bool featured;
  final bool available;
  final String categoryName;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.stock,
    required this.imagePath,
    required this.featured,
    required this.available,
    this.categoryName = '',
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'piece',
      stock: map['stock'] as int? ?? 0,
      imagePath: map['image_path'] as String? ?? 'assets/images/product_generic.svg',
      featured: (map['is_featured'] as int? ?? 0) == 1,
      available: (map['available'] as int? ?? 1) == 1,
      categoryName: map['category_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'stock': stock,
      'image_path': imagePath,
      'is_featured': featured ? 1 : 0,
      'available': available ? 1 : 0,
    };
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon};
  }
}

class AddressModel {
  final int id;
  final int userId;
  final String label;
  final String fullAddress;

  AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      label: map['label'] as String? ?? 'Home',
      fullAddress: map['full_address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'full_address': fullAddress,
    };
  }
}

class CartEntry {
  final int productId;
  final String name;
  final String imagePath;
  final double unitPrice;
  final String unit;
  int quantity;

  CartEntry({
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double productPrice;
  final String unit;
  final int quantity;
  final String imagePath;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.unit,
    required this.quantity,
    required this.imagePath,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      productPrice: (map['product_price'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'piece',
      quantity: map['quantity'] as int? ?? 0,
      imagePath: map['image_path'] as String? ?? 'assets/images/product_generic.svg',
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryInstructions;
  final String paymentMethod;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryInstructions,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {List<OrderItemModel> items = const []}) {
    return OrderModel(
      id: map['id'] as int,
      orderNumber: map['order_number'] as String,
      userId: map['user_id'] as int,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      deliveryAddress: map['delivery_address'] as String,
      deliveryInstructions: map['delivery_instructions'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? 'Cash on Delivery',
      status: map['status'] as String? ?? 'Order Placed',
      subtotal: (map['subtotal'] as num).toDouble(),
      deliveryFee: (map['delivery_fee'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }
}

String hashPassword(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}
