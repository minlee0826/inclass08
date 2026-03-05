import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../repositories/card_repository.dart';

class AddEditCardScreen extends StatefulWidget {
  final int folderId;
  final String folderName;
  final PlayingCard? existing;

  const AddEditCardScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    this.existing,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final repo = CardRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _imageCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.cardName ?? '');
    _imageCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final image = _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();

    try {
      if (widget.existing == null) {
        await repo.createCard(
          PlayingCard(
            cardName: name,
            suit: widget.folderName,
            imageUrl: image,
            folderId: widget.folderId,
          ),
        );
      } else {
        await repo.updateCard(
          widget.existing!.copyWith(
            cardName: name,
            suit: widget.folderName,
            imageUrl: image,
            folderId: widget.folderId,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing == null ? 'Card added' : 'Card updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Card' : 'Add Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Folder/Suit: ${widget.folderName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card name (Ace, 2, ... King)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Card name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image path or URL (optional)',
                  hintText: 'assets/cards/AS.png OR https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}