import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository folderRepo = FolderRepository();
  final CardRepository cardRepo = CardRepository();

  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = folderRepo.getFolders();

    // Trigger seeding after first frame so dialog works reliably
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSeeded();
    });
  }

  Future<void> _ensureSeeded() async {
    final folders = await folderRepo.getFolders();
    if (folders.isNotEmpty) return;

    final suitCount = await _pickSuitCount();
    if (suitCount == null) return;

    await cardRepo.seedSuitsAndCards(suitCount);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _foldersFuture = folderRepo.getFolders();
    });
  }

  Future<int?> _pickSuitCount() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose number of suits'),
        content: const Text('Select 2, 3, or 4 suits (13 cards per suit).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 2), child: const Text('2 suits')),
          TextButton(onPressed: () => Navigator.pop(ctx, 3), child: const Text('3 suits')),
          TextButton(onPressed: () => Navigator.pop(ctx, 4), child: const Text('4 suits')),
        ],
      ),
    );
  }

  IconData _iconForSuit(String suit) {
    return switch (suit) {
      'Hearts' => Icons.favorite,
      'Spades' => Icons.change_history,
      'Diamonds' => Icons.diamond,
      'Clubs' => Icons.local_florist,
      _ => Icons.folder,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suit Folders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Folder>>(
        future: _foldersFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final folders = snap.data ?? [];

          // IMPORTANT: show something if empty
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No folders found.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _ensureSeeded,
                    child: const Text('Seed 2–4 suits'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (ctx, i) {
              final f = folders[i];
              return ListTile(
                leading: Icon(_iconForSuit(f.folderName)),
                title: Text(f.folderName),
                subtitle: Text('Tap to view cards'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CardsScreen(folder: f)),
                  );
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}