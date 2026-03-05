class Folder {
  final int? id;
  final String folderName;
  final String timestamp;

  Folder({
    this.id,
    required this.folderName,
    required this.timestamp,
  });

  Folder copyWith({
    int? id,
    String? folderName,
    String? timestamp,
  }) {
    return Folder(
      id: id ?? this.id,
      folderName: folderName ?? this.folderName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_name': folderName,
      'timestamp': timestamp,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      folderName: map['folder_name'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}