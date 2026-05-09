// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<int> stockQuantity = GeneratedColumn<int>(
      'stock_quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minStockMeta =
      const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<int> minStock = GeneratedColumn<int>(
      'min_stock', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        name,
        price,
        stockQuantity,
        minStock,
        barcode,
        categoryId,
        imageUrl,
        costPrice,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(Insertable<LocalProduct> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stock_quantity']!, _stockQuantityMeta));
    } else if (isInserting) {
      context.missing(_stockQuantityMeta);
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta,
          minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    } else if (isInserting) {
      context.missing(_minStockMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_quantity'])!,
      minStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_stock'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final int id;
  final String? remoteId;
  final String name;
  final double price;
  final int stockQuantity;
  final int minStock;
  final String? barcode;
  final int? categoryId;
  final String? imageUrl;
  final double costPrice;
  final bool isActive;
  const LocalProduct(
      {required this.id,
      this.remoteId,
      required this.name,
      required this.price,
      required this.stockQuantity,
      required this.minStock,
      this.barcode,
      this.categoryId,
      this.imageUrl,
      required this.costPrice,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['stock_quantity'] = Variable<int>(stockQuantity);
    map['min_stock'] = Variable<int>(minStock);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['cost_price'] = Variable<double>(costPrice);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      price: Value(price),
      stockQuantity: Value(stockQuantity),
      minStock: Value(minStock),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      costPrice: Value(costPrice),
      isActive: Value(isActive),
    );
  }

  factory LocalProduct.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      stockQuantity: serializer.fromJson<int>(json['stockQuantity']),
      minStock: serializer.fromJson<int>(json['minStock']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'stockQuantity': serializer.toJson<int>(stockQuantity),
      'minStock': serializer.toJson<int>(minStock),
      'barcode': serializer.toJson<String?>(barcode),
      'categoryId': serializer.toJson<int?>(categoryId),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'costPrice': serializer.toJson<double>(costPrice),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalProduct copyWith(
          {int? id,
          Value<String?> remoteId = const Value.absent(),
          String? name,
          double? price,
          int? stockQuantity,
          int? minStock,
          Value<String?> barcode = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          double? costPrice,
          bool? isActive}) =>
      LocalProduct(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        name: name ?? this.name,
        price: price ?? this.price,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minStock: minStock ?? this.minStock,
        barcode: barcode.present ? barcode.value : this.barcode,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        costPrice: costPrice ?? this.costPrice,
        isActive: isActive ?? this.isActive,
      );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('costPrice: $costPrice, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remoteId, name, price, stockQuantity,
      minStock, barcode, categoryId, imageUrl, costPrice, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.price == this.price &&
          other.stockQuantity == this.stockQuantity &&
          other.minStock == this.minStock &&
          other.barcode == this.barcode &&
          other.categoryId == this.categoryId &&
          other.imageUrl == this.imageUrl &&
          other.costPrice == this.costPrice &&
          other.isActive == this.isActive);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> name;
  final Value<double> price;
  final Value<int> stockQuantity;
  final Value<int> minStock;
  final Value<String?> barcode;
  final Value<int?> categoryId;
  final Value<String?> imageUrl;
  final Value<double> costPrice;
  final Value<bool> isActive;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStock = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    required double price,
    required int stockQuantity,
    required int minStock,
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.isActive = const Value.absent(),
  })  : name = Value(name),
        price = Value(price),
        stockQuantity = Value(stockQuantity),
        minStock = Value(minStock);
  static Insertable<LocalProduct> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<int>? stockQuantity,
    Expression<int>? minStock,
    Expression<String>? barcode,
    Expression<int>? categoryId,
    Expression<String>? imageUrl,
    Expression<double>? costPrice,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minStock != null) 'min_stock': minStock,
      if (barcode != null) 'barcode': barcode,
      if (categoryId != null) 'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (costPrice != null) 'cost_price': costPrice,
      if (isActive != null) 'is_active': isActive,
    });
  }

  LocalProductsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteId,
      Value<String>? name,
      Value<double>? price,
      Value<int>? stockQuantity,
      Value<int>? minStock,
      Value<String?>? barcode,
      Value<int?>? categoryId,
      Value<String?>? imageUrl,
      Value<double>? costPrice,
      Value<bool>? isActive}) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      costPrice: costPrice ?? this.costPrice,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<int>(stockQuantity.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<int>(minStock.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('costPrice: $costPrice, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, LocalSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, remoteId, totalAmount, paymentMethod, createdAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }
}

class LocalSale extends DataClass implements Insertable<LocalSale> {
  final int id;
  final String? remoteId;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final bool isSynced;
  const LocalSale(
      {required this.id,
      this.remoteId,
      required this.totalAmount,
      required this.paymentMethod,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      totalAmount: Value(totalAmount),
      paymentMethod: Value(paymentMethod),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalSale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSale(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalSale copyWith(
          {int? id,
          Value<String?> remoteId = const Value.absent(),
          double? totalAmount,
          String? paymentMethod,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalSale(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalSale copyWithCompanion(LocalSalesCompanion data) {
    return LocalSale(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSale(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, remoteId, totalAmount, paymentMethod, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSale &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.totalAmount == this.totalAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalSalesCompanion extends UpdateCompanion<LocalSale> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<double> totalAmount;
  final Value<String> paymentMethod;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  const LocalSalesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required double totalAmount,
    required String paymentMethod,
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
  })  : totalAmount = Value(totalAmount),
        paymentMethod = Value(paymentMethod);
  static Insertable<LocalSale> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<double>? totalAmount,
    Expression<String>? paymentMethod,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  LocalSalesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteId,
      Value<double>? totalAmount,
      Value<String>? paymentMethod,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced}) {
    return LocalSalesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $LocalSaleItemsTable extends LocalSaleItems
    with TableInfo<$LocalSaleItemsTable, LocalSaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _localSaleIdMeta =
      const VerificationMeta('localSaleId');
  @override
  late final GeneratedColumn<int> localSaleId = GeneratedColumn<int>(
      'local_sale_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_sales (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _priceAtSaleMeta =
      const VerificationMeta('priceAtSale');
  @override
  late final GeneratedColumn<double> priceAtSale = GeneratedColumn<double>(
      'price_at_sale', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costPriceAtSaleMeta =
      const VerificationMeta('costPriceAtSale');
  @override
  late final GeneratedColumn<double> costPriceAtSale = GeneratedColumn<double>(
      'cost_price_at_sale', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localSaleId,
        productId,
        productName,
        quantity,
        priceAtSale,
        costPriceAtSale,
        subtotal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sale_items';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSaleItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_sale_id')) {
      context.handle(
          _localSaleIdMeta,
          localSaleId.isAcceptableOrUnknown(
              data['local_sale_id']!, _localSaleIdMeta));
    } else if (isInserting) {
      context.missing(_localSaleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price_at_sale')) {
      context.handle(
          _priceAtSaleMeta,
          priceAtSale.isAcceptableOrUnknown(
              data['price_at_sale']!, _priceAtSaleMeta));
    } else if (isInserting) {
      context.missing(_priceAtSaleMeta);
    }
    if (data.containsKey('cost_price_at_sale')) {
      context.handle(
          _costPriceAtSaleMeta,
          costPriceAtSale.isAcceptableOrUnknown(
              data['cost_price_at_sale']!, _costPriceAtSaleMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSaleItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      localSaleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_sale_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      priceAtSale: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_at_sale'])!,
      costPriceAtSale: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}cost_price_at_sale'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
    );
  }

  @override
  $LocalSaleItemsTable createAlias(String alias) {
    return $LocalSaleItemsTable(attachedDatabase, alias);
  }
}

class LocalSaleItem extends DataClass implements Insertable<LocalSaleItem> {
  final int id;
  final int localSaleId;
  final String? productId;
  final String productName;
  final int quantity;
  final double priceAtSale;
  final double costPriceAtSale;
  final double subtotal;
  const LocalSaleItem(
      {required this.id,
      required this.localSaleId,
      this.productId,
      required this.productName,
      required this.quantity,
      required this.priceAtSale,
      required this.costPriceAtSale,
      required this.subtotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_sale_id'] = Variable<int>(localSaleId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['price_at_sale'] = Variable<double>(priceAtSale);
    map['cost_price_at_sale'] = Variable<double>(costPriceAtSale);
    map['subtotal'] = Variable<double>(subtotal);
    return map;
  }

  LocalSaleItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalSaleItemsCompanion(
      id: Value(id),
      localSaleId: Value(localSaleId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      priceAtSale: Value(priceAtSale),
      costPriceAtSale: Value(costPriceAtSale),
      subtotal: Value(subtotal),
    );
  }

  factory LocalSaleItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSaleItem(
      id: serializer.fromJson<int>(json['id']),
      localSaleId: serializer.fromJson<int>(json['localSaleId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      priceAtSale: serializer.fromJson<double>(json['priceAtSale']),
      costPriceAtSale: serializer.fromJson<double>(json['costPriceAtSale']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localSaleId': serializer.toJson<int>(localSaleId),
      'productId': serializer.toJson<String?>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'priceAtSale': serializer.toJson<double>(priceAtSale),
      'costPriceAtSale': serializer.toJson<double>(costPriceAtSale),
      'subtotal': serializer.toJson<double>(subtotal),
    };
  }

  LocalSaleItem copyWith(
          {int? id,
          int? localSaleId,
          Value<String?> productId = const Value.absent(),
          String? productName,
          int? quantity,
          double? priceAtSale,
          double? costPriceAtSale,
          double? subtotal}) =>
      LocalSaleItem(
        id: id ?? this.id,
        localSaleId: localSaleId ?? this.localSaleId,
        productId: productId.present ? productId.value : this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        priceAtSale: priceAtSale ?? this.priceAtSale,
        costPriceAtSale: costPriceAtSale ?? this.costPriceAtSale,
        subtotal: subtotal ?? this.subtotal,
      );
  LocalSaleItem copyWithCompanion(LocalSaleItemsCompanion data) {
    return LocalSaleItem(
      id: data.id.present ? data.id.value : this.id,
      localSaleId:
          data.localSaleId.present ? data.localSaleId.value : this.localSaleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      priceAtSale:
          data.priceAtSale.present ? data.priceAtSale.value : this.priceAtSale,
      costPriceAtSale: data.costPriceAtSale.present
          ? data.costPriceAtSale.value
          : this.costPriceAtSale,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItem(')
          ..write('id: $id, ')
          ..write('localSaleId: $localSaleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('priceAtSale: $priceAtSale, ')
          ..write('costPriceAtSale: $costPriceAtSale, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, localSaleId, productId, productName,
      quantity, priceAtSale, costPriceAtSale, subtotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSaleItem &&
          other.id == this.id &&
          other.localSaleId == this.localSaleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.priceAtSale == this.priceAtSale &&
          other.costPriceAtSale == this.costPriceAtSale &&
          other.subtotal == this.subtotal);
}

class LocalSaleItemsCompanion extends UpdateCompanion<LocalSaleItem> {
  final Value<int> id;
  final Value<int> localSaleId;
  final Value<String?> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<double> priceAtSale;
  final Value<double> costPriceAtSale;
  final Value<double> subtotal;
  const LocalSaleItemsCompanion({
    this.id = const Value.absent(),
    this.localSaleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.priceAtSale = const Value.absent(),
    this.costPriceAtSale = const Value.absent(),
    this.subtotal = const Value.absent(),
  });
  LocalSaleItemsCompanion.insert({
    this.id = const Value.absent(),
    required int localSaleId,
    this.productId = const Value.absent(),
    required String productName,
    required int quantity,
    required double priceAtSale,
    this.costPriceAtSale = const Value.absent(),
    required double subtotal,
  })  : localSaleId = Value(localSaleId),
        productName = Value(productName),
        quantity = Value(quantity),
        priceAtSale = Value(priceAtSale),
        subtotal = Value(subtotal);
  static Insertable<LocalSaleItem> custom({
    Expression<int>? id,
    Expression<int>? localSaleId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<double>? priceAtSale,
    Expression<double>? costPriceAtSale,
    Expression<double>? subtotal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localSaleId != null) 'local_sale_id': localSaleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (priceAtSale != null) 'price_at_sale': priceAtSale,
      if (costPriceAtSale != null) 'cost_price_at_sale': costPriceAtSale,
      if (subtotal != null) 'subtotal': subtotal,
    });
  }

  LocalSaleItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? localSaleId,
      Value<String?>? productId,
      Value<String>? productName,
      Value<int>? quantity,
      Value<double>? priceAtSale,
      Value<double>? costPriceAtSale,
      Value<double>? subtotal}) {
    return LocalSaleItemsCompanion(
      id: id ?? this.id,
      localSaleId: localSaleId ?? this.localSaleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
      costPriceAtSale: costPriceAtSale ?? this.costPriceAtSale,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localSaleId.present) {
      map['local_sale_id'] = Variable<int>(localSaleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (priceAtSale.present) {
      map['price_at_sale'] = Variable<double>(priceAtSale.value);
    }
    if (costPriceAtSale.present) {
      map['cost_price_at_sale'] = Variable<double>(costPriceAtSale.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('localSaleId: $localSaleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('priceAtSale: $priceAtSale, ')
          ..write('costPriceAtSale: $costPriceAtSale, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $LocalSaleItemsTable localSaleItems = $LocalSaleItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localProducts, localSales, localSaleItems];
}

typedef $$LocalProductsTableCreateCompanionBuilder = LocalProductsCompanion
    Function({
  Value<int> id,
  Value<String?> remoteId,
  required String name,
  required double price,
  required int stockQuantity,
  required int minStock,
  Value<String?> barcode,
  Value<int?> categoryId,
  Value<String?> imageUrl,
  Value<double> costPrice,
  Value<bool> isActive,
});
typedef $$LocalProductsTableUpdateCompanionBuilder = LocalProductsCompanion
    Function({
  Value<int> id,
  Value<String?> remoteId,
  Value<String> name,
  Value<double> price,
  Value<int> stockQuantity,
  Value<int> minStock,
  Value<String?> barcode,
  Value<int?> categoryId,
  Value<String?> imageUrl,
  Value<double> costPrice,
  Value<bool> isActive,
});

class $$LocalProductsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => column);

  GeneratedColumn<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalProductsTable,
    LocalProduct,
    $$LocalProductsTableFilterComposer,
    $$LocalProductsTableOrderingComposer,
    $$LocalProductsTableAnnotationComposer,
    $$LocalProductsTableCreateCompanionBuilder,
    $$LocalProductsTableUpdateCompanionBuilder,
    (
      LocalProduct,
      BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>
    ),
    LocalProduct,
    PrefetchHooks Function()> {
  $$LocalProductsTableTableManager(_$AppDatabase db, $LocalProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<int> stockQuantity = const Value.absent(),
            Value<int> minStock = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              LocalProductsCompanion(
            id: id,
            remoteId: remoteId,
            name: name,
            price: price,
            stockQuantity: stockQuantity,
            minStock: minStock,
            barcode: barcode,
            categoryId: categoryId,
            imageUrl: imageUrl,
            costPrice: costPrice,
            isActive: isActive,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            required String name,
            required double price,
            required int stockQuantity,
            required int minStock,
            Value<String?> barcode = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
          }) =>
              LocalProductsCompanion.insert(
            id: id,
            remoteId: remoteId,
            name: name,
            price: price,
            stockQuantity: stockQuantity,
            minStock: minStock,
            barcode: barcode,
            categoryId: categoryId,
            imageUrl: imageUrl,
            costPrice: costPrice,
            isActive: isActive,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalProductsTable,
    LocalProduct,
    $$LocalProductsTableFilterComposer,
    $$LocalProductsTableOrderingComposer,
    $$LocalProductsTableAnnotationComposer,
    $$LocalProductsTableCreateCompanionBuilder,
    $$LocalProductsTableUpdateCompanionBuilder,
    (
      LocalProduct,
      BaseReferences<_$AppDatabase, $LocalProductsTable, LocalProduct>
    ),
    LocalProduct,
    PrefetchHooks Function()>;
typedef $$LocalSalesTableCreateCompanionBuilder = LocalSalesCompanion Function({
  Value<int> id,
  Value<String?> remoteId,
  required double totalAmount,
  required String paymentMethod,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
});
typedef $$LocalSalesTableUpdateCompanionBuilder = LocalSalesCompanion Function({
  Value<int> id,
  Value<String?> remoteId,
  Value<double> totalAmount,
  Value<String> paymentMethod,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
});

final class $$LocalSalesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale> {
  $$LocalSalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalSaleItemsTable, List<LocalSaleItem>>
      _localSaleItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localSaleItems,
              aliasName: $_aliasNameGenerator(
                  db.localSales.id, db.localSaleItems.localSaleId));

  $$LocalSaleItemsTableProcessedTableManager get localSaleItemsRefs {
    final manager = $$LocalSaleItemsTableTableManager($_db, $_db.localSaleItems)
        .filter((f) => f.localSaleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_localSaleItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  Expression<bool> localSaleItemsRefs(
      Expression<bool> Function($$LocalSaleItemsTableFilterComposer f) f) {
    final $$LocalSaleItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localSaleItems,
        getReferencedColumn: (t) => t.localSaleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSaleItemsTableFilterComposer(
              $db: $db,
              $table: $db.localSaleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  Expression<T> localSaleItemsRefs<T extends Object>(
      Expression<T> Function($$LocalSaleItemsTableAnnotationComposer a) f) {
    final $$LocalSaleItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localSaleItems,
        getReferencedColumn: (t) => t.localSaleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSaleItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.localSaleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalSalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSalesTable,
    LocalSale,
    $$LocalSalesTableFilterComposer,
    $$LocalSalesTableOrderingComposer,
    $$LocalSalesTableAnnotationComposer,
    $$LocalSalesTableCreateCompanionBuilder,
    $$LocalSalesTableUpdateCompanionBuilder,
    (LocalSale, $$LocalSalesTableReferences),
    LocalSale,
    PrefetchHooks Function({bool localSaleItemsRefs})> {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
          }) =>
              LocalSalesCompanion(
            id: id,
            remoteId: remoteId,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            isSynced: isSynced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            required double totalAmount,
            required String paymentMethod,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
          }) =>
              LocalSalesCompanion.insert(
            id: id,
            remoteId: remoteId,
            totalAmount: totalAmount,
            paymentMethod: paymentMethod,
            createdAt: createdAt,
            isSynced: isSynced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalSalesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localSaleItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localSaleItemsRefs) db.localSaleItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localSaleItemsRefs)
                    await $_getPrefetchedData<LocalSale, $LocalSalesTable,
                            LocalSaleItem>(
                        currentTable: table,
                        referencedTable: $$LocalSalesTableReferences
                            ._localSaleItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalSalesTableReferences(db, table, p0)
                                .localSaleItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.localSaleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalSalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSalesTable,
    LocalSale,
    $$LocalSalesTableFilterComposer,
    $$LocalSalesTableOrderingComposer,
    $$LocalSalesTableAnnotationComposer,
    $$LocalSalesTableCreateCompanionBuilder,
    $$LocalSalesTableUpdateCompanionBuilder,
    (LocalSale, $$LocalSalesTableReferences),
    LocalSale,
    PrefetchHooks Function({bool localSaleItemsRefs})>;
typedef $$LocalSaleItemsTableCreateCompanionBuilder = LocalSaleItemsCompanion
    Function({
  Value<int> id,
  required int localSaleId,
  Value<String?> productId,
  required String productName,
  required int quantity,
  required double priceAtSale,
  Value<double> costPriceAtSale,
  required double subtotal,
});
typedef $$LocalSaleItemsTableUpdateCompanionBuilder = LocalSaleItemsCompanion
    Function({
  Value<int> id,
  Value<int> localSaleId,
  Value<String?> productId,
  Value<String> productName,
  Value<int> quantity,
  Value<double> priceAtSale,
  Value<double> costPriceAtSale,
  Value<double> subtotal,
});

final class $$LocalSaleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalSaleItemsTable, LocalSaleItem> {
  $$LocalSaleItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalSalesTable _localSaleIdTable(_$AppDatabase db) =>
      db.localSales.createAlias($_aliasNameGenerator(
          db.localSaleItems.localSaleId, db.localSales.id));

  $$LocalSalesTableProcessedTableManager get localSaleId {
    final $_column = $_itemColumn<int>('local_sale_id')!;

    final manager = $$LocalSalesTableTableManager($_db, $_db.localSales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localSaleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalSaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceAtSale => $composableBuilder(
      column: $table.priceAtSale, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPriceAtSale => $composableBuilder(
      column: $table.costPriceAtSale,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  $$LocalSalesTableFilterComposer get localSaleId {
    final $$LocalSalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localSaleId,
        referencedTable: $db.localSales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSalesTableFilterComposer(
              $db: $db,
              $table: $db.localSales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceAtSale => $composableBuilder(
      column: $table.priceAtSale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPriceAtSale => $composableBuilder(
      column: $table.costPriceAtSale,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  $$LocalSalesTableOrderingComposer get localSaleId {
    final $$LocalSalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localSaleId,
        referencedTable: $db.localSales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSalesTableOrderingComposer(
              $db: $db,
              $table: $db.localSales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSaleItemsTable> {
  $$LocalSaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get priceAtSale => $composableBuilder(
      column: $table.priceAtSale, builder: (column) => column);

  GeneratedColumn<double> get costPriceAtSale => $composableBuilder(
      column: $table.costPriceAtSale, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  $$LocalSalesTableAnnotationComposer get localSaleId {
    final $$LocalSalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localSaleId,
        referencedTable: $db.localSales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSalesTableAnnotationComposer(
              $db: $db,
              $table: $db.localSales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSaleItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSaleItemsTable,
    LocalSaleItem,
    $$LocalSaleItemsTableFilterComposer,
    $$LocalSaleItemsTableOrderingComposer,
    $$LocalSaleItemsTableAnnotationComposer,
    $$LocalSaleItemsTableCreateCompanionBuilder,
    $$LocalSaleItemsTableUpdateCompanionBuilder,
    (LocalSaleItem, $$LocalSaleItemsTableReferences),
    LocalSaleItem,
    PrefetchHooks Function({bool localSaleId})> {
  $$LocalSaleItemsTableTableManager(
      _$AppDatabase db, $LocalSaleItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> localSaleId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> priceAtSale = const Value.absent(),
            Value<double> costPriceAtSale = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
          }) =>
              LocalSaleItemsCompanion(
            id: id,
            localSaleId: localSaleId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            priceAtSale: priceAtSale,
            costPriceAtSale: costPriceAtSale,
            subtotal: subtotal,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int localSaleId,
            Value<String?> productId = const Value.absent(),
            required String productName,
            required int quantity,
            required double priceAtSale,
            Value<double> costPriceAtSale = const Value.absent(),
            required double subtotal,
          }) =>
              LocalSaleItemsCompanion.insert(
            id: id,
            localSaleId: localSaleId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            priceAtSale: priceAtSale,
            costPriceAtSale: costPriceAtSale,
            subtotal: subtotal,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalSaleItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localSaleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (localSaleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.localSaleId,
                    referencedTable:
                        $$LocalSaleItemsTableReferences._localSaleIdTable(db),
                    referencedColumn: $$LocalSaleItemsTableReferences
                        ._localSaleIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalSaleItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSaleItemsTable,
    LocalSaleItem,
    $$LocalSaleItemsTableFilterComposer,
    $$LocalSaleItemsTableOrderingComposer,
    $$LocalSaleItemsTableAnnotationComposer,
    $$LocalSaleItemsTableCreateCompanionBuilder,
    $$LocalSaleItemsTableUpdateCompanionBuilder,
    (LocalSaleItem, $$LocalSaleItemsTableReferences),
    LocalSaleItem,
    PrefetchHooks Function({bool localSaleId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$LocalSaleItemsTableTableManager get localSaleItems =>
      $$LocalSaleItemsTableTableManager(_db, _db.localSaleItems);
}
