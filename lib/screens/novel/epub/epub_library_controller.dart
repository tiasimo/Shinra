import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/novel/epub/epub_parser.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Un libro nella libreria locale.
class EpubBookEntry {
  final String id;
  final String title;
  final String? author;
  final String fileName; // file copiato nella cartella dell'app
  final String? coverFileName;
  final int totalChapters;
  final int addedAt;
  final int sourceSize;
  final String originalName;

  int lastChapterIndex;
  double lastOffset;
  double lastMaxOffset;
  int lastReadAt;

  EpubBookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.fileName,
    required this.coverFileName,
    required this.totalChapters,
    required this.addedAt,
    required this.sourceSize,
    required this.originalName,
    this.lastChapterIndex = 0,
    this.lastOffset = 0,
    this.lastMaxOffset = 0,
    this.lastReadAt = 0,
  });

  double get progress {
    if (totalChapters <= 0) return 0;
    final base = lastChapterIndex / totalChapters;
    final inChapter = lastMaxOffset > 0
        ? (lastOffset / lastMaxOffset).clamp(0.0, 1.0) / totalChapters
        : 0.0;
    return (base + inChapter).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'fileName': fileName,
        'coverFileName': coverFileName,
        'totalChapters': totalChapters,
        'addedAt': addedAt,
        'sourceSize': sourceSize,
        'originalName': originalName,
        'lastChapterIndex': lastChapterIndex,
        'lastOffset': lastOffset,
        'lastMaxOffset': lastMaxOffset,
        'lastReadAt': lastReadAt,
      };

  factory EpubBookEntry.fromJson(Map<String, dynamic> j) => EpubBookEntry(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Senza titolo',
        author: j['author'] as String?,
        fileName: j['fileName'] as String,
        coverFileName: j['coverFileName'] as String?,
        totalChapters: (j['totalChapters'] as num?)?.toInt() ?? 0,
        addedAt: (j['addedAt'] as num?)?.toInt() ?? 0,
        sourceSize: (j['sourceSize'] as num?)?.toInt() ?? 0,
        originalName: j['originalName'] as String? ?? '',
        lastChapterIndex: (j['lastChapterIndex'] as num?)?.toInt() ?? 0,
        lastOffset: (j['lastOffset'] as num?)?.toDouble() ?? 0,
        lastMaxOffset: (j['lastMaxOffset'] as num?)?.toDouble() ?? 0,
        lastReadAt: (j['lastReadAt'] as num?)?.toInt() ?? 0,
      );
}

/// Libreria EPUB: copia i file nella memoria dell'app e ne ricorda
/// l'elenco e i progressi di lettura.
class EpubLibraryController extends GetxController {
  final RxList<EpubBookEntry> books = <EpubBookEntry>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isImporting = false.obs;

  late Directory _dir;
  File get _indexFile => File(p.join(_dir.path, 'index.json'));

