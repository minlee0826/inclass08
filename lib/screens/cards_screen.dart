import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/playing_card.dart';
import '../repositories/card_repository.dart';
import 'add_edit_card_screen.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final repo = CardRepository();
  late Future<List<PlayingCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _cardsFuture = repo.getCardsByFolder(widget.folder.id!);
  }

  void _refresh() {
    setState(() {
      _cardsFuture = repo.getCardsByFolder(widget.folder.id!);
    });
  }

  String _guessCode(String rank, String suit) {
    final r = switch (rank) {
      'Ace' => 'A',
      'Jack' => 'J',
      'Queen' => 'Q',
      'King' => 'K',
      _ => rank,
    };
    final s = switch (suit) {
      'Spades' => 'S',
      'Hearts' => 'H',
      'Diamonds' => 'D',
      'Clubs' => 'C',
      _ => 'S',
    };
    return '$r$s';
  }

  Widget _cardImage(PlayingCard c) {
    final code = _guessCode(c.cardName, c.suit);
    final fallbackUrl = 'https://deckofcardsapi.com/static/img/$code.png';

    final url = c.imageUrl?.trim();
    if (url != null && url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 60,
        height: 90,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Image.network(fallbackUrl, width: 60, height: 90, fit: BoxFit.contain),
      );
    }
    if (url != null && url.startsWith('http')) {
      return Image.network(url, width: 60, height: 90, fit: BoxFit.contain);
    }
    return Image.network(fallbackUrl, width: 60, height: 90, fit: BoxFit.contain);
  }

  Future<void> _deleteCard(PlayingCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Delete ${card.cardName} of ${card.suit}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    await repo.deleteCard(card.id!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card deleted')),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folder.folderName} Cards')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditCardScreen(
                folderId: widget.folder.id!,
                folderName: widget.folder.folderName,
              ),
            ),
          );
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PlayingCard>>(
        future: _cardsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final cards = snap.data ?? [];
          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this folder.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final c = cards[i];
              return Card(
                child: ListTile(
                  leading: _cardImage(c),
                  title: Text('${c.cardName} of ${c.suit}'),
                  subtitle: Text('ID: ${c.id} • FolderID: ${c.folderId}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditCardScreen(
                                folderId: widget.folder.id!,
                                folderName: widget.folder.folderName,
                                existing: c,
                              ),
                            ),
                          );
                          _refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteCard(c),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}