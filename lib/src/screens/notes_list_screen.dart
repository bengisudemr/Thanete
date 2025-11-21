import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/models/note.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/providers/app_theme_controller.dart';
import 'package:thanette/src/screens/note_detail_screen.dart';
import 'package:thanette/src/providers/supabase_service.dart';
import 'package:thanette/src/screens/profile_screen.dart';
import 'package:thanette/src/widgets/color_picker.dart';
import 'package:thanette/src/widgets/floating_chat_bubble.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:thanette/src/widgets/ui/ui_primitives.dart';

class NotesListScreen extends StatefulWidget {
  static const route = '/notes';
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _profileName;
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });

    // Load real notes from Supabase on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotesProvider>();
      await provider.loadFromSupabase();
      try {
        final profile = await SupabaseService.instance.getMyProfile();
        if (mounted) {
          setState(() {
            _profileName = profile?['name']?.toString();
          });
        }
      } catch (_) {}
    });
  }

  void _onScroll() {
    final provider = context.read<NotesProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoading) {
      provider.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showColorPickerForNote(NoteModel note) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXXL),
            child: ColorPicker(
              selectedColor: note.color,
              onColorChanged: (color) async {
                await context.read<NotesProvider>().updateNoteColorRemote(
                  id: note.id,
                  color: color,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerForNote(NoteModel note) {
    final textController = TextEditingController();
    bool isSaving = false;

    final popupFuture = showCupertinoModalPopup<void>(
      context: context,
      builder: (modalCtx) {
        return CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              child: StatefulBuilder(
                builder: (innerCtx, setModalState) {
                  return Consumer<NotesProvider>(
                    builder: (context, provider, _) {
                      final categories = provider.categories
                          .where((cat) => cat != 'all')
                          .toList(growable: false);
                      final maxHeight = (categories.length * 48.0)
                          .clamp(0.0, 260.0)
                          .toDouble();

                      Future<void> selectCategory(String category) async {
                        if (isSaving) return;
                        setModalState(() => isSaving = true);
                        try {
                          final normalized = provider.canonicalizeCategory(
                            category,
                          );
                          await provider.setNoteCategoryRemote(
                            note.id,
                            normalized,
                          );
                          Navigator.of(modalCtx).pop();
                        } catch (_) {
                          setModalState(() => isSaving = false);
                        }
                      }

                      Future<void> addNewCategory() async {
                        final raw = textController.text.trim();
                        if (raw.isEmpty || isSaving) return;
                        await selectCategory(raw);
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Kategori Seç',
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: AppTheme.fontWeightSemiBold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          if (categories.isNotEmpty)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: categories.length <= 3
                                    ? 180
                                    : maxHeight,
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppTheme.spacingS),
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final isSelected = category == note.category;
                                  return CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: isSaving
                                        ? null
                                        : () => selectCategory(category),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spacingM,
                                        horizontal: AppTheme.spacingL,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryPink.withOpacity(
                                                0.12,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusLarge,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              provider.categoryLabel(category),
                                              style: AppTheme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: AppTheme.textPrimary,
                                                  ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              CupertinoIcons
                                                  .check_mark_circled_solid,
                                              size: 20,
                                              color: AppTheme.primaryPink,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (categories.isNotEmpty)
                            const SizedBox(height: AppTheme.spacingL),
                          CupertinoTextField(
                            controller: textController,
                            placeholder: 'Yeni kategori adı',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => addNewCategory(),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          CupertinoButton.filled(
                            onPressed: isSaving ? null : () => addNewCategory(),
                            child: isSaving
                                ? const CupertinoActivityIndicator()
                                : const Text('Kategori Ekle'),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          CupertinoButton(
                            onPressed: () {
                              if (!isSaving) {
                                Navigator.of(modalCtx).pop();
                              }
                            },
                            child: const Text('Vazgeç'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    popupFuture.whenComplete(textController.dispose);
  }

  void _showNoteMenu(NoteModel note) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCategoryPickerForNote(note);
            },
            child: const Text('Kategoriyi Değiştir'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showColorPickerForNote(note);
            },
            child: const Text('Rengi Değiştir'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(note);
            },
            child: const Text('Notu Sil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(note) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<NotesProvider>().deleteNoteRemote(note.id);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final notes = provider.items;

    // Watch AppThemeController to rebuild when theme changes
    return Consumer<AppThemeController>(
      builder: (context, themeController, _) {
        return AppScaffold(
          padded: false,
          background: AppTheme.backgroundSecondary,
          body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              _NotesHeader(
                profileName: _profileName,
                noteCount: notes.length,
                isListView: _isListView,
                onProfileTap: () =>
                    Navigator.of(context).pushNamed(ProfileScreen.route),
                onViewModeChanged: (isList) =>
                    setState(() => _isListView = isList),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Consumer<NotesProvider>(
                builder: (context, provider, _) {
                  final categories = provider.categories;
                  if (categories.length <= 1) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXXL,
                      ),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final value = categories[index];
                        final label = provider.categoryLabel(value);
                        final isSelected = provider.activeCategory == value;
                        return _CategoryFilterChip(
                          label: label,
                          isSelected: isSelected,
                          onTap: () => provider.setCategoryFilter(value),
                        );
                      },
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppTheme.spacingS),
                      itemCount: categories.length,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingL),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXXL,
                  vertical: AppTheme.spacingXL,
                ),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) =>
                      context.read<NotesProvider>().searchNotes(value),
                  onClear: () {
                    _searchController.clear();
                    context.read<NotesProvider>().clearSearch();
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXXL,
                  ),
                  child: provider.isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : AnimatedSwitcher(
                          duration: AppTheme.animationFast,
                          child: notes.isEmpty
                              ? _buildEmptyState(provider)
                              : _isListView
                              ? _NotesListView(
                                  controller: _scrollController,
                                  notes: notes,
                                  onOpen: _openNote,
                                  onTogglePin: _togglePin,
                                  onMore: _showNoteMenu,
                                  hasMore: provider.hasMore,
                                )
                              : _NotesGridView(
                                  controller: _scrollController,
                                  notes: notes,
                                  onOpen: _openNote,
                                  onTogglePin: _togglePin,
                                  onMore: _showNoteMenu,
                                  onReorder: provider.reorderNotesLocally,
                                  hasMore: provider.hasMore,
                                ),
                        ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 25,
            right: 20,
            child: _AddNoteButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  NoteDetailScreen.route,
                  arguments: const NoteDetailArgs(id: null),
                );
              },
            ),
          ),
          const FloatingChatBubble(extraBottomOffset: 3),
        ],
      ),
    );
      },
    );
  }

  void _openNote(String id) {
    Navigator.of(
      context,
    ).pushNamed(NoteDetailScreen.route, arguments: NoteDetailArgs(id: id));
  }

  void _togglePin(String id) {
    context.read<NotesProvider>().togglePinRemote(id);
  }

  Widget _buildEmptyState(NotesProvider provider) {
    final isSearching = provider.searchQuery.isNotEmpty;
    return Center(
      child: EmptyState(
        title: isSearching ? 'Arama sonucu yok' : 'Henüz not oluşturulmadı',
        message: isSearching
            ? '"${provider.searchQuery}" için sonuç bulamadık.\nFarklı anahtar kelimeler deneyin.'
            : 'İlk notunu oluşturmak için sağ alttaki + butonuna dokun.',
        icon: isSearching ? Icons.search_off_outlined : Icons.sticky_note_2,
        primaryAction: isSearching
            ? CupertinoButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<NotesProvider>().clearSearch();
                },
                color: AppTheme.primaryPink.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXXL,
                  vertical: AppTheme.spacingM,
                ),
                child: Text(
                  'Filtreyi temizle',
                  style: AppTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryPink,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // Drawer removed; profile actions moved to bottom sheet
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader({
    required this.profileName,
    required this.noteCount,
    required this.isListView,
    required this.onProfileTap,
    required this.onViewModeChanged,
  });

  final String? profileName;
  final int noteCount;
  final bool isListView;
  final VoidCallback onProfileTap;
  final ValueChanged<bool> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final greeting = profileName?.split(' ').first ?? 'thanette kullanıcısı';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXXL,
        AppTheme.spacingXXXL,
        AppTheme.spacingXXL,
        AppTheme.spacingL,
      ),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXXXL,
          vertical: AppTheme.spacingXL,
        ),
        borderColor: Colors.transparent,
        borderWidth: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradientLinear,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXLarge,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      greeting.characters.first.toUpperCase(),
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin, $greeting',
                        style: AppTheme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Notlarını düzenle, fikirlerini yakala ve her şeyi tek yerde tut.',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Text(
                    '$noteCount not',
                    style: AppTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: isListView ? 1 : 0,
                    thumbColor: AppTheme.primaryPink.withOpacity(0.15),
                    backgroundColor: AppTheme.backgroundTertiary.withOpacity(
                      0.8,
                    ),
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.grid_view,
                          size: 20,
                        ),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.list,
                          size: 20,
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      if (value == null) return;
                      onViewModeChanged(value == 1);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Notlarda ara',
      onChanged: onChanged,
      onSuffixTap: onClear,
      placeholderStyle: AppTheme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
      ),
      style: AppTheme.textTheme.bodyLarge,
    );
  }
}

