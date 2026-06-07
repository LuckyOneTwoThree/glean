import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/models.dart';
import 'database_service.dart';

/// 数据源管理服务
/// 对应 PRD 接口 FeedService
/// 含 RSS 连通性测试
class FeedService {
  final DatabaseService _db;
  static const _table = 'feeds';

  FeedService(this._db);

  /// 添加数据源
  Future<Feed> addFeed({
    required String url,
    required String type,
    String? category,
    String? name,
  }) async {
    final feed = Feed(
      id: _generateId(),
      name: name ?? Uri.parse(url).host,
      url: url,
      type: type,
      category: category,
      isDomestic: isDomesticUrl(url),
    );
    await _db.insert(_table, feed.toMap());
    return feed;
  }

  /// 删除数据源
  Future<void> removeFeed(String feedId) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [feedId]);
  }

  /// 切换启用状态（重新启用时同时重置错误状态）
  Future<void> toggleFeed(String feedId) async {
    final feeds = await _db.query(_table, where: 'id = ?', whereArgs: [feedId]);
    if (feeds.isEmpty) return;
    final feed = Feed.fromMap(feeds.first);
    final newEnabled = feed.isEnabled ? 0 : 1;
    final values = <String, dynamic>{'is_enabled': newEnabled};
    // 重新启用时重置错误状态
    if (newEnabled == 1) {
      values['fetch_error_count'] = 0;
      values['status'] = 'active';
    }
    await _db.update(_table, values, where: 'id = ?', whereArgs: [feedId]);
  }

  /// 获取所有数据源
  Future<List<Feed>> getAllFeeds() async {
    final maps = await _db.query(_table, orderBy: 'name ASC');
    return maps.map((m) => Feed.fromMap(m)).toList();
  }

  /// 获取已启用的数据源
  Future<List<Feed>> getEnabledFeeds() async {
    final maps = await _db.query(_table, where: 'is_enabled = 1');
    return maps.map((m) => Feed.fromMap(m)).toList();
  }

  /// 更新采集时间
  Future<void> updateLastFetched(String feedId, {int? errorCount}) async {
    final values = <String, dynamic>{
      'last_fetched_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (errorCount != null) {
      values['fetch_error_count'] = errorCount;
    }
    await _db.update(_table, values, where: 'id = ?', whereArgs: [feedId]);
  }

  String _generateId() => 'f${DateTime.now().millisecondsSinceEpoch}';

  /// 更新源状态（同时更新 is_enabled 和 status）
  Future<void> updateStatus(String feedId, String status) async {
    final isEnabled = status == 'active' ? 1 : 0;
    await _db.update(
      _table,
      {'status': status, 'is_enabled': isEnabled},
      where: 'id = ?',
      whereArgs: [feedId],
    );
  }

  /// 重置错误计数（用户手动恢复时调用）
  Future<void> resetErrorCount(String feedId) async {
    await _db.update(
      _table,
      {'fetch_error_count': 0, 'status': 'active'},
      where: 'id = ?',
      whereArgs: [feedId],
    );
  }

  /// 获取异常源列表
  Future<List<Feed>> getErrorFeeds() async {
    final maps = await _db.query(_table, where: 'status = ?', whereArgs: ['error']);
    return maps.map((m) => Feed.fromMap(m)).toList();
  }

  /// 测试 RSS 源连通性
  /// 返回 null 表示成功，否则返回错误信息
  Future<String?> testFeedUrl(String url) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.headers = {
        'User-Agent': 'Glean/1.0 (RSS Reader)',
      };

      final response = await dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.data == null || response.data!.isEmpty) {
        return '返回内容为空';
      }

      // 尝试解析 XML
      try {
        final document = XmlDocument.parse(response.data!);
        final hasItems = document.findAllElements('item').isNotEmpty ||
            document.findAllElements('entry').isNotEmpty;
        if (!hasItems) {
          return 'XML 格式有效但未找到文章条目';
        }
      } catch (e) {
        return '返回内容不是有效的 RSS/Atom XML';
      }

      return null; // 成功
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '连接超时';
        case DioExceptionType.connectionError:
          return '无法连接到服务器';
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          return '服务器返回错误 ($statusCode)';
        default:
          return '网络错误: ${e.message}';
      }
    } catch (e) {
      return '未知错误: $e';
    }
  }

  /// 根据URL判断是否国内源
  static bool isDomesticUrl(String sourceUrl) {
    final domesticDomains = [
      'qbitai.com', '36kr.com', 'infoq.cn', 'ifanr.com',
      'sspai.com', 'ithome.com', 'jiqizhixin.com', 'huxiu.com',
    ];
    return domesticDomains.any((d) => sourceUrl.contains(d));
  }
}
