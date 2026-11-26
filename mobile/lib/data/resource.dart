/// Tipos de contenido que puede devolver el catálogo de recursos.
///
/// El backend (o la API gratuita que se conecte más adelante) puede enviar
/// `kind` o `type` con alguno de estos valores.
enum ResourceKind { article, guide, exercise, audio }

class Resource {
  const Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.readMinutes,
    this.imageUrl,
    this.author,
    this.kind = ResourceKind.article,
    this.tags = const [],
    this.content,
    this.audioUrl,
    this.imageCaption,
    this.featured = false,
    this.clinical = false,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int readMinutes;
  final String? imageUrl;
  final String? author;
  final ResourceKind kind;
  final List<String> tags;
  final String? content;
  final String? audioUrl;

  /// Texto que aparece sobre la fotografía (ej. "Neurobiología Aplicada").
  final String? imageCaption;

  /// Si es true, se muestra como la recomendación principal del día.
  final bool featured;

  /// Contenido revisado por profesionales de la salud mental.
  final bool clinical;

  /// Reservado para una futura monetización.
  final bool isPremium;

  bool get isArticle => kind == ResourceKind.article;
  bool get isReadable => content != null && content!.trim().isNotEmpty;

  String get kindLabel {
    switch (kind) {
      case ResourceKind.article:
        return '$readMinutes min de lectura';
      case ResourceKind.guide:
        return '$readMinutes min · Guía interactiva';
      case ResourceKind.exercise:
        return '$readMinutes min · Ejercicio guiado';
      case ResourceKind.audio:
        return '$readMinutes min · Audio guiado';
    }
  }

  /// Lectura tolerante: acepta varias formas de nombrar los campos para que
  /// cualquier API gratuita se pueda adaptar sin romper la pantalla.
  factory Resource.fromJson(Map<String, dynamic> json) {
    final rawKind = (json['kind'] ?? json['type'] ?? '').toString().toLowerCase();
    final tags = (json['tags'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const <String>[];

    return Resource(
      id: (json['id'] ?? json['resourceId'] ?? json['slug'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description:
          (json['description'] ?? json['summary'] ?? json['excerpt'] ?? '')
              .toString(),
      category: (json['category'] ?? json['topic'] ?? 'Bienestar').toString(),
      readMinutes: _parseMinutes(
        json['readMinutes'] ?? json['durationMinutes'] ?? json['minutes'],
      ),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['thumbnail'])?.toString(),
      author: (json['author'] ?? json['byline'])?.toString(),
      kind: _parseKind(rawKind, tags),
      tags: tags,
      content: (json['content'] ?? json['body'] ?? json['html'])?.toString(),
      audioUrl: (json['audioUrl'] ?? json['audio'])?.toString(),
      imageCaption:
          (json['imageCaption'] ?? json['category'] ?? json['topic'])?.toString(),
      featured: json['featured'] == true,
      clinical: json['clinical'] == true || json['reviewed'] == true,
      isPremium: json['isPremium'] == true,
    );
  }

  static ResourceKind _parseKind(String raw, List<String> tags) {
    switch (raw) {
      case 'guide':
      case 'guia':
      case 'guía':
        return ResourceKind.guide;
      case 'exercise':
      case 'ejercicio':
      case 'breathing':
      case 'meditation':
        return ResourceKind.exercise;
      case 'audio':
      case 'podcast':
        return ResourceKind.audio;
      case 'article':
      case 'articulo':
      case 'artículo':
        return ResourceKind.article;
    }
    if (tags.contains('audio')) return ResourceKind.audio;
    if (tags.contains('guia') || tags.contains('guía')) return ResourceKind.guide;
    return ResourceKind.article;
  }

  static int _parseMinutes(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    final text = value?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(text);
    return match == null ? 5 : int.tryParse(match.group(0)!) ?? 5;
  }
}