class _NotesListView extends StatelessWidget {
  const _NotesListView({
    required this.controller,
    required this.notes,
    required this.onOpen,
    required this.onTogglePin,
    required this.onMore,
    required this.hasMore,
  });

  final ScrollController controller;
  final List<NoteModel> notes;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onTogglePin;
  final ValueChanged<NoteModel> onMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXXXL),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteListTile(
                note: note,
                onOpen: onOpen,
                onTogglePin: onTogglePin,
                onMore: onMore,
              );
            },
          ),
        ),
        if (notes.isNotEmpty && hasMore) const _PaginationIndicator(),
      ],
    );
  }
}

class _NotesGridView extends StatelessWidget {
  const _NotesGridView({
    required this.controller,
    required this.notes,
    required this.onOpen,
    required this.onTogglePin,
    required this.onMore,
    required this.onReorder,
    required this.hasMore,
  });

  final ScrollController controller;
  final List<NoteModel> notes;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onTogglePin;
  final ValueChanged<NoteModel> onMore;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid: telefon için 2, tablet için 3-4 sütun
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth >= 900) {
      // Büyük tablet/desktop
      crossAxisCount = 4;
      childAspectRatio = 0.75;
    } else if (screenWidth >= 600) {
      // Tablet
      crossAxisCount = 3;
      childAspectRatio = 0.72;
    } else {
      // Telefon
      crossAxisCount = 2;
      childAspectRatio = 0.78;
    }
    
    return Column(
      children: [
        Expanded(
          child: ReorderableGridView.builder(
            controller: controller,
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXXXL),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppTheme.spacingXXL,
              mainAxisSpacing: AppTheme.spacingXXL,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: notes.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteGridTile(
                key: ValueKey(note.id),
                note: note,
                onOpen: onOpen,
                onTogglePin: onTogglePin,
                onMore: onMore,
              );
            },
          ),
        ),
        if (notes.isNotEmpty && hasMore) const _PaginationIndicator(),
      ],
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({
    required this.note,
    required this.onOpen,
    required this.onTogglePin,
    required this.onMore,
  });

  final NoteModel note;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onTogglePin;
  final ValueChanged<NoteModel> onMore;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXL),
      padding: const EdgeInsets.all(AppTheme.spacingXXL),
      borderColor: Colors.transparent,
      borderWidth: 0,
      onTap: () => onOpen(note.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: note.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Başlıksız not' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18,
                  color: note.isPinned
                      ? AppTheme.primaryPink
                      : AppTheme.textTertiary,
                ),
                onPressed: () => onTogglePin(note.id),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onMore(note),
                child: const Icon(CupertinoIcons.ellipsis, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          if (note.category.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: _CategoryChip(category: note.category),
            ),
          const SizedBox(height: AppTheme.spacingXL),
          _NoteMetadataRow(note: note),
        ],
      ),
    );
  }
}

