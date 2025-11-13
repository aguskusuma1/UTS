class NewsModel {
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? author;
  final String? content;
  final Source? source;

  NewsModel({
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.author,
    this.content,
    this.source,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      author: json['author'],
      content: json['content'],
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'author': author,
      'content': content,
      'source': source?.toJson(),
    };
  }

  String get formattedDate {
    if (publishedAt == null) return '';
    try {
      final date = DateTime.parse(publishedAt!);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return publishedAt ?? '';
    }
  }
}

class Source {
  final String? id;
  final String? name;

  Source({this.id, this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class NewsResponse {
  final String status;
  final int totalResults;
  final List<NewsModel> articles;

  NewsResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      status: json['status'] ?? '',
      totalResults: json['totalResults'] ?? 0,
      articles: (json['articles'] as List<dynamic>?)
              ?.map((article) => NewsModel.fromJson(article as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

