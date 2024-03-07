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
  int maxCustomEmojis;
  ReactionProvider({this.maxCustomEmojis = 5});
  Future<void> open() async {
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
        
    if (kDebugMode) {
      print('DB opened');
    }
  }

  Future<void> openCustomReactions() async {
    sqfliteFfiInit();
    final factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactoryFfi;
    db = await (kIsWeb
        ? factory.openDatabase('reactions.db')
        : sqflite.openDatabase('reactions.db'));
    if (db == null) {
      return Future.value(null);
    }
    await db!.execute('''CREATE TABLE IF NOT EXISTS $tableCutomEmoji ( 
            $columnId integer primary key autoincrement, 
            $columnEmoji text not null,
            $columnCount integer not null,
            $columnTimestamp integer not null)
          ''');
  }

  Future<Reaction?> insert(Reaction reaction) async {
    if (db == null) {
      await open();
    }
    if (db == null) {
      return Future.value(null);
    }
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
      await openCustomReactions();
    }
    if (db == null) {
      return Future.value(null);
      
    }
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
      await open();
    }
    if (db == null) {
      return Future.value(null);
    }
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
      await openCustomReactions();
    }
    if (db == null) {
      return Future.value([]);
    }
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
      openCustomReactions();
    }
    if (db == null) {
      return Future.value(null);
    }
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
      await open();
    }
    if (db == null) {
      return Future.value([]);
    }
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
      await open();
    }
    if (db == null) {
      return Future.value([]);
    }
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
      await open();
    }
    if (db == null) {
      return Future.value(0);
    }
    return await db!.update(table, reaction.toMap(),
        where: '$columnId = ?', whereArgs: [reaction.id]);
  }

  Future<void> close() async {
    if (db != null) {
      await db!.close();
    }
  }
}


final List<String> defaultReactions = [
  '😀',
  '😂',
  '😍',
  '😢',
  '😡',
  '👍',
  '👎'
];
Future<List<String>> getCustomReactions({int limit = 5}) async {
  ReactionProvider provider = ReactionProvider();
  List<Reaction> reactionsData =
      await provider.getCustomReactions(limit: limit);
  List<String> reactions = reactionsData.map((e) => e.emoji).toSet().toList();

  if (reactions.length < limit) {
    List<String> defaultReactionsData = await getRecentlyAdded();
    reactions.addAll(defaultReactionsData);
  }
  return reactions;
}

Future<bool> updateRecentlyAdded(String emoji) async {
  ReactionProvider provider = ReactionProvider();
  await provider.insert(
      Reaction(emoji: emoji, timestamp: DateTime.now().millisecondsSinceEpoch));
  return true;
}

//recently used reactions - custom reactions - most used reactions - default reactions
Future<List<String>> getRecentlyAdded({int limit = 5}) async {
  ReactionProvider provider = ReactionProvider();
  List<Reaction> reactionsData =
      await provider.getRecentlyUsedReactions(limit: limit);
  List<String> reactions = reactionsData.map((e) => e.emoji).toSet().toList();
  if (reactions.length < limit) {
    List<String> defaultReactionsData = await getMostUsedReactions();
    reactions.addAll(defaultReactionsData);
  }
  return reactions;
}

Future<List<String>> getMostUsedReactions({int limit = 5}) async {
  ReactionProvider provider = ReactionProvider();
  List<Reaction> reactionsData =
      await provider.getMostUsedReactions(limit: limit);
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
  ReactionProvider provider = ReactionProvider();
  List<String> reactions = (await provider.getCustomReactions())
      .map((e) => e.emoji)
      .take(limit)
      .toList();
  if (reactions.contains(newEmoji)) {
    return false;
  }
  await provider.insertCustomReactions(
      Reaction(
          emoji: newEmoji, timestamp: DateTime.now().millisecondsSinceEpoch),
      replace: emojiToReplace);
  onReplaced!(emojiToReplace);
  return true;
}

Future<bool> addAllDefaultToCustom() async {
  ReactionProvider provider = ReactionProvider();

  for (var reaction in defaultReactions.reversed) {
    await provider.insertCustomReactions(Reaction(
        emoji: reaction, timestamp: DateTime.now().millisecondsSinceEpoch));
  }
  return true;
}