class _NoteGridTile extends StatelessWidget {
  const _NoteGridTile({
    super.key,
    required this.note,
    required this.onOpen,
    required this.onTogglePin,
    required this.onMore,
  });

  final NoteModel note;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onTogglePin;
  final ValueChanged<NoteModel> onMore;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      borderColor: Colors.transparent,
      borderWidth: 0,
      onTap: () => onOpen(note.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              gradient: LinearGradient(
                colors: [
                  note.color.withOpacity(0.9),
                  note.color.withOpacity(0.4),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            note.title.isEmpty ? 'Başlıksız not' : note.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Align(
            alignment: Alignment.centerLeft,
            child: _CategoryChip(category: note.category),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: note.isPinned
                        ? AppTheme.primaryPink
                        : AppTheme.textTertiary,
                  ),
                  onPressed: () => onTogglePin(note.id),
                ),
                const SizedBox(width: AppTheme.spacingXS),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onPressed: () => onMore(note),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteMetadataRow extends StatelessWidget {
  const _NoteMetadataRow({required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Row(children: [_NoteMetaChips(note: note)]);
  }
}

class _NoteMetaChips extends StatelessWidget {
  const _NoteMetaChips({required this.note});

  final NoteModel note;

  List<Widget> _buildChips() {
    final chips = <Widget>[];
    if (note.hasDrawing) {
      chips.add(_MetaChip(icon: Icons.draw, label: 'Çizim'));
    }
    if (note.todos.isNotEmpty) {
      chips.add(
        _MetaChip(
          icon: Icons.check_circle_outline,
          label: '${note.todos.length} görev',
        ),
      );
    }
    if (note.attachments.isNotEmpty) {
      chips.add(
        _MetaChip(icon: Icons.attachment, label: '${note.attachments.length}'),
      );
    }
    if (chips.isEmpty) {
      chips.add(_MetaChip(icon: Icons.edit_note_outlined, label: 'Not'));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: _buildChips(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            label,
            style: AppTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = context.read<NotesProvider>().categoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Text(
        label,
        style: AppTheme.textTheme.labelMedium?.copyWith(
          color: AppTheme.primaryPink,
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        curve: AppTheme.animationCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPink.withOpacity(0.18)
              : AppTheme.backgroundTertiary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPink.withOpacity(0.4)
                : AppTheme.borderLight.withOpacity(0.6),
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.primaryPink : AppTheme.textPrimary,
            fontWeight: isSelected
                ? AppTheme.fontWeightSemiBold
                : AppTheme.fontWeightMedium,
          ),
        ),
      ),
    );
  }
}

class _PaginationIndicator extends StatelessWidget {
  const _PaginationIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXXL),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXXL,
            vertical: AppTheme.spacingL,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppTheme.spacingM),
              Text('Daha fazla not yükleniyor...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNoteButton extends StatelessWidget {
  const _AddNoteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.buttonShadow,
        ),
        alignment: Alignment.center,
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
