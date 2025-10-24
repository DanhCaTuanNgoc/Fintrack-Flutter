class Transaction {
  final int? id;
  final double amount;
  final String note;
  final DateTime date;
  final String type;
  final int? categoryId;
  final int bookId;
  final int userId;
  final String? imagePath;

  Transaction({
    this.id,
    required this.amount,
    required this.note,
    DateTime? date,
    required this.type,
    required this.categoryId,
    required this.bookId,
    required this.userId,
    this.imagePath,
  }) : date = date ?? DateTime.now();

  Transaction copyWith({
    int? id,
    double? amount,
    String? note,
    DateTime? date,
    String? type,
    int? categoryId,
    int? bookId,
    int? userId,
    String? imagePath,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'type': type,
      'category_id': categoryId,
      'book_id': bookId,
      'user_id': userId,
      'image_path': imagePath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      note: map['note'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      categoryId: map['category_id'],
      bookId: map['book_id'],
      userId: map['user_id'],
      imagePath: map['image_path'],
    );
  }
}
