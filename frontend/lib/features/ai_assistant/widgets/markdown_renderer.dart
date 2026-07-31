import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/theme/app_colors.dart';
import 'package:swaransh_academy/Core/theme/app_typography.dart';

/// Custom markdown renderer tuned to the Swaransh chat panel.
/// Supports: paragraphs, **bold**, *italic*, `inline code`,
/// ``` code blocks, # headings, - / * bullet lists,
/// 1. numbered lists, > blockquotes, | tables (horizontally scrollable).
class ChatMarkdown extends StatelessWidget {
  const ChatMarkdown({super.key, required this.text, this.isUser = false});

  final String text;
  final bool isUser;

  Color get _fg => isUser ? AppColors.navy : AppColors.textOnNavy;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((b) => _buildBlock(context, b)).toList(),
    );
  }

  // ── Block parsing ────────────────────────────────────────────────────────

  List<_Block> _parseBlocks(String raw) {
    final lines = raw.split('\n');
    final blocks = <_Block>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Horizontal rule / Divider (e.g. ---, ***, or ___)
      if (RegExp(r'^(\-{3,}|\*{3,}|_{3,})$').hasMatch(line.trim())) {
        blocks.add(const _Block(_BlockType.divider, ''));
        i++;
        continue;
      }
      // Fenced code block
      if (line.trimLeft().startsWith('```')) {
        final lang = line.trim().substring(3).trim();
        final buf = StringBuffer();
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          buf.writeln(lines[i]);
          i++;
        }
        blocks.add(
          _Block(_BlockType.code, buf.toString().trimRight(), meta: lang),
        );
        i++;
        continue;
      }

      // Table — line contains | and next line is separator (|---|)
      if (line.contains('|') &&
          i + 1 < lines.length &&
          lines[i + 1].contains('|') &&
          lines[i + 1].contains('-')) {
        final tableLines = <String>[line];
        i++;
        // skip separator row
        i++;
        while (i < lines.length && lines[i].contains('|')) {
          tableLines.add(lines[i]);
          i++;
        }
        blocks.add(_Block(_BlockType.table, tableLines.join('\n')));
        continue;
      }

      // Headings
      final headMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      if (headMatch != null) {
        blocks.add(
          _Block(
            _BlockType.heading,
            headMatch.group(2)!,
            meta: headMatch.group(1)!.length.toString(),
          ),
        );
        i++;
        continue;
      }

      // Blockquote
      if (line.startsWith('> ')) {
        final buf = StringBuffer(line.substring(2));
        i++;
        while (i < lines.length && lines[i].startsWith('> ')) {
          buf.write(' ${lines[i].substring(2)}');
          i++;
        }
        blocks.add(_Block(_BlockType.blockquote, buf.toString()));
        continue;
      }

      // Bullet list
      if (RegExp(r'^[\-\*\+] ').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^[\-\*\+] ').hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(RegExp(r'^[\-\*\+] '), ''));
          i++;
        }
        blocks.add(_Block(_BlockType.bulletList, items.join('\n')));
        continue;
      }

      // Numbered list
      if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^\d+\. ').hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(RegExp(r'^\d+\. '), ''));
          i++;
        }
        blocks.add(_Block(_BlockType.numberedList, items.join('\n')));
        continue;
      }

      // Blank line — skip
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Paragraph — collect until blank or special line
      // Paragraph — collect until blank or special line
      final buf = StringBuffer(line);
      i++;
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !RegExp(
            r'^(#{1,3} |> |[\-\*\+] |\d+\. |```|\||\-{3,}|\*{3,}|_{3,})', // <--- Added divider regex at the end
          ).hasMatch(lines[i])) {
        buf.write(' ${lines[i]}');
        i++;
      }
      blocks.add(_Block(_BlockType.paragraph, buf.toString()));
    }

    return blocks;
  }

  // ── Block rendering ──────────────────────────────────────────────────────

  Widget _buildBlock(BuildContext context, _Block block) {
    switch (block.type) {
      case _BlockType.heading:
        final level = int.tryParse(block.meta ?? '1') ?? 1;
        final style = level == 1
            ? AppTypography.headlineMedium.copyWith(color: _fg)
            : level == 2
            ? AppTypography.titleLarge.copyWith(color: _fg)
            : AppTypography.bodyMedium.copyWith(
                color: _fg,
                fontWeight: FontWeight.w700,
              );
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(block.text, style: style),
        );

      case _BlockType.code:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                block.text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF90CAF9),
                  height: 1.5,
                ),
              ),
            ),
          ),
        );

      case _BlockType.blockquote:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.text,
                    style: AppTypography.bodySmall.copyWith(
                      color: _fg.withOpacity(0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case _BlockType.bulletList:
        final items = block.text.split('\n');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        Expanded(child: _InlineText(item, fg: _fg)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );

      case _BlockType.numberedList:
        final items = block.text.split('\n');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.key + 1}. ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(child: _InlineText(e.value, fg: _fg)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );

      case _BlockType.table:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _TableWidget(raw: block.text, fg: _fg),
        );

      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _InlineText(block.text, fg: _fg),
        );
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            color: AppColors.divider, // Or AppColors.gold.withOpacity(0.3)
            thickness: 1,
          ),
        );
    }
  }
}

// ── Inline text (bold, italic, inline code) ─────────────────────────────────

class _InlineText extends StatelessWidget {
  const _InlineText(this.text, {required this.fg});
  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parseInline(text, fg),
      style: AppTypography.bodyMedium.copyWith(color: fg, height: 1.35),
    );
  }

  static TextSpan _parseInline(String text, Color fg) {
    final spans = <InlineSpan>[];
    // Pattern order matters — longer patterns first
    final pattern = RegExp(
      r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)',
    );
    int last = 0;

    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }

      if (m.group(1) != null) {
        // Bold+italic
        spans.add(
          TextSpan(
            text: m.group(2),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (m.group(3) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: m.group(4),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(5) != null) {
        // Italic
        spans.add(
          TextSpan(
            text: m.group(6),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m.group(7) != null) {
        // Inline code
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                m.group(8)!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF90CAF9),
                ),
              ),
            ),
          ),
        );
      }

      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return TextSpan(children: spans);
  }
}

// ── Scrollable table ─────────────────────────────────────────────────────────

class _TableWidget extends StatelessWidget {
  const _TableWidget({required this.raw, required this.fg});
  final String raw;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    final headers = _parseCells(lines.first);
    final rows = lines.skip(1).map(_parseCells).toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        physics: const BouncingScrollPhysics(),
        child: IntrinsicWidth(
          // <--- 1. Forces full content width calculation
          child: Table(
            // 2. Set min/max or explicit widths per column, or flexible sizing:
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                ),
                children: headers
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          h,
                          softWrap:
                              false, // <--- 3. Prevents header text wrapping
                          style: AppTypography.bodySmall.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // Data rows
              ...rows.map(
                (cells) => TableRow(
                  children: List.generate(
                    headers.length,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        i < cells.length ? cells[i] : '',
                        softWrap: false, // <--- 4. Prevents cell text wrapping
                        style: AppTypography.bodySmall.copyWith(color: fg),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _parseCells(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|'))
      trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed.split('|').map((c) => c.trim()).toList();
  }
}

// ── Internal data model ──────────────────────────────────────────────────────

enum _BlockType {
  paragraph,
  heading,
  code,
  blockquote,
  bulletList,
  numberedList,
  table,
  divider,
}

class _Block {
  const _Block(this.type, this.text, {this.meta});
  final _BlockType type;
  final String text;
  final String? meta; // heading level, code language, etc.
}
