import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/transaction_model.dart' as models;
import '../models/category_model.dart';
import '../models/shift_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final _uuid = const Uuid();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows/Linux desktop
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'pos_system_web.db';
    } else if (Platform.isWindows || Platform.isLinux) {
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, 'pos_system.db');
    } else {
      path = join(await getDatabasesPath(), 'pos_system.db');
    }

    if (kDebugMode) {
      print('Database initialized at: $path');
    }

    final db = await openDatabase(
      path,
      version: 5, // Incremented version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Check if products table is empty and reseed if needed
    await _checkAndReseedProducts(db);

    return db;
  }

  Future<void> _checkAndReseedProducts(Database db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE isDeleted = 0',
    );
    final count = result.first['count'] as int;

    if (count == 0) {
      await _seedProducts(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        avatarUrl TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        lastLogin TEXT,
        updatedAt TEXT,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        imageUrl TEXT,
        description TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        orderNumber TEXT UNIQUE NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        paymentMethod TEXT,
        amountPaid REAL,
        change REAL,
        cashierId TEXT,
        cashierName TEXT,
        customerName TEXT,
        notes TEXT,
        isDineIn INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        updatedAt TEXT,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        orderNumber TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        cashierId TEXT,
        cashierName TEXT,
        customerName TEXT,
        reference TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        FOREIGN KEY (orderId) REFERENCES orders (id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'id': _uuid.v4(),
      'username': 'admin',
      'password': 'admin123',
      'name': 'Administrator',
      'role': 'admin',
      'email': 'admin@pos.com',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'isSynced': 0,
      'isDeleted': 0,
    });

    // Insert default cashier user
    await db.insert('users', {
      'id': _uuid.v4(),
      'username': 'cashier',
      'password': 'cashier123',
      'name': 'Cashier 1',
      'role': 'cashier',
      'email': 'cashier@pos.com',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'isSynced': 0,
      'isDeleted': 0,
    });

    // Populate initial products
    await _seedProducts(db);

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        color INTEGER,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // Shifts table
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_cash REAL NOT NULL,
        expected_cash REAL DEFAULT 0,
        actual_cash REAL,
        status TEXT NOT NULL DEFAULT 'open'
      )
    ''');

    // Seed default categories
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns for hybrid sync
      final tables = ['users', 'products', 'orders', 'transactions'];
      for (final table in tables) {
        await _addColumnIfNotExists(db, table, 'updatedAt', 'TEXT');
        await _addColumnIfNotExists(db, table, 'isSynced', 'INTEGER DEFAULT 0');
        await _addColumnIfNotExists(
          db,
          table,
          'isDeleted',
          'INTEGER DEFAULT 0',
        );
      }
    }

    await _addColumnIfNotExists(db, 'orders', 'isDineIn', 'INTEGER DEFAULT 1');

    if (oldVersion < 4) {
      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT UNIQUE NOT NULL,
          color INTEGER,
          isActive INTEGER DEFAULT 1,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          isSynced INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0
        )
      ''');

      // Migrate existing distinct categories from products to categories table
      final distinctCategories = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE isDeleted = 0',
      );

      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (var row in distinctCategories) {
        final catName = row['category'] as String;
        if (catName.isNotEmpty) {
          batch.insert('categories', {
            'id': const Uuid().v4(),
            'name': catName,
            'color': null, // Default color
            'isActive': 1,
            'createdAt': now,
            'updatedAt': now,
            'isSynced': 0,
            'isDeleted': 0,
          });
        }
      }
      await batch.commit(noResult: true);
    }

    if (oldVersion < 5) {
      // Create shifts table
      await db.execute('''
        CREATE TABLE shifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          start_cash REAL NOT NULL,
          expected_cash REAL DEFAULT 0,
          actual_cash REAL,
          status TEXT NOT NULL DEFAULT 'open'
        )
      ''');
    }
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (e) {
      // Column likely already exists
    }
  }

  Future<void> _seedProducts(Database db) async {
    final now = DateTime.now().toIso8601String();
    final products = [
      // Coffee
      {
        'name': 'Espresso',
        'category': 'Coffee',
        'price': 18000,
        'stock': 100,
        'description': 'Bold and intense single espresso shot',
      },
      {
        'name': 'Americano',
        'category': 'Coffee',
        'price': 22000,
        'stock': 100,
        'description': 'Espresso with hot water',
      },
      {
        'name': 'Cappuccino',
        'category': 'Coffee',
        'price': 28000,
        'stock': 100,
        'description': 'Espresso with steamed milk foam',
      },
      {
        'name': 'Latte',
        'category': 'Coffee',
        'price': 30000,
        'stock': 100,
        'description': 'Espresso with steamed milk',
      },
      {
        'name': 'Mocha',
        'category': 'Coffee',
        'price': 32000,
        'stock': 100,
        'description': 'Espresso with chocolate and milk',
      },
      // Tea
      {
        'name': 'Green Tea',
        'category': 'Tea',
        'price': 15000,
        'stock': 100,
        'description': 'Traditional Japanese green tea',
      },
      {
        'name': 'Earl Grey',
        'category': 'Tea',
        'price': 18000,
        'stock': 100,
        'description': 'Black tea with bergamot',
      },
      {
        'name': 'Chamomile',
        'category': 'Tea',
        'price': 16000,
        'stock': 100,
        'description': 'Calming herbal tea',
      },
      {
        'name': 'Matcha Latte',
        'category': 'Tea',
        'price': 28000,
        'stock': 100,
        'description': 'Japanese matcha with steamed milk',
      },
      // Pastries
      {
        'name': 'Croissant',
        'category': 'Pastries',
        'price': 20000,
        'stock': 50,
        'description': 'Buttery French pastry',
      },
      {
        'name': 'Chocolate Muffin',
        'category': 'Pastries',
        'price': 18000,
        'stock': 50,
        'description': 'Rich chocolate muffin',
      },
      {
        'name': 'Blueberry Scone',
        'category': 'Pastries',
        'price': 22000,
        'stock': 50,
        'description': 'Fresh blueberry scone',
      },
      {
        'name': 'Cinnamon Roll',
        'category': 'Pastries',
        'price': 25000,
        'stock': 50,
        'description': 'Sweet cinnamon pastry',
      },
      // Snacks
      {
        'name': 'Cookies (3 pcs)',
        'category': 'Snacks',
        'price': 15000,
        'stock': 80,
        'description': 'Assorted cookies',
      },
      {
        'name': 'Brownie',
        'category': 'Snacks',
        'price': 18000,
        'stock': 60,
        'description': 'Rich chocolate brownie',
      },
      {
        'name': 'Banana Bread',
        'category': 'Snacks',
        'price': 20000,
        'stock': 40,
        'description': 'Moist banana bread slice',
      },
      // Other
      {
        'name': 'Mineral Water',
        'category': 'Other',
        'price': 8000,
        'stock': 200,
        'description': '500ml bottled water',
      },
      {
        'name': 'Orange Juice',
        'category': 'Other',
        'price': 15000,
        'stock': 100,
        'description': 'Fresh squeezed orange juice',
      },
    ];

    final batch = db.batch();
    for (var product in products) {
      batch.insert('products', {
        'id': _uuid.v4(),
        'name': product['name'],
        'category': product['category'],
        'price': product['price'],
        'stock': product['stock'],
        'imageUrl': '',
        'description': product['description'],
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
        'isSynced': 0,
        'isDeleted': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = ['Coffee', 'Tea', 'Pastries', 'Snacks', 'Other'];

    final batch = db.batch();
    for (var name in defaults) {
      batch.insert('categories', {
        'id': _uuid.v4(),
        'name': name,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
        'isSynced': 0,
        'isDeleted': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  // User operations
  Future<User?> authenticateUser(String username, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ? AND isActive = 1 AND isDeleted = 0',
      whereArgs: [username, password],
    );

    if (results.isNotEmpty) {
      final user = User.fromMap(results.first);
      // Update last login
      await db.update(
        'users',
        {
          'lastLogin': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return user;
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    final db = await database;

    // Check if username already exists (including deleted ones)
    final existingUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username],
    );

    if (existingUsers.isNotEmpty) {
      final existingUser = existingUsers.first;
      if (existingUser['isDeleted'] == 1) {
        // Reactivate soft-deleted user and update info
        final map = user.toMap();
        map['isSynced'] = 0;
        map['updatedAt'] = DateTime.now().toIso8601String();
        map['isDeleted'] = 0; // Reactivate
        map['isActive'] = 1; // Ensure active

        // Use the OLD ID to update the existing row
        return await db.update(
          'users',
          map,
          where: 'username = ?',
          whereArgs: [user.username],
        );
      } else {
        // User exists and is active -> let the Unique constraint fail naturally or throw specific error
        throw Exception('UNIQUE constraint failed: users.username');
      }
    }

    // Normal insert
    final map = user.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('users', map);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final map = user.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'users',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Resets/recreates the default admin user
  Future<void> resetAdminUser() async {
    final db = await database;

    // First, try to reactivate existing admin if soft-deleted
    final existingAdmin = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );

    if (existingAdmin.isNotEmpty) {
      // Reactivate and reset password
      await db.update(
        'users',
        {
          'password': 'admin123',
          'isActive': 1,
          'isDeleted': 0,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'username = ?',
        whereArgs: ['admin'],
      );
    } else {
      // Create new admin user
      await db.insert('users', {
        'id': _uuid.v4(),
        'username': 'admin',
        'password': 'admin123',
        'name': 'Administrator',
        'role': 'admin',
        'email': 'admin@pos.com',
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
        'isDeleted': 0,
      });
    }
  }

  // Product operations
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'isDeleted = 0',
      orderBy: 'name ASC',
    );
    return results.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getActiveProducts() async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'isActive = 1 AND isDeleted = 0',
      orderBy: 'name ASC',
    );
    return results.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'category = ? AND isActive = 1 AND isDeleted = 0',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return results.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<String>> getCategories() async {
    // Fetch from categories table
    final db = await database;
    final results = await db.query(
      'categories',
      where: 'isActive = 1 AND isDeleted = 0',
      orderBy: 'name ASC',
    );

    // Fallback to products if empty (rare case if migration worked)
    if (results.isEmpty) {
      final productCats = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE isActive = 1 AND isDeleted = 0 ORDER BY category ASC',
      );
      return productCats.map((map) => map['category'] as String).toList();
    }

    return results.map((map) => map['name'] as String).toList();
  }

  // Category CRUD
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final results = await db.query(
      'categories',
      where: 'isDeleted = 0',
      orderBy: 'name ASC',
    );
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    final map = category.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('categories', map);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;

    // Check if name changed to update products
    final oldCategory = await db.query(
      'categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [category.id],
    );

    String? oldName;
    if (oldCategory.isNotEmpty) {
      oldName = oldCategory.first['name'] as String;
    }

    final map = category.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'categories',
        map,
        where: 'id = ?',
        whereArgs: [category.id],
      );

      // If name changed, update all products with this category
      if (oldName != null && oldName != category.name) {
        await txn.update(
          'products',
          {
            'category': category.name,
            'updatedAt': DateTime.now().toIso8601String(),
            'isSynced': 0,
          },
          where: 'category = ?',
          whereArgs: [oldName],
        );
      }
    });

    return 1;
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.update(
      'categories',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return Product.fromMap(results.first);
    }
    return null;
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final map = product.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('products', map);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    final map = product.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'products',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductStock(String productId, int newStock) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Order operations
  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final results = await db.query(
      'orders',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return results.map((map) {
      final itemsJson = jsonDecode(map['items'] as String) as List;
      return Order.fromMap({...map, 'items': itemsJson});
    }).toList();
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final results = await db.query(
      'orders',
      where: 'createdAt >= ? AND createdAt <= ? AND isDeleted = 0',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) {
      final itemsJson = jsonDecode(map['items'] as String) as List;
      return Order.fromMap({...map, 'items': itemsJson});
    }).toList();
  }

  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final db = await database;
    final results = await db.query(
      'orders',
      where: 'status = ? AND isDeleted = 0',
      whereArgs: [status.toString().split('.').last],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) {
      final itemsJson = jsonDecode(map['items'] as String) as List;
      return Order.fromMap({...map, 'items': itemsJson});
    }).toList();
  }

  Future<Order?> getOrderById(String id) async {
    final db = await database;
    final results = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      final map = results.first;
      final itemsJson = jsonDecode(map['items'] as String) as List;
      return Order.fromMap({...map, 'items': itemsJson});
    }
    return null;
  }

  Future<String> generateOrderNumber() async {
    final db = await database;
    final today = DateTime.now();
    // YYMMDD format
    final year = (today.year % 100).toString().padLeft(2, '0');
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    final datePrefix = '$year$month$day';

    final results = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE orderNumber LIKE '$datePrefix%'",
    );

    final count = (results.first['count'] as int) + 1;
    // Format: YYMMDD-#### (e.g., 251209-0001)
    return '$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  Future<int> insertOrder(Order order) async {
    final db = await database;
    final orderMap = order.toMap();
    orderMap['items'] = jsonEncode(order.items.map((e) => e.toMap()).toList());

    // Ensure hybrid fields are set
    orderMap['isSynced'] = 0;
    orderMap['isDeleted'] = 0;
    if (!orderMap.containsKey('updatedAt') || orderMap['updatedAt'] == null) {
      orderMap['updatedAt'] = DateTime.now().toIso8601String();
    }

    return await db.insert('orders', orderMap);
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    final orderMap = order.toMap();
    orderMap['items'] = jsonEncode(order.items.map((e) => e.toMap()).toList());
    orderMap['isSynced'] = 0;
    orderMap['updatedAt'] = DateTime.now().toIso8601String();

    return await db.update(
      'orders',
      orderMap,
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(String id) async {
    final db = await database;
    // Soft Delete
    return await db.update(
      'orders',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<List<models.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'createdAt >= ? AND createdAt <= ? AND isDeleted = 0',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => models.Transaction.fromMap(map)).toList();
  }

  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    final map = transaction.toMap();
    map['isSynced'] = 0;
    map['updatedAt'] = DateTime.now().toIso8601String();
    map['isDeleted'] = 0;
    return await db.insert('transactions', map);
  }

  // Statistics and Reports
  Future<double> getTotalRevenue({DateTime? start, DateTime? end}) async {
    final db = await database;
    String query =
        "SELECT SUM(total) as total FROM orders WHERE status = 'completed' AND isDeleted = 0";
    List<Object?> args = [];

    if (start != null && end != null) {
      query += ' AND createdAt >= ? AND createdAt <= ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    final results = await db.rawQuery(query, args);
    return (results.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTotalOrders({DateTime? start, DateTime? end}) async {
    final db = await database;
    String query =
        "SELECT COUNT(*) as count FROM orders WHERE status = 'completed' AND isDeleted = 0";
    List<Object?> args = [];

    if (start != null && end != null) {
      query += ' AND createdAt >= ? AND createdAt <= ?';
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    final results = await db.rawQuery(query, args);
    return (results.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalProducts() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE isActive = 1 AND isDeleted = 0',
    );
    return (results.first['count'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getSalesTrend({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    final endDate = end ?? DateTime.now();
    final startDate = start ?? endDate.subtract(const Duration(days: 7));

    final results = await db.rawQuery(
      '''
      SELECT
        DATE(createdAt) as date,
        SUM(total) as total
      FROM orders
      WHERE status = 'completed'
        AND isDeleted = 0
        AND createdAt >= ?
        AND createdAt <= ?
      GROUP BY DATE(createdAt)
      ORDER BY date ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results;
  }

  Future<List<Map<String, dynamic>>> getHourlySalesTrend(DateTime date) async {
    final db = await database;

    // Start and End of the specific day
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final results = await db.rawQuery(
      '''
      SELECT
        strftime('%H', createdAt) as hour,
        SUM(total) as total
      FROM orders
      WHERE status = 'completed'
        AND isDeleted = 0
        AND createdAt >= ?
        AND createdAt <= ?
      GROUP BY strftime('%H', createdAt)
      ORDER BY hour ASC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return results;
  }

  Future<List<Map<String, dynamic>>> getTopProducts({
    int limit = 5,
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;

    String dateFilter = "";
    List<Object?> args = [];

    if (start != null && end != null) {
      dateFilter = "AND orders.createdAt >= ? AND orders.createdAt <= ?";
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    // Add limit to args
    args.add(limit);

    final results = await db.rawQuery('''
      SELECT
        p.name,
        SUM(json_extract(item.value, '\$.quantity')) as totalSold,
        SUM(json_extract(item.value, '\$.quantity') * json_extract(item.value, '\$.price')) as totalRevenue
      FROM products p
      JOIN (
          SELECT value, status
          FROM orders, json_each(orders.items)
          WHERE orders.status = 'completed' AND orders.isDeleted = 0
          $dateFilter
      ) item ON p.id = json_extract(item.value, '\$.productId')
      WHERE p.isDeleted = 0
      GROUP BY p.id
      ORDER BY totalSold DESC
      LIMIT ?
    ''', args);

    return results;
  }

  Future<Map<String, int>> getOrderStats({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    String query =
        "SELECT status, COUNT(*) as count FROM orders WHERE isDeleted = 0";
    List<Object?> args = [];

    if (start != null && end != null) {
      query += " AND createdAt >= ? AND createdAt <= ?";
      args = [start.toIso8601String(), end.toIso8601String()];
    }

    query += " GROUP BY status";

    final results = await db.rawQuery(query, args);

    final stats = <String, int>{'completed': 0, 'pending': 0, 'cancelled': 0};

    for (var row in results) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      stats[status] = count;
    }

    return stats;
  }

  // Hybrid System Synchronization Methods

  // Get unsynced records
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'isSynced = 0');
  }

  // Mark records as synced
  Future<void> markAsSynced(String table, List<String> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(table, {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clears all transaction data (orders, order items, transactions)
  Future<Map<String, int>> clearAllTransactionData() async {
    final db = await database;

    final ordersDeleted = await db.delete('orders');
    final orderItemsDeleted = await db.delete('order_items');
    final transactionsDeleted = await db.delete('transactions');

    return {
      'orders': ordersDeleted,
      'orderItems': orderItemsDeleted,
      'transactions': transactionsDeleted,
    };
  }

  // ============================================
  // Shift Management Methods
  // ============================================

  Future<Shift> startShift(String userId, double startCash) async {
    final db = await database;
    final now = DateTime.now();

    // Check if user already has open shift
    final existingShift = await getActiveShift(userId);
    if (existingShift != null) {
      return existingShift;
    }

    final shift = Shift(
      userId: userId,
      startTime: now,
      startCash: startCash,
      status: 'open',
    );

    // Remove ID from map since it's autoincrement
    final shiftMap = shift.toMap();
    shiftMap.remove('id');

    final id = await db.insert('shifts', shiftMap);

    return shift.copyWith(id: id);
  }

  Future<Shift?> getActiveShift(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shifts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'open'],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Shift.fromMap(maps.first);
    }
    return null;
  }

  Future<Shift> endShift(int shiftId, double actualCash) async {
    final db = await database;
    final now = DateTime.now();

    // Get the shift to calculate expected cash
    final shiftMaps = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    if (shiftMaps.isEmpty) throw Exception('Shift not found');

    final shift = Shift.fromMap(shiftMaps.first);

    // Calculate expected cash: Start Cash + Cash Transactions during shift
    final expectedCash = await _calculateShiftExpectedCash(
      db,
      shift.startTime,
      now,
      shift.startCash,
      shift.userId,
    );

    await db.update(
      'shifts',
      {
        'end_time': now.toIso8601String(),
        'actual_cash': actualCash,
        'expected_cash': expectedCash,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );

    return shift.copyWith(
      endTime: now,
      actualCash: actualCash,
      expectedCash: expectedCash,
      status: 'closed',
    );
  }

  Future<double> _calculateShiftExpectedCash(
    Database db,
    DateTime start,
    DateTime end,
    double startCash,
    String userId,
  ) async {
    // Sum Cash Transactions
    // Note: We check specifically for 'cash' payment method
    // Also ensuring we check by cashierId (more robust than name) and exclude deleted transactions
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE cashierId = ? 
      AND createdAt >= ? 
      AND createdAt <= ?
      AND (lower(paymentMethod) = 'cash' OR lower(paymentMethod) = 'tunai')
      AND isDeleted = 0
    ''',
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    final totalSales = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return startCash + totalSales;
  }

  Future<Map<String, double>> getPaymentMethodStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT paymentMethod, SUM(amount) as total
      FROM transactions
      WHERE isDeleted = 0
      GROUP BY paymentMethod
    ''');

    final stats = <String, double>{};
    for (var row in result) {
      final method = row['paymentMethod'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      stats[method] = total;
    }
    return stats;
  }

  Future<List<Shift>> getAllShifts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.*, u.name as cashier_name
      FROM shifts s
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.start_time DESC
    ''');

    return result.map((map) => Shift.fromMap(map)).toList();
  }
}
