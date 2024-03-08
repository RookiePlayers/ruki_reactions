import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const String tableName = 'reactions';
const String tableCutomEmoji = 'custom_emojis';
const String columnId = '_id';
const String columnEmoji = 'emoji';
const String columnTimestamp = 'timestamp';
const String columnCount = 'count';

class Reaction {
  int? id;
  String emoji;
  int count;
  int timestamp;

  Reaction({this.id, required this.emoji, this.count = 0, this.timestamp = 0});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnEmoji: emoji,
      columnCount: count,
      columnTimestamp: timestamp
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  Reaction.fromMap(Map<String, dynamic> map)
      : id = map[columnId],
        emoji = map[columnEmoji],
        count = map[columnCount],
        timestamp = map[columnTimestamp];
}

class ReactionProvider {
  Database? db;
  bool _isOpened = false;
  //make singleton
  static final ReactionProvider instance = ReactionProvider._internal();
  ReactionProvider._internal() {
    open();
  }

  Future<void> open() async {
    if (_isOpened && (db!=null && db!.isOpen)) return;
    try {
      sqfliteFfiInit();

      final factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactoryFfi;
      db = await (kIsWeb
          ? factory.openDatabase('reactions.db')
          : sqflite.openDatabase('reactions.db'));
      if (db == null) {
        return Future.value(null);
      }
      await db!.execute('''CREATE TABLE IF NOT EXISTS $tableName ( 
            $columnId integer primary key autoincrement, 
            $columnEmoji text not null,
            $columnCount integer not null,
            $columnTimestamp integer not null)
          ''');

      await db!.execute('''CREATE TABLE IF NOT EXISTS $tableCutomEmoji ( 
            $columnId integer primary key autoincrement, 
            $columnEmoji text not null,
            $columnCount integer not null,
            $columnTimestamp integer not null)
          ''');

      if (kDebugMode) {
        print('RukiReactions SQflite: DB opened');
      }
      _isOpened = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error opening db: $e');
      }
    }
  }

 Future<Reaction?> insert(Reaction reaction) async {
    if (db == null) {
      return Future.value(null);
    }
    await open();
    reaction.timestamp = DateTime.now().millisecondsSinceEpoch;
    if (await getReaction(reaction.emoji) != null) {
      reaction.count++;
      update(reaction);
    } else {
      reaction.id = await db!.insert(tableName, reaction.toMap());
    }

    return reaction;
  }

  Future<Reaction?> insertCustomReactions(Reaction reaction,
      {String? replace}) async {
    if (db == null) {
      return Future.value(null);
    }
    await open();
    reaction.timestamp = DateTime.now().millisecondsSinceEpoch;
    Reaction? existing =
        await getCustomReaction(emoji: replace ?? reaction.emoji);
    if (existing != null) {
      existing.emoji = reaction.emoji;
      update(existing, table: tableCutomEmoji);
    } else {
      reaction.id = await db!.insert(tableCutomEmoji, reaction.toMap());
    }

    return reaction;
  }

  Future<Reaction?> getReaction(String emoji) async {
    if (db == null) {
      return Future.value(null);
    }
    await open();
    List<Map<String, Object?>> maps = await db!.query(tableName,
        columns: [columnId, columnEmoji, columnCount, columnTimestamp],
        where: '$columnEmoji = ?',
        whereArgs: [emoji]);
    if (maps.isNotEmpty) {
      return Reaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Reaction>> getCustomReactions({int limit = 5}) async {
    if (db == null) {
      return Future.value([]);
    }
    await open();
    List<Map<String, Object?>> maps = await db!.query(tableCutomEmoji,
        columns: [columnId, columnEmoji, columnCount, columnTimestamp],
        limit: limit,
        orderBy: '$columnTimestamp DESC');
    return List.generate(maps.length, (i) {
      return Reaction.fromMap(maps[i]);
    });
  }

  Future<Reaction?> getCustomReaction({String? emoji, String? id}) async {
    if (emoji == null && id == null) {
      return Future.value(null);
    }
    if (db == null) {
      return Future.value(null);
    }
    await open();
    List<Map<String, Object?>> maps = await db!.query(tableCutomEmoji,
        columns: [columnId, columnEmoji, columnCount, columnTimestamp],
        where: emoji != null ? '$columnEmoji = ?' : '$columnId = ?',
        whereArgs: emoji != null ? [emoji] : [id]);
    if (maps.isNotEmpty) {
      return Reaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Reaction>> getRecentlyUsedReactions({int? limit}) async {
    if (db == null) {
      return Future.value([]);
    }
    await open();
    List<Map<String, Object?>> maps = await db!.query(tableName,
        columns: [columnId, columnEmoji, columnCount, columnTimestamp],
        limit: limit,
        orderBy: '$columnTimestamp DESC');
    return List.generate(maps.length, (i) {
      return Reaction.fromMap(maps[i]);
    });
  }

  Future<List<Reaction>> getMostUsedReactions({int limit = 5}) async {
    if (db == null) {
      return Future.value([]);
    }
    await open();
    List<Map<String, Object?>> maps = await db!.query(tableName,
        columns: [columnId, columnEmoji, columnCount, columnTimestamp],
        limit: limit,
        orderBy: '$columnCount DESC');
    return List.generate(maps.length, (i) {
      return Reaction.fromMap(maps[i]);
    });
  }

  Future<int> update(Reaction reaction, {String table = tableName}) async {
    if (db == null) {
      return Future.value(0);
    }
    await open();
    return await db!.update(table, reaction.toMap(),
        where: '$columnId = ?', whereArgs: [reaction.id]);
  }

  Future<bool> clearHistory() async {
    if (db == null) {
      return Future.value(false);
    }
    await open();
    await db!.delete(tableName);
    return true;
  }

  Future<bool> clearCustomReactions() async {
    if (db == null) {
      return Future.value(false);
    }
    await open();
    await db!.delete(tableCutomEmoji);
    return true;
  }

  Future<bool> removeCustomReaction(String emoji) async {
    if (db == null) {
      return Future.value(false);
    }
    await open();
    await db!
        .delete(tableCutomEmoji, where: '$columnEmoji = ?', whereArgs: [emoji]);
    return true;
  }

  Future<void> close() async {
    if (db != null) {
      await db!.close();
      _isOpened = false;
    }
  }
}

final List<String> defaultReactions = [
  '❤️',
  '😂',
  '😍',
  '😢',
  '😡',
  '👍',
  '👎',
  '👏',
  '🙌',
  '🤔',
  '🤣',
  '🤩',
  '🤪',
  '🥰',
  '🥺',
  '🥳',
  '🦄',
  '🦋',
  '🧐',
];
Future<List<String>> getCustomReactions({int limit = 5}) async {
  List<Reaction> reactionsData =
      await ReactionProvider.instance.getCustomReactions(limit: limit);
  List<String> reactions = reactionsData.map((e) => e.emoji).toSet().toList();

  if (reactions.length < limit) {
    List<String> defaultReactionsData = await getRecentlyAdded();
    reactions.addAll(defaultReactionsData);
  }
  return reactions;
}

Future<bool> updateRecentlyAdded(String emoji) async {
  await ReactionProvider.instance.insert(
      Reaction(emoji: emoji, timestamp: DateTime.now().millisecondsSinceEpoch));
  return true;
}

//recently used reactions - custom reactions - most used reactions - default reactions
Future<List<String>> getRecentlyAdded(
    {int limit = 5, List<String>? customDefaultReactions}) async {
  List<Reaction> reactionsData =
      await ReactionProvider.instance.getRecentlyUsedReactions(limit: limit);
  List<String> reactions = reactionsData.map((e) => e.emoji).toSet().toList();
  if (reactions.length < limit) {
    List<String> defaultReactionsData = await getMostUsedReactions();
    reactions.addAll(defaultReactionsData);
  }
  if (customDefaultReactions != null) {
    reactions.insertAll(0, customDefaultReactions);
  }
  return reactions.toSet().toList();
}

Future<List<String>> getMostUsedReactions({int limit = 5}) async {
  List<Reaction> reactionsData =
      await ReactionProvider.instance.getMostUsedReactions(limit: limit);
  List<String> reactions = reactionsData.map((e) => e.emoji).toSet().toList();
  if (reactions.length < defaultReactions.length) {
    reactions.addAll(defaultReactions);
  }
  return reactions;
}

Future<bool> replaceEmoji(
    {String? emojiToReplace,
    String newEmoji = "",
    int limit = 5,
    Function(String)? onReplaced}) async {
  if (emojiToReplace == null) return false;
  List<String> reactions =
      (await ReactionProvider.instance.getCustomReactions())
          .map((e) => e.emoji)
          .take(limit)
          .toList();
  if (reactions.contains(newEmoji)) {
    return false;
  }
  await ReactionProvider.instance.insertCustomReactions(
      Reaction(
          emoji: newEmoji, timestamp: DateTime.now().millisecondsSinceEpoch),
      replace: emojiToReplace);
  onReplaced!(emojiToReplace);
  return true;
}

Future<bool> addAllDefaultToCustom() async {
  for (var reaction in defaultReactions.reversed) {
    await ReactionProvider.instance.insertCustomReactions(Reaction(
        emoji: reaction, timestamp: DateTime.now().millisecondsSinceEpoch));
  }
  return true;
}
