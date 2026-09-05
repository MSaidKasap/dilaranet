class Post {
  final int id;
  final String date;
  final String dateGmt;
  final Map<String, dynamic> guid;
  final String modified;
  final String modifiedGmt;
  final String slug;
  final String status;
  final String type;
  final String link;
  final Map<String, dynamic> title;
  final Map<String, dynamic> content;
  final Map<String, dynamic> excerpt;
  final int author;
  final int featuredMedia;
  final String commentStatus;
  final String pingStatus;
  final bool sticky;
  final String template;
  final String format;
  final Map<String, dynamic> meta;
  final List<dynamic> categories;
  final List<dynamic> tags;
  final List<dynamic> classList;
  final String jetpackFeaturedMediaUrl;
  final Map<String, dynamic> custom;
  final Map<String, dynamic> links;

  Post({
    required this.id,
    required this.date,
    required this.dateGmt,
    required this.guid,
    required this.modified,
    required this.modifiedGmt,
    required this.slug,
    required this.status,
    required this.type,
    required this.link,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.author,
    required this.featuredMedia,
    required this.commentStatus,
    required this.pingStatus,
    required this.sticky,
    required this.template,
    required this.format,
    required this.meta,
    required this.categories,
    required this.tags,
    required this.classList,
    required this.jetpackFeaturedMediaUrl,
    required this.custom,
    required this.links,
  });

  // JSON verisinden Post nesnesi oluşturan factory constructor
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      dateGmt: json['date_gmt'] ?? '',
      guid: json['guid'] ?? {},
      modified: json['modified'] ?? '',
      modifiedGmt: json['modified_gmt'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      title: json['title'] ?? {},
      content: json['content'] ?? {},
      excerpt: json['excerpt'] ?? {},
      author: json['author'] ?? 0,
      featuredMedia: json['featured_media'] ?? 0,
      commentStatus: json['comment_status'] ?? '',
      pingStatus: json['ping_status'] ?? '',
      sticky: json['sticky'] ?? false,
      template: json['template'] ?? '',
      format: json['format'] ?? '',
      meta: json['meta'] ?? {},
      categories: json['categories'] ?? [],
      tags: json['tags'] ?? [],
      classList: json['class_list'] ?? [],
      jetpackFeaturedMediaUrl: json['jetpack_featured_media_url'] ?? '',
      custom: json['custom'] ?? {},
      links: json['_links'] ?? {},
    );
  }

  // Post nesnesini JSON formatına dönüştüren metod
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'date_gmt': dateGmt,
      'guid': guid,
      'modified': modified,
      'modified_gmt': modifiedGmt,
      'slug': slug,
      'status': status,
      'type': type,
      'link': link,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'author': author,
      'featured_media': featuredMedia,
      'comment_status': commentStatus,
      'ping_status': pingStatus,
      'sticky': sticky,
      'template': template,
      'format': format,
      'meta': meta,
      'categories': categories,
      'tags': tags,
      'class_list': classList,
      'jetpack_featured_media_url': jetpackFeaturedMediaUrl,
      'custom': custom,
      '_links': links,
    };
  }

  // Opsiyonel: Başlık, içerik ve özet gibi alanların metin değerlerini doğrudan almak için getter metodları
  String get titleText => title['rendered'] ?? '';
  String get contentText => content['rendered'] ?? '';
  String get excerptText => excerpt['rendered'] ?? '';
}
