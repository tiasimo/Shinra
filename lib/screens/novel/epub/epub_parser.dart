import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Un capitolo (voce della spine) di un EPUB.
class EpubChapterInfo {
  final String path; // percorso completo dentro lo zip
  final String title;

  const EpubChapterInfo({required this.path, required this.title});
}

/// Metadati letti da un EPUB.
class EpubMetadata {
  final String title;
  final String? author;
  final Uint8List? coverBytes;
  final String? coverExtension;
  final List<EpubChapterInfo> chapters;

  const EpubMetadata({
    required this.title,
    required this.author,
    required this.coverBytes,
    required this.coverExtension,
    required this.chapters,
  });
}

/// Legge un file .epub: metadati, indice dei capitoli e contenuto HTML
/// (con le immagini incorporate come data URI).
class EpubDocument {
  final Archive _archive;
  final Map<String, ArchiveFile> _files = {};
  late final EpubMetadata metadata;

  EpubDocument._(this._archive) {
    for (final f in _archive) {
      if (f.isFile) _files[_normalizeKey(f.name)] = f;
    }
  }

  static String _normalizeKey(String name) =>
      p.posix.normalize(name.replaceAll('\\', '/')).toLowerCase();

  static Future<EpubDocument> open(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return fromBytes(bytes);
  }

