import '../database/database_helper.dart';
import '../models/playing_card.dart';

class CardRepository {
  Future<int> createCard(PlayingCard card) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('cards', card.toMap());
  }

  Future<List<PlayingCard>> getCardsByFolder(int folderId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );
    return rows.map((e) => PlayingCard.fromMap(e)).toList();
  }

  Future<int> updateCard(PlayingCard card) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Seeds 2–4 suit folders, and 13 cards per suit.
  /// Runs only if folders table is empty.
  Future<void> seedSuitsAndCards(int suitCount) async {
    final db = await DatabaseHelper.instance.database;

    final existing = await db.query('folders', limit: 1);
    if (existing.isNotEmpty) return;

    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'].take(suitCount).toList();
    final ranks = ['Ace','2','3','4','5','6','7','8','9','10','Jack','Queen','King'];

    await db.transaction((txn) async {
      for (final suit in suits) {
        final folderId = await txn.insert('folders', {
          'folder_name': suit,
          'timestamp': DateTime.now().toIso8601String(),
        });

        for (final rank in ranks) {
          final code = _deckApiCode(rank: rank, suit: suit);

          // ✅ We store the ONLINE URL so you don't need assets at all.
          final imageUrl = 'https://deckofcardsapi.com/static/img/$code.png';

          await txn.insert('cards', {
            'card_name': rank,
            'suit': suit,
            'image_url': imageUrl,
            'folder_id': folderId,
          });
        }
      }
    });
  }

  // ✅ FIXED: 10 maps to 0 for deckofcardsapi
  String _deckApiCode({required String rank, required String suit}) {
    final r = switch (rank) {
      'Ace' => 'A',
      'Jack' => 'J',
      'Queen' => 'Q',
      'King' => 'K',
      '10' => '0', // IMPORTANT
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
}