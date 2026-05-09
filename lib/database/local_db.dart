import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/web.dart';

part 'local_db.g.dart';

class LocalProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get stockQuantity => integer()();
  IntColumn get minStock => integer()();
  TextColumn get barcode => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class LocalSales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class LocalSaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localSaleId => integer().references(LocalSales, #id)();
  TextColumn get productId => text().nullable()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get priceAtSale => real()();
  RealColumn get costPriceAtSale => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real()();
}

@DriftDatabase(tables: [LocalProducts, LocalSales, LocalSaleItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(
    kIsWeb 
      ? WebDatabase.withStorage(DriftWebStorage.indexedDb('quickinvent_db'))
      : driftDatabase(name: 'quickinvent_db')
  );

  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localSaleItems);
      }
    },
  );
}

final localDbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