  String filePathOf(EpubBookEntry b) => p.join(_dir.path, b.fileName);
  String? coverPathOf(EpubBookEntry b) =>
      b.coverFileName == null ? null : p.join(_dir.path, b.coverFileName!);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      _dir = Directory(p.join(base.path, 'epub_library'));
      if (!await _dir.exists()) await _dir.create(recursive: true);
      if (await _indexFile.exists()) {
        final data = jsonDecode(await _indexFile.readAsString()) as List;
        final loaded = <EpubBookEntry>[];
        for (final item in data) {
          try {
            final e = EpubBookEntry.fromJson(Map<String, dynamic>.from(item));
            if (await File(filePathOf(e)).exists()) loaded.add(e);
          } catch (_) {}
        }
        books.assignAll(loaded);
        _sort();
      }
    } catch (e) {
      errorSnackBar('Impossibile leggere la libreria: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _sort() {
    books.sort((a, b) {
      final byRead = b.lastReadAt.compareTo(a.lastReadAt);
      return byRead != 0 ? byRead : b.addedAt.compareTo(a.addedAt);
    });
  }

  Future<void> _saveIndex() async {
    try {
      await _indexFile
          .writeAsString(jsonEncode(books.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }

  /// Sceglie uno o più file .epub e li copia nella libreria.
  Future<void> importBooks() async {
    if (isImporting.value) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    isImporting.value = true;
    int added = 0;
    int skipped = 0;
    int failed = 0;
    try {
      for (final picked in result.files) {
        final path = picked.path;
        if (path == null) {
          failed++;
          continue;
        }
        final source = File(path);
        final size = await source.length();
        final originalName = p.basename(path);
        if (books.any((b) =>
            b.sourceSize == size && b.originalName == originalName)) {
          skipped++;
          continue;
        }
        final id = DateTime.now().microsecondsSinceEpoch.toString();
        final storedName = '$id.epub';
        final storedFile = File(p.join(_dir.path, storedName));
        try {
          await source.copy(storedFile.path);
          final doc = await EpubDocument.open(storedFile.path);
          final meta = doc.metadata;
          String? coverName;
          if (meta.coverBytes != null) {
            coverName = '${id}_cover.${meta.coverExtension ?? 'jpg'}';
            await File(p.join(_dir.path, coverName))
                .writeAsBytes(meta.coverBytes!);
          }
          books.add(EpubBookEntry(
            id: id,
            title: meta.title,
            author: meta.author,
            fileName: storedName,
            coverFileName: coverName,
            totalChapters: meta.chapters.length,
            addedAt: DateTime.now().millisecondsSinceEpoch,
            sourceSize: size,
            originalName: originalName,
          ));
          added++;
        } catch (_) {
          failed++;
          if (await storedFile.exists()) await storedFile.delete();
        }
      }
      _sort();
      await _saveIndex();
    } finally {
      isImporting.value = false;
    }
    if (added > 0) {
      successSnackBar(
          added == 1 ? 'Libro aggiunto alla libreria' : '$added libri aggiunti');
    }
    if (skipped > 0) {
      infoSnackBar(skipped == 1
          ? 'Un libro era già in libreria'
          : '$skipped libri erano già in libreria');
    }
    if (failed > 0) {
      errorSnackBar(failed == 1
          ? 'Un file non è un EPUB valido'
          : '$failed file non sono EPUB validi');
    }
  }

  Future<void> removeBook(EpubBookEntry book) async {
    books.remove(book);
    try {
      final f = File(filePathOf(book));
      if (await f.exists()) await f.delete();
      final c = coverPathOf(book);
      if (c != null && await File(c).exists()) await File(c).delete();
    } catch (_) {}
    await _saveIndex();
  }

  void _updateProgress(
      EpubBookEntry book, int chapterIndex, Chapter chapter) {
    book.lastChapterIndex = chapterIndex;
    book.lastOffset = chapter.currentOffset ?? 0;
    book.lastMaxOffset = chapter.maxOffset ?? 0;
    book.lastReadAt = DateTime.now().millisecondsSinceEpoch;
    books.refresh();
    _saveIndex();
  }

  /// Apre il libro nel lettore, riprendendo da dove eri rimasto.
  Future<void> openBook(EpubBookEntry book) async {
    try {
      final doc = await EpubDocument.open(filePathOf(book));
      final infos = doc.metadata.chapters;
      if (infos.isEmpty) {
        errorSnackBar('Questo libro non contiene capitoli');
        return;
      }
      final chapters = <Chapter>[
        for (var i = 0; i < infos.length; i++)
          Chapter(
            link: infos[i].path,
            title: infos[i].title,
            number: (i + 1).toDouble(),
          ),
      ];
      final start = book.lastChapterIndex.clamp(0, chapters.length - 1);
      final initial = chapters[start]
        ..currentOffset = book.lastOffset
        ..maxOffset = book.lastMaxOffset;

      final cover = coverPathOf(book);
      final media = Media(
        id: 'epub_${book.id}',
        title: book.title,
        romajiTitle: book.title,
        poster: cover ?? '?',
        cover: cover,
        mediaType: ItemType.novel,
        serviceType: ServicesType.extensions,
        totalChapters: chapters.length.toString(),
      );

      await navigate(() => NovelReader(
            chapter: initial,
            media: media,
            chapters: chapters,
            localContentLoader: (chapter) async =>
                doc.readChapterHtml(chapter.link ?? ''),
            onLocalProgress: (chapter) {
              final index = chapters.indexWhere((c) => c.link == chapter.link);
              if (index >= 0) _updateProgress(book, index, chapter);
            },
          ));
    } catch (e) {
      errorSnackBar('Impossibile aprire il libro: $e');
    }
  }
}
