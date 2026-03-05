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
  Map<int, int> _cardCounts = {};

  @override
  void initState() {
    super.initState();
    _loadFoldersWithCounts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSeeded();
    });
  }

  Future<void> _loadFoldersWithCounts() async {
    final folders = await folderRepo.getFolders();
    final counts = <int, int>{};
    for (var f in folders) {
      counts[f.id!] = await folderRepo.getCardCountForFolder(f.id!);
    }
    setState(() {
      _foldersFuture = Future.value(folders);
      _cardCounts = counts;
    });
  }

  void _refresh() {
    _loadFoldersWithCounts();
  }

  Future<void> _ensureSeeded() async {
    final folders = await folderRepo.getFolders();
    if (folders.isNotEmpty) return;

    final suitCount = await _pickSuitCount();
    if (suitCount == null) return;

    await cardRepo.seedSuitsAndCards(suitCount);
    _refresh();
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

  Future<void> _deleteFolder(Folder folder) async {
    final count = _cardCounts[folder.id] ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Are you sure you want to delete "${folder.folderName}"?\n\n'
          'This will also delete all $count cards in this folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await folderRepo.deleteFolder(folder.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder "${folder.folderName}" deleted')),
      );
      _refresh();
    }
  }

  IconData _iconForSuit(String suit) {
    return switch (suit) {
      'Hearts' => Icons.favorite,
      'Diamonds' => Icons.change_history,
      'Clubs' => Icons.local_florist,
      'Spades' => Icons.eco, // Fixed: was Icons.change_history
      _ => Icons.folder,
    };
  }

  Color _colorForSuit(String suit) {
    return switch (suit) {
      'Hearts' || 'Diamonds' => Colors.red,
      'Clubs' || 'Spades' => Colors.black,
      _ => Colors.grey,
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
              final cardCount = _cardCounts[f.id] ?? 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    _iconForSuit(f.folderName),
                    color: _colorForSuit(f.folderName),
                    size: 32,
                  ),
                  title: Text(
                    f.folderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$cardCount cards'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFolder(f),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CardsScreen(folder: f)),
                    );
                    _refresh();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}