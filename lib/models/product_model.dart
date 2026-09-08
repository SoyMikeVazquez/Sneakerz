class ProductItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;

  ProductItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final name = json['nombre_producto'] ??
        json['nombre'] ??
        json['name'] ??
        json['producto'] ??
        json['titulo'] ??
        json['title'] ??
        'Producto';

    final description = json['descripcion_producto'] ??
        json['descripcion'] ??
        json['description'] ??
        json['detalle'] ??
        json['detalles'];

    final rawPrice = json['precio_producto'] ??
        json['precio_unitario'] ??
        json['precio'] ??
        json['costo'] ??
        json['price'] ??
        json['amount'] ??
        0.0;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    final imageUrl = json['foto_producto'] ??
        json['foto'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['imagen'] ??
        json['url_imagen'] ??
        json['photo'] ??
        json['img'] ??
        json['image'];

    final category = json['categoria'] ??
        json['category'] ??
        json['unidad_medida'] ??
        json['tipo'];

    return ProductItem(
      id: (json['id'] ?? '').toString(),
      name: name.toString(),
      description: description?.toString(),
      price: price,
      imageUrl: imageUrl?.toString(),
      category: category?.toString(),
    );
  }
}
