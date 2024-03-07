
import 'dart:math';

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:ruki_reactions/ruki_reactions.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyLoadingController {
  Function? loadMore = () {};
}

class LazyLoadingEmojis extends StatefulWidget {
  final Size? size;
  final EmojiStyle emojiStyle;
  final Widget Function(String?) builder;
  final LazyLoadingController? controller;
  final List<String> emojis;
  final List<String>? headerEmojis;
  final Function(EmojiGroup)? onGroupSelected;
  final EmojiGroup? selectedGroup;
  final bool useGridView;
  final ScrollPhysics? gridViewScrollPhysics;
  final double horizontalFit;
  final double verticalFit;
  const LazyLoadingEmojis(
      {super.key,
      this.size,
      required this.builder,
      required this.emojis,
      this.headerEmojis,
      this.horizontalFit = 0.4,
      this.verticalFit = 0.4,
      this.onGroupSelected,
      this.selectedGroup,
      this.useGridView = false,
      this.controller,
      this.gridViewScrollPhysics,
      this.emojiStyle = const EmojiStyle()})
      : assert(horizontalFit > 0 && horizontalFit <= 1,
            "horizontalFit must be between 0 and 1 | where 0 is 0% and 1 is 100%");

  @override
  LazyLoadingEmojisState createState() => LazyLoadingEmojisState();
}

class LazyLoadingEmojisState extends State<LazyLoadingEmojis>
    with AutomaticKeepAliveClientMixin {
  List<String> items = [];
  int currentPointer = 0;
  int limit = 20;
  bool isLoading = false;
  List<String> emojis = [];
  int horizontalFit = 10;
  int verticalFit = 10;
  EmojiGroup? selectedGroup;
  Map<num, EmojiGroup> pageIndexTracker = {};
  Map<String, UniqueKey> groupEmojiTracker = {};
  @override
  void initState() {
    emojis = widget.emojis;
    selectedGroup = widget.selectedGroup;
    populateGroupEmojiTracker();
    super.initState();
    // Simulate initial data loading
    if (widget.controller != null) {
      widget.controller!.loadMore = () async {
        if (mounted) {
          setState(() {
            isLoading = true;
          });
          await _loadItems();
        }
      };
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < (verticalFit * 0.5).ceil(); i++) {
        _loadItems();
      }
    });
  }

  // @override
  // void didUpdateWidget(LazyLoadingEmojis oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.emojis != widget.emojis) {
  //     emojis = widget.emojis;
  //     items.clear();
  //     currentPointer = 0;
  //     for (int i = 0; i < (verticalFit * 0.5).ceil(); i++) {
  //       _loadItems();
  //     }
  //   }
  // }

  populateGroupEmojiTracker() {
    if (widget.onGroupSelected == null) return;
    EmojiGroup currentGroup =
        Emoji.byChar(emojis.first)?.emojiGroup ?? EmojiGroup.smileysEmotion;
    groupEmojiTracker[emojis.first] = UniqueKey();
    for (int i = 1; i < emojis.length; i++) {
      final group =
          Emoji.byChar(emojis[i])?.emojiGroup ?? EmojiGroup.smileysEmotion;
      if (currentGroup != group) {
        groupEmojiTracker[emojis[max(0, i - 1)]] = UniqueKey();
        groupEmojiTracker[emojis[i]] = UniqueKey();
        currentGroup = group;
      }
    }
  }

  Future<void> _loadItems() async {
    int maxLimit = min((currentPointer + 1) * horizontalFit, emojis.length);
    setState(() {
      // Add more items to the list
      if (items.length < emojis.length) {
        final emojiList =
            emojis.sublist(currentPointer * horizontalFit, maxLimit);
        items.addAll(emojiList);
        items.sublist(0, min(min(emojiList.length, limit), maxLimit));

        currentPointer++;
      }
      isLoading = false;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      // Load more items when user scrolls to the bottom (within 200 pixels)
      if (!isLoading) {
        setState(() {
          isLoading = true;
        });
        _loadItems();
      }
    }
    //check any key in the groupEmojiTracker is visible

    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    horizontalFit =
        (((widget.size?.width ?? MediaQuery.of(context).size.width)) /
                widget.emojiStyle.size)
            .floor();
    verticalFit =
        (((widget.size?.height ?? MediaQuery.of(context).size.height) /
                widget.emojiStyle.size)
            .floor());
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: widget.useGridView ? _gridViewVersion() : _sliverGridVersion(),
    );
  }

  SliverGrid _sliverGridVersion() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (horizontalFit * min(1, widget.horizontalFit)).ceil(),
        crossAxisSpacing: 2,
        mainAxisSpacing: 5,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          List<String> allEmojis = [];
          allEmojis.addAll(items);
          if (index == allEmojis.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return widget.onGroupSelected != null
              ? VisibilityDetector(
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction == 1) {
                      final group =
                          Emoji.byChar(allEmojis[index])?.emojiGroup ??
                              EmojiGroup.smileysEmotion;
                      if (selectedGroup != group) {
                        selectedGroup = group;
                        widget.onGroupSelected?.call(group);
                      }
                    }
                  },
                  key: groupEmojiTracker[allEmojis[index]] ?? UniqueKey(),
                  child: widget.builder(allEmojis[index]))
              : widget.builder(allEmojis[index]);
        },
        childCount: (items.length + (isLoading ? 1 : 0)),
      ),
    );
  }

  GridView _gridViewVersion() {
    return GridView.builder(
      shrinkWrap: true,
      physics: widget.gridViewScrollPhysics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (horizontalFit * min(1, widget.horizontalFit)).ceil(),
        crossAxisSpacing: 2,
        mainAxisSpacing: 5,
      ),
      itemCount: (items.length + (isLoading ? 1 : 0)),
      itemBuilder: (context, index) {
        List<String> allEmojis = [];
        allEmojis.addAll(items);
        if (index == allEmojis.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return widget.onGroupSelected != null
            ? VisibilityDetector(
                onVisibilityChanged: (info) {
                  if (info.visibleFraction == 1) {
                    final group = Emoji.byChar(allEmojis[index])?.emojiGroup ??
                        EmojiGroup.smileysEmotion;
                    if (selectedGroup != group) {
                      selectedGroup = group;
                      widget.onGroupSelected?.call(group);
                    }
                  }
                },
                key: groupEmojiTracker[allEmojis[index]] ?? UniqueKey(),
                child: widget.builder(allEmojis[index]))
            : widget.builder(allEmojis[index]);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
