import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import '../../utils/category_helper.dart';
import '../../utils/localization.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final path = join(appDocDir.path, filePath);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Bảng User
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        premium INTEGER DEFAULT 0
      )
    ''');

    // Bảng Books (Ví/Sổ chi tiêu)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL DEFAULT 0,
        user_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Bảng Wallets
    await db.execute("""
    CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nameBalance TEXT NOT NULL,
        walletBalance REAL DEFAULT 0,
        type Text,
        user_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES books (id) ON DELETE CASCADE
      )
    """);

    // Bảng Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        type TEXT CHECK(type IN ('income', 'expense'))
      )
    ''');

    // Bảng Transactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        type TEXT CHECK(type IN ('income', 'expense')),
        category_id INTEGER,
        book_id INTEGER,
        user_id INTEGER,
        image_path TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Bảng Periodic Invoices
    await db.execute('''
      CREATE TABLE IF NOT EXISTS periodic_invoices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        frequency TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        is_paid INTEGER NOT NULL,
        last_paid_date TEXT,
        next_due_date TEXT,
        book_id INTEGER,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE SET NULL
      )
    ''');

    // Bảng Notifications
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        time TEXT NOT NULL,
        is_read INTEGER NOT NULL,
        invoice_id TEXT,
        invoice_due_date TEXT,
        goal_id TEXT,
        item_name TEXT,
        amount TEXT,
        remaining_days INTEGER
      )
    ''');

    // Bảng Savings Goals
    await db.execute('''
    CREATE TABLE IF NOT EXISTS savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      type TEXT CHECK(type IN ('flexible', 'periodic')) NOT NULL,
      periodic_amount REAL,                         -- Chỉ dùng nếu type = periodic
      periodic_frequency TEXT CHECK(periodic_frequency IN ('daily', 'weekly', 'monthly')),
      started_date TIMESTAMP,                       -- Ngày bắt đầu tiết kiệm
      target_date TIMESTAMP,                        -- Ngày mong muốn đạt mục tiêu
      next_reminder_date TIMESTAMP,                -- Dùng để nhắc lần tiếp theo
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      is_active INTEGER DEFAULT 1
    )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          note TEXT,
          saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (goal_id) REFERENCES savings_goals(id) ON DELETE CASCADE
      );
    ''');

    // Bảng Recurring Bills
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        day_of_month INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        is_active INTEGER DEFAULT 1,
        book_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_paid_date TIMESTAMP,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    // Thêm một số category mặc định
    await _insertDefaultCategories(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Nâng cấp từ version 1 lên version 2
      // Tạo bảng notifications mới với schema mới
      await db.execute('DROP TABLE IF EXISTS notifications');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          time TEXT NOT NULL,
          is_read INTEGER NOT NULL,
          invoice_id TEXT,
          invoice_due_date TEXT,
          goal_id TEXT,
          item_name TEXT,
          amount TEXT,
          remaining_days INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN image_path TEXT');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = CategoryHelper.getDefaultCategoriesForDatabase();

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // CRUD operations cho Books
  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    return await db.insert('books', book);
  }

  Future<List<Map<String, dynamic>>> getBooksByUser(int userId) async {
    final db = await database;
    return await db.query('books', where: 'user_id = ?', whereArgs: [userId]);
  }

  // CRUD operations cho Wallets
  Future<int> insertWallet(Map<String, dynamic> wallet) async {
    final db = await database;
    return await db.insert('wallets', wallet);
  }

  Future<List<Map<String, dynamic>>> getWalletByUser(int userId) async {
    final db = await database;
    return await db.query('wallets', where: 'user_id = ?', whereArgs: [userId]);
  }

  // CRUD operations cho Categories
  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type]);
  }

  Future<List<Map<String, dynamic>>> getCategoriesById(int id) async {
    final db = await database;
    return await db.query('categories', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations cho Transactions
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByBook(int bookId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );
  }

  // Hiển thị tất cả dữ liệu trong database
  Future<void> showAllTables() async {
    final db = await database;
    final logger = Logger('DatabaseHelper');

    logger.info('\n=== DATABASE TABLES ===\n');
    // Hiển thị bảng Books
    logger.info('\n📚 BOOKS TABLE:');
    logger.info('----------------');
    final books = await db.query('books');
    for (var book in books) {
      logger.info('ID: ${book['id']}');
      logger.info('Name: ${book['name']}');
      logger.info('Description: ${book['description']}');
      logger.info('Balance: ${book['balance']}');
      logger.info('User ID: ${book['user_id']}');
      logger.info('Created at: ${book['created_at']}');
      logger.info('----------------');
    }

    // Hiển thị bảng Categories
    logger.info('\n🏷 CATEGORIES TABLE:');
    logger.info('----------------');
    final categories = await db.query('categories');
    for (var category in categories) {
      logger.info('ID: ${category['id']}');
      logger.info('Name: ${category['name']}');
      logger.info('Icon: ${category['icon']}');
      logger.info('Type: ${category['type']}');
      logger.info('----------------');
    }

    // Hiển thị bảng Transactions
    logger.info('\n💰 TRANSACTIONS TABLE:');
    logger.info('----------------');
    final transactions = await db.query('transactions');
    for (var transaction in transactions) {
      logger.info('ID: ${transaction['id']}');
      logger.info('Amount: ${transaction['amount']}');
      logger.info('Note: ${transaction['note']}');
      logger.info('Date: ${transaction['date']}');
      logger.info('Type: ${transaction['type']}');
      logger.info('Category ID: ${transaction['category_id']}');
      logger.info('Book ID: ${transaction['book_id']}');
      logger.info('User ID: ${transaction['user_id']}');
      logger.info('----------------');
    }

    // Hiển thị bảng Notifications
    logger.info('\n🔔 NOTIFICATIONS TABLE:');
    logger.info('----------------');
    final notifications = await db.query('notifications');
    for (var notification in notifications) {
      logger.info('ID: ${notification['id']}');
      logger.info('Title: ${notification['title']}');
      logger.info('Message: ${notification['message']}');
      logger.info('Time: ${notification['time']}');
      logger.info('Is Read: ${notification['is_read'] == 1 ? 'Yes' : 'No'}');
      logger.info('Invoice ID: ${notification['invoice_id']}');
      logger.info('Invoice Due Date: ${notification['invoice_due_date']}');
      logger.info('Goal ID: ${notification['goal_id']}');
      logger.info('----------------');
    }

    logger.info('\n=== END OF DATABASE ===\n');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  // Lấy toàn bộ danh sách mục tiêu tiết kiệm
  Future<List<Map<String, dynamic>>> getAllSavingsGoals() async {
    final db = await database;
    return await db.query('savings_goals', where: 'is_active = 1');
  }

  // Lấy toàn bộ danh sách mục tiêu tiết kiệm
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query('notifications');
  }

  // Cập nhật ngày nhắc nhở tiếp theo cho mục tiêu tiết kiệm
  Future<int> updateSavingsGoalNextReminder(
      int id, DateTime nextReminderDate) async {
    final db = await database;
    return await db.update(
      'savings_goals',
      {
        'next_reminder_date': nextReminderDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cập nhật tên categories khi ngôn ngữ thay đổi
  Future<void> updateCategoriesOnLanguageChange(AppLocalizations l10n) async {
    final db = await database;
    final defaultCategories = CategoryHelper.getDefaultCategories(l10n);

    for (var category in defaultCategories) {
      await db.update(
        'categories',
        {'name': category['name']},
        where: 'icon = ? AND type = ?',
        whereArgs: [category['icon'], category['type']],
      );
    }
  }
}
