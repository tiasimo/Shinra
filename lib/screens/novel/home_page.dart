import 'dart:io';

import 'package:anymex/screens/novel/epub/epub_library_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Sezione Novel: libreria locale di file EPUB.
class NovelHomePage extends StatefulWidget {
  const NovelHomePage({super.key});

  @override
  State<NovelHomePage> createState() => _NovelHomePageState();
}

class _NovelHomePageState extends State<NovelHomePage> {
  late ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);
  late final EpubLibraryController _library;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _library = Get.isRegistered<EpubLibraryController>()
        ? Get.find<EpubLibraryController>()
        : Get.put(EpubLibraryController(), permanent: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(EpubBookEntry book) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovere il libro?'),
        content: Text(
            '"${book.title}" verrà tolto dalla libreria. Il file originale sul telefono non viene toccato.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Rimuovi')),
        ],
      ),
    );
    if (remove == true) await _library.removeBook(book);
  }

  Widget _buildCover(EpubBookEntry book) {
    final coverPath = _library.coverPathOf(book);
    final placeholder = Container(
      color: context.colors.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        book.title,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.onSurfaceVariant),
      ),
    );
    if (coverPath == null) return placeholder;
    return Image.file(
      File(coverPath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _buildBookCard(EpubBookEntry book) {
    return GestureDetector(
      onTap: () => _library.openBook(book),
      onLongPress: () => _confirmRemove(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(book),
                  if (book.progress > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: 4,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnymeXText(
            book.title,
            variant: TextVariant.semiBold,
            size: 13,
            maxLines: 2,
          ),
          if (book.author != null && book.author!.isNotEmpty)
            AnymeXText(
              book.author!,
              size: 11,
              maxLines: 1,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 72, color: context.colors.primary),
          const SizedBox(height: 16),
          const AnymeXText(
            'La tua libreria è vuota',
            variant: TextVariant.bold,
            size: 18,
          ),
          const SizedBox(height: 8),
          AnymeXText(
            'Aggiungi i tuoi file EPUB: restano salvati nell\'app e puoi riprendere a leggere da dove eri rimasto.',
            textAlign: TextAlign.center,
            maxLines: 4,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _library.importBooks,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Aggiungi EPUB'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 6 : (width > 600 ? 4 : 3);
    final bottomNavBarHeight = MediaQuery.paddingOf(context).bottom + 65.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: statusBarHeight + appBarHeight + 10),
                Obx(() {
                  if (_library.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final books = _library.books.toList();
                  if (books.isEmpty) return _buildEmptyState();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: books.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.52,
                      ),
                      itemBuilder: (_, i) => _buildBookCard(books[i]),
                    ),
                  );
                }),
                SizedBox(height: bottomNavBarHeight + 150),
              ],
            ),
          ),
          Obx(() => _library.isImporting.value
              ? const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                )
              : const SizedBox.shrink()),
          CustomAnimatedAppBar(
            isVisible: _isAppBarVisibleExternally,
            scrollController: _scrollController,
            headerContent: Header(
              title: 'Novels',
              subtitleWidget: const HeaderGreetingSubtitle(),
              actions: [
                HeaderActionButton(
                  icon: Icons.add_rounded,
                  onTap: _library.importBooks,
                ),
              ],
            ),
            visibleStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
            hiddenStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.light
                      : Brightness.dark,
              statusBarBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
