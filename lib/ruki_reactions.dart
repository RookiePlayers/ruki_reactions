import 'dart:math';

import 'package:emojis/emoji.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ruki_reactions/color_extensions.dart';
import 'package:ruki_reactions/misc/flutter_scale_tab.dart';
import 'package:ruki_reactions/reaction.dart';

import 'components/more_reactions.dart';
import 'components/reaction_widget.dart';

enum ReactionsMoreViewMode { popup, bottomSheet }

class EmojiStyle {
  final double size;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  const EmojiStyle({this.size = 20, this.backgroundColor, this.borderRadius});
}

class ReactionsController {
  Function clearHistory = () {};
  Function addCustomReaction = (String r) {};
  Function removeCustomReaction = (String r) {};
  Function clearAllCustomReactions = () {};
}

class Reactions extends StatefulWidget {
  final Function(String)? onReactionSelected;
  final List<String>? customDefaultReactions;
  final ReactionsMoreViewMode moreViewMode;
  final ReactionsController? controller;
  final bool allowMoreView;
  final Icon? moreIcon;
  final EmojiStyle emojiStyle;
  final EmojiStyle? moreEmojiStyle;
  final bool useHistory;
  final Size? size;
  final bool displayEmojiGroups;
  final int limit;
  final bool enableCustom;
  final bool diableSkinToneGroupingForMoreView;
  final bool disableSkinTone;
  final int? recentEmojiPerPage;
  final Color? backgroundColor;
  final double? emojiHorizontalFit;
  final double? emojiVerticalFit;
  final bool showVariationsOnHold;
  final bool leadingMoreButton;
  final Widget? customLoader;

  Reactions(
      {super.key,
      this.onReactionSelected,
      this.useHistory = true,
      this.customLoader,
      this.controller,
      this.customDefaultReactions,
      this.allowMoreView = true,
      this.enableCustom = false,
      this.disableSkinTone = true,
      this.showVariationsOnHold = true,
      this.diableSkinToneGroupingForMoreView = false,
      this.leadingMoreButton = false,
      this.recentEmojiPerPage,
      this.moreViewMode = ReactionsMoreViewMode.popup,
      this.moreIcon,
      this.size,
      this.limit = 6,
      this.emojiHorizontalFit,
      this.emojiVerticalFit,
      this.backgroundColor,
      this.displayEmojiGroups = false,
      this.moreEmojiStyle = const EmojiStyle(),
      this.emojiStyle = const EmojiStyle()}) {
    //check for a valid emoji
    if (customDefaultReactions != null) {
      //assert(customDefaultReactions!.any((element) => !RegExp('[:;][a-zA-Z0-9_]+').hasMatch(element)));
    }
    if (customDefaultReactions != null) {
      defaultReactions.addAll(customDefaultReactions!);
    }
    addAllDefaultToCustom();
  }

  @override
  State<Reactions> createState() => _ReactionsState();
}

class _ReactionsState extends State<Reactions> {
  String? emojiToReplace;

  final ReactionWidgetController _reactionWidgetController =
      ReactionWidgetController();

  int cappedLimit = 6;
  @override
  void initState() {
    cappedLimit = min(widget.limit, defaultReactions.length + (widget.customDefaultReactions?.length ?? 0));
    if(widget.limit > defaultReactions.length  + (widget.customDefaultReactions?.length ?? 0)){
      if(kDebugMode){
        print('Limit is greater than default reactions (${defaultReactions.length}), feel free to add custom reactions');
      }
    }
    super.initState();
    if (widget.controller != null) {
      widget.controller!.clearHistory = () {
        ReactionProvider.instance.clearHistory();
        setState(() {});
      };
      widget.controller!.addCustomReaction = (String r) {
        ReactionProvider.instance.insert(Reaction(
            emoji: r, timestamp: DateTime.now().millisecondsSinceEpoch));
        setState(() {});
      };
      widget.controller!.removeCustomReaction = (String r) {
        ReactionProvider.instance.removeCustomReaction(r);
        setState(() {});
      };
      widget.controller!.clearAllCustomReactions = () {
        ReactionProvider.instance.clearCustomReactions();
        setState(() {});
      };
    }
  }

