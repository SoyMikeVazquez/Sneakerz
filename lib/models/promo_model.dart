class PromoItem {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final DateTime? fechaInicio;
  final DateTime? fechaFinal;

  PromoItem({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.fechaInicio,
    this.fechaFinal,
  });

  factory PromoItem.fromJson(Map<String, dynamic> json) {
    final title = json['titulo_promo'] ??
        json['titulo'] ??
        json['title'] ??
        json['nombre'] ??
        'Promoción Especial';

    final description = json['descripcion_prom'] ??
        json['descripcion_promo'] ??
        json['descripcion'] ??
        json['description'];

    final imageUrl = json['imagen_promo'] ??
        json['imagen'] ??
        json['image_url'] ??
        json['image'] ??
        json['foto'] ??
        '';

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return PromoItem(
      id: (json['id'] ?? '').toString(),
      title: title.toString(),
      description: description?.toString(),
      imageUrl: imageUrl.toString(),
      fechaInicio: parseDate(json['fecha_inicio']),
      fechaFinal: parseDate(json['fecha_final']),
    );
  }
}
