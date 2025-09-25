import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/screens/note_detail_screen.dart';
import 'package:thanette/src/widgets/thanette_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/providers/supabase_service.dart';
import 'package:thanette/src/widgets/color_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

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

  void _showColorPickerForNote(note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
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
    );
  }

  void _showNoteMenu(note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: note.color ?? Colors.grey,
                    ),
                    title: const Text('Rengi Değiştir'),
                    onTap: () {
                      Navigator.pop(context);
                      _showColorPickerForNote(note);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Notu Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(note);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<NotesProvider>().deleteNoteRemote(note.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>().items;
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  children: [
                    // Top row with mini menu button
                    Row(
                      children: [
                        Builder(
                          builder: (ctx) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEC60FF,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              tooltip: 'Menü',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Logo and title row
                    Row(
                      children: [
                        const ThanetteLogo(size: 40),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notların',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                'Tüm düşüncelerine tek yerden ulaş',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${notes.length} not',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          context.read<NotesProvider>().searchNotes(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Notlarında ara...',
                          prefixIcon: const Icon(
                            Icons.search_outlined,
                            color: Color(0xFF6B7280),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF6B7280),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<NotesProvider>().clearSearch();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes grid
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesGrid(notes, provider),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC60FF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            Navigator.of(context).pushNamed(
              NoteDetailScreen.route,
              arguments: const NoteDetailArgs(id: null),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final provider = context.watch<NotesProvider>();
    final isSearching = provider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC60FF).withOpacity(0.1),
                    const Color(0xFFFF4D79).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_outlined
                    : Icons.note_add_outlined,
                size: 60,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'Arama sonucu bulunamadı' : 'Henüz not yok',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? '"${provider.searchQuery}" için sonuç bulunamadı.\nFarklı kelimeler deneyin.'
                  : 'İlk notunu oluşturmak için\naşağıdaki butona dokun',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid(List notes, provider) {
    return Column(
      children: [
        Expanded(
          child: ReorderableGridView.count(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            onReorder: (oldIndex, newIndex) {
              // Pinlenmiş notlar sıralanamaz
              if (notes[oldIndex].isPinned) return;

              // Yeni index'i pinlenmiş notların sayısına göre ayarla
              final pinnedCount = notes.where((note) => note.isPinned).length;
              if (newIndex < pinnedCount) {
                newIndex = pinnedCount;
              }

              context.read<NotesProvider>().reorderNotes(oldIndex, newIndex);
            },
            children: notes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;

              // Define a set of beautiful gradient colors for variety
              final gradients = [
                [const Color(0xFFEC60FF), const Color(0xFFFF4D79)], // Pink-Red
                [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ], // Purple-Blue
                [
                  const Color(0xFF6EE7B7),
                  const Color(0xFF3B82F6),
                ], // Green-Blue
                [
                  const Color(0xFFFBBF24),
                  const Color(0xFFF59E0B),
                ], // Yellow-Orange
                [
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ], // Purple-Pink
                [const Color(0xFF10B981), const Color(0xFF059669)], // Green
              ];

              // Use note's actual color or fallback to index-based gradient
              final cardGradient = note.color != null
                  ? <Color>[note.color!, note.color!.withOpacity(0.7)]
                  : gradients[index % gradients.length];

              return GestureDetector(
                key: ValueKey(note.id),
                onTap: () => Navigator.of(context).pushNamed(
                  NoteDetailScreen.route,
                  arguments: NoteDetailArgs(id: note.id),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardGradient[0].withOpacity(0.1),
                        cardGradient[1].withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cardGradient[0].withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cardGradient[0].withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      // Note title centered
                      Center(
                        child: Text(
                          note.title.isEmpty ? 'Başlıksız not' : note.title,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Pin button - inset with pastel background and animations
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.read<NotesProvider>().togglePinRemote(
                                note.id,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: note.isPinned
                                    ? const Color(0xFFE91E63).withOpacity(0.2)
                                    : cardGradient[0].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: note.isPinned
                                      ? const Color(0xFFE91E63).withOpacity(0.4)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: note.isPinned
                                        ? const Color(
                                            0xFFE91E63,
                                          ).withOpacity(0.2)
                                        : cardGradient[0].withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                note.isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 16,
                                color: note.isPinned
                                    ? const Color(0xFFE91E63)
                                    : const Color(0xFF374151), // grey700
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Three dots menu - inset with pastel background and animations
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _showNoteMenu(note);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cardGradient[0].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: cardGradient[0].withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: const Color(0xFF374151), // grey700
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Drag handle - only for non-pinned notes
                      if (!note.isPinned)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: cardGradient[0].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: cardGradient[0].withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 16,
                                color: const Color(0xFF374151).withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Loading indicator at bottom
        if (notes.isNotEmpty && provider.hasMore)
          Container(
            height: 60,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFEC60FF),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Misafir';
    final displayName =
        (_profileName != null && _profileName!.trim().isNotEmpty)
        ? _profileName!
        : email;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              subtitle: Text(
                email,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            const Divider(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    try {
                      await Supabase.instance.client.auth.signOut();
                    } finally {
                      if (!mounted) return;
                      nav.pushNamedAndRemoveUntil(
                        LoginScreen.route,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Oturumu Sonlandır',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
