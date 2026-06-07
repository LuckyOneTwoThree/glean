class HtmlUtils {
  /// 剥离 HTML 标签，清理为纯文本
  /// 处理：HTML标签 → 换行 → 实体解码 → 空白压缩
  static String stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';

    var text = html;

    // 1. 将块级标签替换为换行
    text = text.replaceAllMapped(
      RegExp(r'</(p|div|br|h[1-6]|li|tr|blockquote|section|article|header|footer|aside)>', caseSensitive: false),
      (_) => '\n',
    );
    // <br> 和 <br/> 自闭合标签
    text = text.replaceAllMapped(RegExp(r'<br\s*/?\s*>', caseSensitive: false), (_) => '\n');

    // 2. 移除所有 HTML 标签
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 3. HTML 实体解码
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '', radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });

    // 4. 清理 CDATA 残留
    text = text.replaceAll('<![CDATA[', '');
    text = text.replaceAll(']]>', '');

    // 5. 压缩连续空白和换行
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }
}
