import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int? id;
  final int? remoteId;
  final int? categoryId;
  final String? barcode;
  final String sku;
  final String name;
  final String? description;
  final String? image;
  final String? imageUrl;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double? memberPrice;
  final int stock;
  final int minStock;
  final bool isActive;

  const Product({
    this.id,
    this.remoteId,
    this.categoryId,
    this.barcode,
    required this.sku,
    required this.name,
    this.description,
    this.image,
    this.imageUrl,
    this.unit = 'pcs',
    this.costPrice = 0,
    required this.sellingPrice,
    this.memberPrice,
    this.stock = 0,
    this.minStock = 5,
    this.isActive = true,
  });

  double getEffectivePrice(bool isMember) {
    if (isMember && memberPrice != null && memberPrice! > 0) {
      return memberPrice!;
    }
    return sellingPrice;
  }

  bool get isLowStock => stock <= minStock;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'remote_id': remoteId,
      'category_id': categoryId,
      'barcode': barcode,
      'sku': sku,
      'name': name,
      'description': description,
      'image': image,
      'image_url': imageUrl,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'member_price': memberPrice,
      'stock': stock,
      'min_stock': minStock,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      categoryId: map['category_id'] as int?,
      barcode: map['barcode'] as String?,
      sku: (map['sku'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      image: map['image'] as String?,
      imageUrl: map['image_url'] as String?,
      unit: (map['unit'] as String?) ?? 'pcs',
      costPrice: ((map['cost_price'] ?? 0) as num).toDouble(),
      sellingPrice: ((map['selling_price'] ?? 0) as num).toDouble(),
      memberPrice: map['member_price'] != null ? (map['member_price'] as num).toDouble() : null,
      stock: (map['stock'] ?? 0) as int,
      minStock: (map['min_stock'] ?? 5) as int,
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
    );
  }

  factory Product.fromRemoteJson(Map<String, dynamic> json) {
    return Product(
      remoteId: json['id'] as int?,
      categoryId: json['category_id'] as int?,
      barcode: json['barcode'] as String?,
      sku: (json['sku'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      unit: (json['unit'] as String?) ?? 'pcs',
      costPrice: ((json['cost_price'] ?? 0) as num).toDouble(),
      sellingPrice: ((json['selling_price'] ?? 0) as num).toDouble(),
      memberPrice: json['member_price'] != null ? (json['member_price'] as num).toDouble() : null,
      stock: (json['stock'] ?? 0) as int,
      minStock: (json['min_stock'] ?? 5) as int,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
    );
  }

  Product copyWith({
    int? id,
    int? remoteId,
    int? categoryId,
    String? barcode,
    String? sku,
    String? name,
    String? description,
    String? image,
    String? imageUrl,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    double? memberPrice,
    int? stock,
    int? minStock,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      memberPrice: memberPrice ?? this.memberPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, remoteId, sku, name, sellingPrice, stock, image, imageUrl];
}