  @override
  void dispose() {
    ReactionProvider.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildFromCustomEmoji(context),
    );
  }

  Widget _buildFromCustomEmoji(BuildContext context) {
    return FutureBuilder(
      future: widget.enableCustom
          ? getCustomReactions(limit: cappedLimit)
          : getRecentlyAdded(
              limit: cappedLimit,
              customDefaultReactions: widget.customDefaultReactions),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.runtimeType != List<String>) {
            return _buildReactions(context, defaultReactions);
          }
          List<String> reactions = snapshot.data as List<String>;
          reactions = reactions.toSet().toList();
          if (reactions.length < cappedLimit) {
            reactions.addAll(defaultReactions);
          }
          reactions = reactions.toSet().toList().sublist(0, cappedLimit);
          return _buildReactions(context, reactions);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return widget.customLoader ??
            Container(
              constraints: BoxConstraints(maxHeight: widget.emojiStyle.size),
              child: ListView.builder(
                itemCount: cappedLimit,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    width: widget.emojiStyle.size,
                    height: widget.emojiStyle.size,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: widget.emojiStyle.backgroundColor ??
                          Theme.of(context).cardColor.withOpacity(0.5),
                      borderRadius: widget.emojiStyle.borderRadius ??
                          BorderRadius.circular(5),
                    ),
                  );
                },
                scrollDirection: Axis.horizontal,
              ),
            );
      },
    );
  }

  Widget _buildReactions(BuildContext context, List<String> reactions) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.emojiStyle.size * 2),
      child: ListView.builder(
        itemCount: reactions.length + (widget.allowMoreView ? 1 : 0),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          if (widget.leadingMoreButton && index == 0 && widget.allowMoreView) {
            return _buildMoreButton(context);
          }
          if (!widget.leadingMoreButton &&
              index == reactions.length &&
              widget.allowMoreView) {
            return _buildMoreButton(context);
          }
          return _buildReaction(
              reactions[index - (widget.leadingMoreButton ? 1 : 0)], context);
        },
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  _buildReaction(String reaction, BuildContext context) {
    return ReactionWidget(
      onReactionSelected: (s) {
        setState(() {});
        widget.onReactionSelected?.call(s);
      },
      disableDefaultAction: true,
      disableVariations: widget.disableSkinTone,
      showVariationsOnHold: widget.showVariationsOnHold,
      emojiStyle: widget.emojiStyle,
      reaction: reaction,
    );
  }

  _buildMoreButton(BuildContext context) {
    return ScaleTap(
      onPressed: () {
        if (widget.moreViewMode == ReactionsMoreViewMode.popup) {
          _openPopUp(context);
        } else {
          _openBottomSheet(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        child: widget.moreIcon ??
            Icon(Icons.add_circle_outline_rounded,
                size: widget.emojiStyle.size * 1.4),
      ),
    );
  }

  _openPopUp(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: MediaQuery.of(context).size.width),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  Theme.of(context).cardColor.withShade(0.01),
              borderRadius: BorderRadius.circular(20),
            ),
            child: MoreReactions(
              enableCustomization: widget.enableCustom,
              maxRecentEmojis: widget.recentEmojiPerPage,
              emojiHorizontalFit: widget.emojiHorizontalFit ?? 0.3,
              emojiVerticalFit: widget.emojiVerticalFit ?? 0.3,
              key: UniqueKey(),
              useHistory: widget.useHistory,
              displayEmojiGroups: widget.displayEmojiGroups,
              disableDefaultAction: emojiToReplace != null,
              diableSkinToneGrouping: widget.diableSkinToneGroupingForMoreView,
              showVariationsOnHold: widget.showVariationsOnHold,
              reactionWidgetController: _reactionWidgetController,
              onReactionSelected: widget.onReactionSelected,
              customReactionLimit: cappedLimit,
              emojiStyle: widget.emojiStyle,
              size: widget.size,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        );
      },
    );
  }

  _openBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: MoreReactions(
                enableCustomization: widget.enableCustom,
                maxRecentEmojis: widget.recentEmojiPerPage,
                key: UniqueKey(),
                useHistory: widget.useHistory,
                displayEmojiGroups: widget.displayEmojiGroups,
                disableDefaultAction: emojiToReplace != null,
                diableSkinToneGrouping:
                    widget.diableSkinToneGroupingForMoreView,
                showVariationsOnHold: widget.showVariationsOnHold,
                reactionWidgetController: _reactionWidgetController,
                onReactionSelected: widget.onReactionSelected,
                customReactionLimit: cappedLimit,
                emojiStyle: widget.emojiStyle,
                emojiHorizontalFit: widget.emojiHorizontalFit ?? 0.3,
                emojiVerticalFit: widget.emojiVerticalFit ?? 0.3,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
              ),
            ));
      },
    );
    setState(() {});
  }
}

