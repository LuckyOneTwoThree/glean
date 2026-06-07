/// 文章标签模型
/// 对应 PRD Section 3.2.5 article_tags 表
class ArticleTag {
  final String id;
  final String articleId;
  final String tag;

  const ArticleTag({
    required this.id,
    required this.articleId,
    required this.tag,
  });

  factory ArticleTag.fromMap(Map<String, dynamic> map) {
    return ArticleTag(
      id: map['id'] as String,
      articleId: map['article_id'] as String,
      tag: map['tag'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'article_id': articleId,
      'tag': tag,
    };
  }
}
