import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../data/models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'easymart.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDemoData(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'User',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        unit TEXT NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        is_featured INTEGER NOT NULL DEFAULT 0,
        available INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        delivery_address TEXT NOT NULL,
        delivery_instructions TEXT,
        subtotal REAL NOT NULL,
        delivery_fee REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Order Placed',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_price REAL NOT NULL,
        product_unit TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        image_path TEXT,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        full_address TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        UNIQUE (user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
  }

  Future<void> _seedDemoData(Database db) async {
    final categories = [
      'Fruits',
      'Vegetables',
      'Meat and Seafood',
      'Dairy and Eggs',
      'Rice and Grains',
      'Bread and Bakery',
      'Snacks and Biscuits',
      'Beverages',
      'Canned Goods',
      'Frozen Foods',
      'Personal Care',
      'Household Cleaning',
      'Cooking Essentials',
      'Baby Products',
    ];

    for (final category in categories) {
      await db.insert('categories', {'name': category, 'icon': category.substring(0, 1).toUpperCase()});
    }

    final customerHash = hashPassword('User123!');
    final adminHash = hashPassword('Admin123!');

    await db.insert('users', {
      'name': 'Demo Customer',
      'email': AppStrings.customerDemoEmail,
      'phone': '09170000001',
      'password_hash': customerHash,
      'role': 'User',
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('users', {
      'name': 'System Admin',
      'email': AppStrings.adminDemoEmail,
      'phone': '09170000002',
      'password_hash': adminHash,
      'role': 'Admin',
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final categoryRows = await db.query('categories');
    final categoryMap = {for (final item in categoryRows) item['name'] as String: item['id'] as int};

    final products = [
      {'name': 'Rice', 'category': 'Rice and Grains', 'description': 'Premium quality long grain rice.', 'price': 55.0, 'unit': 'kg', 'stock': 40, 'is_featured': 1},
      {'name': 'Eggs', 'category': 'Dairy and Eggs', 'description': 'Farm fresh chicken eggs.', 'price': 12.0, 'unit': 'piece', 'stock': 82, 'is_featured': 1},
      {'name': 'Fresh Milk', 'category': 'Dairy and Eggs', 'description': 'Rich and creamy whole milk.', 'price': 95.0, 'unit': 'liter', 'stock': 30, 'is_featured': 1},
      {'name': 'Bananas', 'category': 'Fruits', 'description': 'Sweet and ripe bananas.', 'price': 80.0, 'unit': 'kg', 'stock': 20, 'is_featured': 1},
      {'name': 'Tomatoes', 'category': 'Vegetables', 'description': 'Fresh tomatoes for cooking.', 'price': 70.0, 'unit': 'kg', 'stock': 26, 'is_featured': 1},
      {'name': 'Potatoes', 'category': 'Vegetables', 'description': 'Versatile potatoes for all meals.', 'price': 90.0, 'unit': 'kg', 'stock': 33, 'is_featured': 1},
      {'name': 'Chicken', 'category': 'Meat and Seafood', 'description': 'Fresh chicken pieces for everyday meals.', 'price': 220.0, 'unit': 'kg', 'stock': 14, 'is_featured': 1},
      {'name': 'Bread', 'category': 'Bread and Bakery', 'description': 'Soft and fresh daily bread.', 'price': 45.0, 'unit': 'pack', 'stock': 50, 'is_featured': 0},
      {'name': 'Bottled Water', 'category': 'Beverages', 'description': 'Refreshing mineral drinking water.', 'price': 20.0, 'unit': 'bottle', 'stock': 100, 'is_featured': 0},
      {'name': 'Cooking Oil', 'category': 'Cooking Essentials', 'description': 'Healthy cooking oil for everyday use.', 'price': 85.0, 'unit': 'liter', 'stock': 22, 'is_featured': 0},
      {'name': 'Instant Noodles', 'category': 'Snacks and Biscuits', 'description': 'Quick meal for busy days.', 'price': 18.0, 'unit': 'pack', 'stock': 65, 'is_featured': 0},
      {'name': 'Laundry Detergent', 'category': 'Household Cleaning', 'description': 'Bright and fresh detergent wash.', 'price': 25.0, 'unit': 'pack', 'stock': 12, 'is_featured': 0},
      {'name': 'Canned Tuna', 'category': 'Canned Goods', 'description': 'Protein-packed canned tuna.', 'price': 42.0, 'unit': 'can', 'stock': 35, 'is_featured': 0},
      {'name': 'Frozen Mixed Vegetables', 'category': 'Frozen Foods', 'description': 'Easy-to-cook vegetable mix.', 'price': 75.0, 'unit': 'pack', 'stock': 18, 'is_featured': 0},
      {'name': 'Baby Wipes', 'category': 'Baby Products', 'description': 'Gentle wipes for daily care.', 'price': 58.0, 'unit': 'pack', 'stock': 17, 'is_featured': 0},
    ];

    for (final product in products) {
      final categoryId = categoryMap[product['category']] as int?;
      if (categoryId == null) continue;

      await db.insert('products', {
        'category_id': categoryId,
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'unit': product['unit'],
        'stock': product['stock'],
        'image_path': 'assets/images/product_generic.svg',
        'is_featured': product['is_featured'] == 1 ? 1 : 0,
        'available': 1,
      });
    }

    final defaultAddress = await db.query('users', where: 'email = ?', whereArgs: [AppStrings.customerDemoEmail], limit: 1);
    if (defaultAddress.isNotEmpty) {
      await db.insert('addresses', {
        'user_id': defaultAddress.first['id'],
        'label': 'Home',
        'full_address': '123 Mabini Street, Quezon City, Metro Manila',
      });
      await db.insert('addresses', {
        'user_id': defaultAddress.first['id'],
        'label': 'Office',
        'full_address': '45 Don Bosco Avenue, Makati City, Metro Manila',
      });
    }
  }

  Future<AppUser?> loginUser(String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND is_active = 1',
      whereArgs: [email.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final user = AppUser.fromMap(rows.first);
    if (user.passwordHash == hashPassword(password)) {
      return user;
    }
    return null;
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final db = await database;
    final existing = await db.query('users', where: 'email = ?', whereArgs: [email.trim()], limit: 1);
    if (existing.isNotEmpty) return null;

    final id = await db.insert('users', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password_hash': hashPassword(password),
      'role': 'User',
      'is_active': 1,
    });

    return await getUserById(id);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final db = await database;
    final rows = await db.query('categories');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<List<ProductModel>> fetchProducts({
    int? categoryId,
    String? query,
    String sortBy = 'newest',
    double? minPrice,
    double? maxPrice,
  }) async {
    final db = await database;

    String whereClause = 'available = 1';
    final args = <dynamic>[];

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      args.add(categoryId);
    }

    if (query != null && query.trim().isNotEmpty) {
      whereClause += ' AND name LIKE ?';
      args.add('%${query.trim()}%');
    }

    if (minPrice != null) {
      whereClause += ' AND price >= ?';
      args.add(minPrice);
    }

    if (maxPrice != null) {
      whereClause += ' AND price <= ?';
      args.add(maxPrice);
    }

    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE $whereClause
    ''', args);

    final products = rows.map(ProductModel.fromMap).toList();

    switch (sortBy) {
      case 'price_low_to_high':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_to_low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case 'newest':
      default:
        products.sort((a, b) => b.id.compareTo(a.id));
    }

    return products;
  }

  Future<void> createProduct(ProductModel product) async {
    final db = await database;
    await db.insert('products', product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createCategory(CategoryModel category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveAddress({
    required int userId,
    required String label,
    required String fullAddress,
  }) async {
    final db = await database;
    await db.insert('addresses', {
      'user_id': userId,
      'label': label,
      'full_address': fullAddress,
    });
  }

  Future<List<AddressModel>> fetchAddresses(int userId) async {
    final db = await database;
    final rows = await db.query('addresses', where: 'user_id = ?', whereArgs: [userId]);
    return rows.map(AddressModel.fromMap).toList();
  }

  Future<void> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final db = await database;

    final existing = await db.query(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final current = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {'quantity': current + quantity},
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } else {
      await db.insert('cart_items', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  Future<List<CartEntry>> fetchCart(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.user_id, c.product_id, c.quantity, p.name, p.price, p.unit, p.image_path
      FROM cart_items c
      INNER JOIN products p ON p.id = c.product_id
      WHERE c.user_id = ?
    ''', [userId]);

    return rows.map((row) {
      return CartEntry(
        productId: row['product_id'] as int,
        name: row['name'] as String,
        imagePath: row['image_path'] as String? ?? 'assets/images/product_generic.svg',
        unitPrice: (row['price'] as num).toDouble(),
        unit: row['unit'] as String,
        quantity: row['quantity'] as int,
      );
    }).toList();
  }

  Future<void> updateCartQuantity({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete(
        'cart_items',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
      return;
    }

    await db.update(
      'cart_items',
      {'quantity': quantity},
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<void> removeFromCart(int userId, int productId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<int> createOrder({
    required int userId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String deliveryInstructions,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required List<CartEntry> items,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final orderNumber = 'EM-${DateTime.now().millisecondsSinceEpoch}';
      final orderId = await txn.insert('orders', {
        'order_number': orderNumber,
        'user_id': userId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'delivery_instructions': deliveryInstructions,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'total': total,
        'payment_method': paymentMethod,
        'status': 'Order Placed',
      });

      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.name,
          'product_price': item.unitPrice,
          'product_unit': item.unit,
          'quantity': item.quantity,
          'image_path': item.imagePath,
        });

        final productRows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (productRows.isNotEmpty) {
          final currentStock = (productRows.first['stock'] as int);
          final newStock = (currentStock - item.quantity).clamp(0, 999999);
          await txn.update(
            'products',
            {'stock': newStock},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      return orderId;
    });
  }

  Future<List<OrderModel>> fetchOrdersForUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final orders = <OrderModel>[];
    for (final row in rows) {
      final orderId = row['id'] as int;
      final itemsRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemsRows.map(OrderItemModel.fromMap).toList();
      orders.add(OrderModel.fromMap(row, items: items));
    }
    return orders;
  }

  Future<List<OrderModel>> fetchAllOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'created_at DESC');
    final orders = <OrderModel>[];
    for (final row in rows) {
      final orderId = row['id'] as int;
      final itemRows = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      final items = itemRows.map(OrderItemModel.fromMap).toList();
      orders.add(OrderModel.fromMap(row, items: items));
    }
    return orders;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<AppUser>> fetchUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'id DESC');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> cancelOrderAndRestoreStock(int orderId) async {
    final db = await database;
    final itemRows = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);

    for (final item in itemRows) {
      final productId = item['product_id'] as int;
      final quantity = item['quantity'] as int;
      final productRows = await db.query('products', where: 'id = ?', whereArgs: [productId], limit: 1);
      if (productRows.isNotEmpty) {
        final currentStock = productRows.first['stock'] as int;
        await db.update(
          'products',
          {'stock': currentStock + quantity},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    }

    await db.update(
      'orders',
      {'status': 'Cancelled'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