extension EmojiGroupExt on EmojiGroup {
  List<EmojiGroup> get all => [
        EmojiGroup.smileysEmotion,
        EmojiGroup.peopleBody,
        EmojiGroup.animalsNature,
        EmojiGroup.foodDrink,
        EmojiGroup.activities,
        EmojiGroup.travelPlaces,
        EmojiGroup.objects,
        EmojiGroup.symbols,
        EmojiGroup.flags
      ];
  IconData get icon {
    switch (this) {
      case EmojiGroup.peopleBody:
        return Icons.people_alt_rounded;
      case EmojiGroup.animalsNature:
        return Icons.pets;
      case EmojiGroup.foodDrink:
        return Icons.fastfood;
      case EmojiGroup.activities:
        return Icons.sports_soccer_rounded;
      case EmojiGroup.travelPlaces:
        return Icons.airplanemode_active;
      case EmojiGroup.smileysEmotion:
        return Icons.tag_faces;
      case EmojiGroup.component:
        return Icons.build;
      case EmojiGroup.objects:
        return Icons.lightbulb;
      case EmojiGroup.symbols:
        return Icons.emoji_symbols_sharp;
      case EmojiGroup.flags:
        return Icons.flag;
      default:
        return Icons.tag_faces;
    }
  }

  String get name {
    switch (this) {
      case EmojiGroup.peopleBody:
        return 'People';
      case EmojiGroup.animalsNature:
        return 'Animals & Nature';
      case EmojiGroup.foodDrink:
        return 'Food & Drink';
      case EmojiGroup.activities:
        return 'Activities';
      case EmojiGroup.travelPlaces:
        return 'Travel & Places';
      case EmojiGroup.smileysEmotion:
        return 'Smileys & Emotion';
      case EmojiGroup.component:
        return 'Things';
      case EmojiGroup.objects:
        return 'Objects';
      case EmojiGroup.symbols:
        return 'Symbols';
      case EmojiGroup.flags:
        return 'Flags';
      default:
        return '';
    }
  }
}

extension EmojiExt on Emoji {
  List<String> getVariations(
      {bool skin = true, bool hair = false, bool gender = false}) {
    // i want to get all variations of an emoji including skin tone, hair color and gender
    // i.e.
    // [👩🏻‍🦰, 👩🏼‍🦰, 👩🏽‍🦰, 👩🏾‍🦰, 👩🏿‍🦰]

    List<String> variations = [];
    if (skin) {
      for (var skinTone in fitzpatrick.values) {
        Emoji? emoji = Emoji.byChar(char);
        if (emoji == null) continue;
        String modified = Emoji.modify(char, skinTone);
        if (modified == char) continue;
        variations.add(modified);
      }
      if (variations.isNotEmpty) {
        variations.insert(0, char);
      }
    }

    return variations;
  }

  static List<String> sortEmojis(
      {List<Emoji>? emojiList,
      bool skinToneGrouping = true,
      List<EmojiGroup> customOrder = const [
        EmojiGroup.smileysEmotion,
        EmojiGroup.peopleBody,
        EmojiGroup.animalsNature,
        EmojiGroup.foodDrink,
        EmojiGroup.travelPlaces,
        EmojiGroup.activities,
        EmojiGroup.objects,
        EmojiGroup.symbols,
        EmojiGroup.flags,
        EmojiGroup.component
      ]}) {
    Map<EmojiGroup, List<String>> emojis = {};
    List<String> stablized = [];
    for (var emoji in emojiList ?? Emoji.all()) {
      if (emojis[emoji.emojiGroup] == null) {
        emojis[emoji.emojiGroup] = [];
      }
      if (skinToneGrouping) {
        if (stablized.contains(Emoji.stabilize(emoji.char))) continue;
        if (emoji.name.contains(":")) continue;
        stablized.add(Emoji.stabilize(emoji.char));
      }
      emojis[emoji.emojiGroup]!.add(emoji.char);
    }

    List<String> sorted = [];
    for (var group in customOrder) {
      if (emojis[group] != null) {
        sorted.addAll(emojis[group]!);
      }
    }
    return sorted;
  }
}