  static EpubDocument fromBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final doc = EpubDocument._(archive);
    doc.metadata = doc._parseMetadata();
    return doc;
  }

  Uint8List? _readBytes(String path) {
    final file = _files[_normalizeKey(path)] ??
        _files[_normalizeKey(Uri.decodeFull(path))];
    if (file == null) return null;
    final content = file.content;
    if (content is Uint8List) return content;
    return Uint8List.fromList(List<int>.from(content as List));
  }

  String? _readText(String path) {
    final bytes = _readBytes(path);
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }

  String _resolve(String baseFile, String href) {
    final clean = href.split('#').first;
    final baseDir = p.posix.dirname(baseFile);
    final decoded = Uri.decodeFull(clean);
    return p.posix.normalize(p.posix.join(baseDir == '.' ? '' : baseDir, decoded));
  }

  EpubMetadata _parseMetadata() {
    final container = _readText('META-INF/container.xml');
    if (container == null) {
      throw const FormatException('File EPUB non valido: manca container.xml');
    }
    final containerXml = XmlDocument.parse(container);
    final rootfile = containerXml.descendants
        .whereType<XmlElement>()
        .firstWhere((e) => e.name.local == 'rootfile');
    final opfPath = rootfile.getAttribute('full-path');
    if (opfPath == null) {
      throw const FormatException('File EPUB non valido: manca il pacchetto OPF');
    }
    final opfText = _readText(opfPath);
    if (opfText == null) {
      throw const FormatException('File EPUB non valido: OPF non trovato');
    }
    final opf = XmlDocument.parse(opfText);

    String? firstText(String localName) {
      for (final e in opf.descendants.whereType<XmlElement>()) {
        if (e.name.local == localName) {
          final t = e.innerText.trim();
          if (t.isNotEmpty) return t;
        }
      }
      return null;
    }

    final title = firstText('title') ?? p.basenameWithoutExtension(opfPath);
    final author = firstText('creator');

    // manifest: id -> (href, mediaType, properties)
    final manifest = <String, Map<String, String>>{};
    for (final item in opf.descendants.whereType<XmlElement>()) {
      if (item.name.local != 'item') continue;
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      manifest[id] = {
        'href': href,
        'type': item.getAttribute('media-type') ?? '',
        'props': item.getAttribute('properties') ?? '',
      };
    }

    // cover
    String? coverHref;
    for (final entry in manifest.values) {
      if (entry['props']!.split(' ').contains('cover-image')) {
        coverHref = entry['href'];
        break;
      }
    }
    if (coverHref == null) {
      for (final m in opf.descendants.whereType<XmlElement>()) {
        if (m.name.local == 'meta' && m.getAttribute('name') == 'cover') {
          final id = m.getAttribute('content');
          if (id != null && manifest[id] != null) {
            coverHref = manifest[id]!['href'];
            break;
          }
        }
      }
    }
    Uint8List? coverBytes;
    String? coverExt;
    if (coverHref != null) {
      final coverPath = _resolve(opfPath, coverHref);
      coverBytes = _readBytes(coverPath);
      coverExt = p.extension(coverPath).replaceFirst('.', '').toLowerCase();
      if (coverExt.isEmpty) coverExt = 'jpg';
    }

    // spine
    final spine = <String>[];
    String? tocId;
    for (final e in opf.descendants.whereType<XmlElement>()) {
      if (e.name.local == 'spine') {
        tocId = e.getAttribute('toc');
        for (final ref in e.children.whereType<XmlElement>()) {
          if (ref.name.local != 'itemref') continue;
          if (ref.getAttribute('linear') == 'no') continue;
          final idref = ref.getAttribute('idref');
          if (idref != null && manifest[idref] != null) {
            spine.add(manifest[idref]!['href']!);
          }
        }
        break;
      }
    }

    // indice (nav EPUB3 oppure NCX EPUB2): percorso -> titolo
    final tocTitles = <String, String>{};
    String? navHref;
    for (final entry in manifest.values) {
      if (entry['props']!.split(' ').contains('nav')) {
        navHref = entry['href'];
        break;
      }
    }
    if (navHref != null) {
      final navPath = _resolve(opfPath, navHref);
      final navText = _readText(navPath);
      if (navText != null) {
        final doc = html_parser.parse(navText);
        dom.Element? nav;
        for (final n in doc.querySelectorAll('nav')) {
          final t = n.attributes['epub:type'] ?? n.attributes['type'] ?? '';
          if (t.contains('toc')) {
            nav = n;
            break;
          }
        }
        nav ??= doc.querySelector('nav');
        if (nav != null) {
          for (final a in nav.querySelectorAll('a')) {
            final href = a.attributes['href'];
            final text = a.text.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (href == null || text.isEmpty) continue;
            tocTitles.putIfAbsent(_normalizeKey(_resolve(navPath, href)), () => text);
          }
        }
      }
    }
    if (tocTitles.isEmpty) {
      String? ncxHref;
      if (tocId != null && manifest[tocId] != null) {
        ncxHref = manifest[tocId]!['href'];
      } else {
        for (final entry in manifest.values) {
          if (entry['type'] == 'application/x-dtbncx+xml') {
            ncxHref = entry['href'];
            break;
          }
        }
      }
      if (ncxHref != null) {
        final ncxPath = _resolve(opfPath, ncxHref);
        final ncxText = _readText(ncxPath);
        if (ncxText != null) {
          final ncx = XmlDocument.parse(ncxText);
          for (final point in ncx.descendants.whereType<XmlElement>()) {
            if (point.name.local != 'navPoint') continue;
            final label = point.children
                .whereType<XmlElement>()
                .where((e) => e.name.local == 'navLabel')
                .map((e) => e.innerText.replaceAll(RegExp(r'\s+'), ' ').trim())
                .firstWhere((t) => t.isNotEmpty, orElse: () => '');
            final src = point.children
                .whereType<XmlElement>()
                .where((e) => e.name.local == 'content')
                .map((e) => e.getAttribute('src'))
                .firstWhere((s) => s != null, orElse: () => null);
            if (label.isEmpty || src == null) continue;
            tocTitles.putIfAbsent(
                _normalizeKey(_resolve(ncxPath, src)), () => label);
          }
        }
      }
    }

    final chapters = <EpubChapterInfo>[];
    for (var i = 0; i < spine.length; i++) {
      final path = _resolve(opfPath, spine[i]);
      final title = tocTitles[_normalizeKey(path)] ?? 'Capitolo ${i + 1}';
      chapters.add(EpubChapterInfo(path: path, title: title));
    }

    return EpubMetadata(
      title: title,
      author: author,
      coverBytes: coverBytes,
      coverExtension: coverExt,
      chapters: chapters,
    );
  }

  static const _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
  };

  /// Contenuto HTML del capitolo, con le immagini incorporate.
  String readChapterHtml(String chapterPath) {
    final raw = _readText(chapterPath);
    if (raw == null) return '';
    final doc = html_parser.parse(raw);
    final body = doc.body;
    if (body == null) return raw;

    // <svg><image xlink:href=.../></svg> (tipico delle copertine) -> <img>
    for (final svg in body.querySelectorAll('svg')) {
      final image = svg.querySelector('image');
      final href = image?.attributes['xlink:href'] ?? image?.attributes['href'];
      if (href != null) {
        final img = dom.Element.tag('img')..attributes['src'] = href;
        svg.replaceWith(img);
      } else {
        svg.remove();
      }
    }

    for (final img in body.querySelectorAll('img')) {
      final src = img.attributes['src'];
      if (src == null || src.startsWith('data:') || src.startsWith('http')) {
        continue;
      }
      final imgPath = _resolve(chapterPath, src);
      final bytes = _readBytes(imgPath);
      if (bytes == null || bytes.length > 6 * 1024 * 1024) {
        img.remove();
        continue;
      }
      final ext = p.extension(imgPath).replaceFirst('.', '').toLowerCase();
      final mime = _mimeByExt[ext] ?? 'image/jpeg';
      img.attributes['src'] = 'data:$mime;base64,${base64Encode(bytes)}';
    }
    return body.innerHtml;
  }
}
