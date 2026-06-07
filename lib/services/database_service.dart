import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/models.dart';

/// SQLite 数据库服务
/// 管理 Glean 应用的本地数据库
class DatabaseService {
  static const _dbName = 'glean.db';
  static const _dbVersion = 3;
  static Database? _db;
  static bool _ffiInitialized = false;

  /// 初始化 FFI（Windows/Linux/macOS 桌面端需要）
  static void initFFI() {
    if (_ffiInitialized) return;
    _ffiInitialized = true;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactoryOrNull = databaseFactoryFfi;
    }
  }

  /// 获取数据库实例（单例）
  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    initFFI();
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT UNIQUE NOT NULL,
        content TEXT,
        summary_one TEXT,
        summary_points TEXT,
        source_name TEXT NOT NULL,
        source_url TEXT,
        category TEXT,
        published_at INTEGER NOT NULL,
        fetched_at INTEGER NOT NULL,
        score_total REAL DEFAULT 0,
        score_credibility REAL DEFAULT 0,
        score_density REAL DEFAULT 0,
        score_mode TEXT DEFAULT 'local',
        is_read INTEGER DEFAULT 0,
        is_favorited INTEGER DEFAULT 0,
        is_fulltext INTEGER DEFAULT 1,
        merged_article_ids TEXT,
        briefing_id TEXT,
        action_tag TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE feeds (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        is_enabled INTEGER DEFAULT 1,
        is_preset INTEGER DEFAULT 0,
        credibility_weight REAL DEFAULT 3.0,
        last_fetched_at INTEGER,
        fetch_error_count INTEGER DEFAULT 0,
        is_domestic INTEGER DEFAULT 1,
        credibility REAL DEFAULT 5.0,
        status TEXT DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE briefings (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        article_count INTEGER NOT NULL,
        config_snapshot TEXT,
        generated_at INTEGER NOT NULL,
        trigger_type TEXT NOT NULL,
        status TEXT NOT NULL,
        ai_insight TEXT,
        total_fetched INTEGER DEFAULT 0,
        domestic_count INTEGER DEFAULT 0,
        international_count INTEGER DEFAULT 0,
        categories_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE scores (
        id TEXT PRIMARY KEY,
        article_id TEXT NOT NULL,
        mode TEXT NOT NULL,
        credibility REAL DEFAULT 0,
        density REAL DEFAULT 0,
        total REAL DEFAULT 0,
        raw_response TEXT,
        scored_at INTEGER NOT NULL,
        FOREIGN KEY (article_id) REFERENCES articles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_config (
        id TEXT PRIMARY KEY DEFAULT 'default',
        categories TEXT NOT NULL,
        daily_count INTEGER DEFAULT 10,
        domestic_ratio REAL DEFAULT 0.5,
        push_time TEXT DEFAULT '08:00',
        ai_mode TEXT DEFAULT 'hybrid',
        retention_days INTEGER DEFAULT 30,
        fetch_interval INTEGER DEFAULT 2,
        wifi_only INTEGER DEFAULT 0,
        onboarding_done INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE llm_config (
        id TEXT PRIMARY KEY DEFAULT 'default',
        provider TEXT DEFAULT 'mimo',
        api_key TEXT,
        model TEXT DEFAULT 'mimo',
        base_url TEXT,
        is_configured INTEGER DEFAULT 0,
        timeout INTEGER DEFAULT 30,
        budget_tokens INTEGER DEFAULT 10000
      )
    ''');

    await db.execute('''
      CREATE TABLE execution_logs (
        id TEXT PRIMARY KEY,
        task_type TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        duration INTEGER,
        error_message TEXT,
        details TEXT,
        label TEXT
      )
    ''');

    // v2 新增表
    await db.execute('''
      CREATE TABLE article_tags (
        id TEXT PRIMARY KEY,
        article_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        UNIQUE(article_id, tag)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tags_article ON article_tags(article_id)');
    await db.execute('CREATE INDEX idx_tags_tag ON article_tags(tag)');

    await db.execute('''
      CREATE TABLE llm_costs (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        model TEXT NOT NULL,
        input_tokens INTEGER NOT NULL,
        output_tokens INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_costs_date ON llm_costs(created_at)');

    // 索引
    await db.execute(
        'CREATE INDEX idx_articles_published ON articles(published_at DESC)');
    await db.execute(
        'CREATE INDEX idx_articles_score ON articles(score_total DESC)');
    await db.execute(
        'CREATE INDEX idx_articles_briefing ON articles(briefing_id)');
    await db.execute(
        'CREATE INDEX idx_articles_category ON articles(category)');
    await db.execute(
        'CREATE INDEX idx_briefings_date ON briefings(date DESC)');
    await db.execute(
        'CREATE INDEX idx_logs_started ON execution_logs(started_at DESC)');
    await db.execute(
        'CREATE INDEX idx_logs_type ON execution_logs(task_type)');

    // 种子数据
    await _seedPresetFeeds(db);
    await _seedDefaultConfig(db);
  }

  /// 数据库升级（v1 → v2）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // feeds 表扩展（last_fetched_at 和 fetch_error_count 在v1已存在，不重复添加）
      await db.execute(
          'ALTER TABLE feeds ADD COLUMN is_domestic INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE feeds ADD COLUMN credibility REAL DEFAULT 5.0');
      await db.execute(
          'ALTER TABLE feeds ADD COLUMN status TEXT DEFAULT "active"');
      // briefings 表扩展
      await db.execute(
          'ALTER TABLE briefings ADD COLUMN total_fetched INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE briefings ADD COLUMN domestic_count INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE briefings ADD COLUMN international_count INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE briefings ADD COLUMN categories_json TEXT');
      // llm_config 表扩展
      await db.execute(
          'ALTER TABLE llm_config ADD COLUMN timeout INTEGER DEFAULT 30');
      await db.execute(
          'ALTER TABLE llm_config ADD COLUMN budget_tokens INTEGER DEFAULT 10000');
      // v2 新增表
      await db.execute('''
        CREATE TABLE article_tags (
          id TEXT PRIMARY KEY,
          article_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          UNIQUE(article_id, tag)
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_tags_article ON article_tags(article_id)');
      await db.execute('CREATE INDEX idx_tags_tag ON article_tags(tag)');
      await db.execute('''
        CREATE TABLE llm_costs (
          id TEXT PRIMARY KEY,
          operation TEXT NOT NULL,
          model TEXT NOT NULL,
          input_tokens INTEGER NOT NULL,
          output_tokens INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_costs_date ON llm_costs(created_at)');
      // 迁移 credibility_weight → credibility
      try {
        await db.execute(
            'UPDATE feeds SET credibility = credibility_weight * 2 WHERE credibility_weight IS NOT NULL');
      } catch (_) {}
      // 根据 URL 推断 is_domestic
      final domesticDomains = [
        'qbitai.com',
        '36kr.com',
        'infoq.cn',
        'ifanr.com',
        'sspai.com',
        'ithome.com',
        'jiqizhixin.com',
        'huxiu.com'
      ];
      final feeds = await db.query('feeds');
      for (final feed in feeds) {
        final url = feed['url'] as String? ?? '';
        final isDomestic =
            domesticDomains.any((d) => url.contains(d)) ? 1 : 0;
        await db.update('feeds', {'is_domestic': isDomestic},
            where: 'id = ?', whereArgs: [feed['id']]);
      }
      // 插入预置数据源（如果feeds表为空）
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM feeds'),
      );
      if (count == 0) {
        await _seedPresetFeeds(db);
      }
      // 插入默认配置（如果llm_config表缺少v2字段）
      try {
        await db.update(
            'llm_config', {'timeout': 30, 'budget_tokens': 10000},
            where: 'id = ?', whereArgs: ['default']);
      } catch (_) {}
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE articles ADD COLUMN action_tag TEXT');
    }
  }

  // ==================== 种子数据 ====================

  static const _presetFeeds = [
    // 国内源
    {'id': 'preset_sspai', 'name': '少数派', 'url': 'https://sspai.com/feed', 'type': 'rss', 'category': '效率工具', 'is_domestic': 1, 'credibility': 7.5, 'is_preset': 1, 'is_enabled': 1},
    {'id': 'preset_36kr', 'name': '36氪', 'url': 'https://36kr.com/feed', 'type': 'rss', 'category': '科技商业', 'is_domestic': 1, 'credibility': 7.5, 'is_preset': 1, 'is_enabled': 1},
    {'id': 'preset_jiqizhixin', 'name': '机器之心', 'url': 'https://jiqizhixin.com/rss', 'type': 'rss', 'category': 'AI', 'is_domestic': 1, 'credibility': 8.0, 'is_preset': 1, 'is_enabled': 1},
    {'id': 'preset_infoq', 'name': 'InfoQ 中文', 'url': 'https://www.infoq.cn/feed', 'type': 'rss', 'category': '技术', 'is_domestic': 1, 'credibility': 8.0, 'is_preset': 1, 'is_enabled': 1},
    {'id': 'preset_qianxin', 'name': '奇安信威胁情报', 'url': 'https://ti.qianxin.com/rss', 'type': 'rss', 'category': '安全与隐私', 'is_domestic': 1, 'credibility': 8.0, 'is_preset': 1, 'is_enabled': 0},
    {'id': 'preset_jike', 'name': '即刻热门', 'url': 'https://rsshub.app/jike/topic/5538eaee4b9cd700394813e8', 'type': 'rss', 'category': '综合科技', 'is_domestic': 1, 'credibility': 6.0, 'is_preset': 1, 'is_enabled': 0},
    // 国际源
    {'id': 'preset_hn', 'name': 'Hacker News', 'url': 'https://hnrss.org/frontpage', 'type': 'rss', 'category': '开源生态', 'is_domestic': 0, 'credibility': 7.5, 'is_preset': 1, 'is_enabled': 1},
    {'id': 'preset_techcrunch', 'name': 'TechCrunch', 'url': 'https://techcrunch.com/feed', 'type': 'rss', 'category': '科技商业', 'is_domestic': 0, 'credibility': 9.0, 'is_preset': 1, 'is_enabled': 0},
    {'id': 'preset_verge', 'name': 'The Verge', 'url': 'https://www.theverge.com/rss/index.xml', 'type': 'rss', 'category': '消费科技', 'is_domestic': 0, 'credibility': 8.5, 'is_preset': 1, 'is_enabled': 0},
    {'id': 'preset_arstechnica', 'name': 'Ars Technica', 'url': 'https://feeds.arstechnica.com/arstechnica/index', 'type': 'rss', 'category': '安全与隐私', 'is_domestic': 0, 'credibility': 8.5, 'is_preset': 1, 'is_enabled': 0},
    {'id': 'preset_thehackernews', 'name': 'The Hacker News', 'url': 'https://feeds.feedburner.com/TheHackersNews', 'type': 'rss', 'category': '安全与隐私', 'is_domestic': 0, 'credibility': 8.0, 'is_preset': 1, 'is_enabled': 0},
    {'id': 'preset_devto', 'name': 'Dev.to', 'url': 'https://dev.to/feed', 'type': 'rss', 'category': '技术', 'is_domestic': 0, 'credibility': 7.0, 'is_preset': 1, 'is_enabled': 0},
  ];

  Future<void> _seedPresetFeeds(Database db) async {
    for (final feed in _presetFeeds) {
      await db.insert('feeds', {
        ...feed,
        'fetch_error_count': 0,
      });
    }
  }

  Future<void> _seedDefaultConfig(Database db) async {
    await db.insert('user_config', {
      'id': 'default',
      'categories': '["AI"]',
      'daily_count': 20,
      'domestic_ratio': 0.5,
      'push_time': '08:00',
      'ai_mode': 'hybrid',
      'retention_days': 30,
      'fetch_interval': 2,
      'wifi_only': 1,
      'onboarding_done': 0,
    });
    await db.insert('llm_config', {
      'id': 'default',
      'provider': 'mimo',
      'api_key': '',
      'model': 'mimo-v2.5-pro',
      'base_url': 'https://token-plan-cn.xiaomimimo.com/v1',
      'is_configured': 0,
      'timeout': 30,
      'budget_tokens': 10000,
    });
  }

  // ==================== 通用 CRUD ====================

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  /// 原生SQL查询（用于JOIN、聚合等复杂查询）
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  /// 清空所有文章和简报数据（保留配置和数据源）
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('articles');
    await db.delete('briefings');
    await db.delete('scores');
    await db.delete('article_tags');
    await db.delete('llm_costs');
    await db.delete('execution_logs');
  }

  /// 重置数据库（删除并重建）
  Future<void> resetDatabase() async {
    final db = await database;
    final dbPath = db.path;
    await db.close();
    _db = null;
    await deleteDatabase(dbPath);
    // 重新初始化会由下次访问 database getter 自动完成
  }
}
