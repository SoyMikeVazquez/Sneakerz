class ServiceItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? type;

  ServiceItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.type,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    // Buscar nombre
    final name = json['nombre'] ??
        json['name'] ??
        json['titulo'] ??
        json['title'] ??
        json['servicio'] ??
        json['nombre_servicio'] ??
        json['service_name'] ??
        'Servicio';

    // Buscar descripción
    final description = json['descripcion_servicio'] ??
        json['descripcion'] ??
        json['description'] ??
        json['detalle'] ??
        json['detalles'];

    // Buscar precio
    final rawPrice = json['precio_servicio'] ??
        json['precio'] ??
        json['precio_base'] ??
        json['costo'] ??
        json['price'] ??
        json['amount'] ??
        json['tarifa'] ??
        0.0;
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    // Buscar imagen
    final imageUrl = json['foto_servicio'] ??
        json['foto'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['imagen'] ??
        json['url_imagen'] ??
        json['photo'] ??
        json['img'] ??
        json['image'];

    // Buscar tipo/categoría
    final type = json['tipo'] ?? json['type'] ?? json['categoria'] ?? json['category'];

    return ServiceItem(
      id: (json['id'] ?? '').toString(),
      name: name.toString(),
      description: description?.toString(),
      price: price,
      imageUrl: imageUrl?.toString(),
      type: type?.toString(),
    );
  }
}
