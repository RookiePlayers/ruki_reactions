
import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:ruki_reactions/misc/flutter_scale_tab.dart';
import 'package:ruki_reactions/reaction.dart';
import 'package:ruki_reactions/ruki_reactions.dart';

class ReactionWidgetController {
  Function(bool) diableDefaultSelectionAction = (bool b) {};
}

class ReactionWidget extends StatelessWidget {
  const ReactionWidget(
      {super.key,
      this.onReactionSelected,
      this.emojiStyle,
      this.disableDefaultAction = false,
      this.disableVariations = false,
      this.showVariationsOnHold = false,
      required this.reaction,
      this.controller});

  final Function(String r)? onReactionSelected;
  final EmojiStyle? emojiStyle;
  final String reaction;
  final bool disableDefaultAction;
  final ReactionWidgetController? controller;
  final bool disableVariations;
  final bool showVariationsOnHold;

  @override
  Widget build(BuildContext context) {
    List<String> variations = Emoji.byChar(reaction)?.getVariations() ?? [];
    return ScaleTap(
      onLongPress: disableDefaultAction || !showVariationsOnHold
          ? null
          : () {
              if (!disableVariations &&
                  variations.isNotEmpty &&
                  showVariationsOnHold) {
                _showVariations(context, variations);
              }
            },
      onPressed: () {
        if (!disableVariations &&
            variations.isNotEmpty &&
            !showVariationsOnHold) {
          _showVariations(context, variations);
        } else {
          _handleReact(context, reaction);
        }
      },
      child: Badge(
        isLabelVisible: !disableVariations && variations.isNotEmpty,
        alignment: Alignment.bottomRight,
        backgroundColor: Colors.transparent,
        label: Icon(
          Icons.arrow_drop_down_rounded,
          size: 18,
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: emojiStyle?.backgroundColor ?? Colors.transparent,
            borderRadius: emojiStyle?.borderRadius ?? BorderRadius.circular(5),
          ),
          child: Center(
              child: Text(reaction,
                  style: TextStyle(fontSize: emojiStyle?.size ?? 20))),
        ),
      ),
    );
  }

  Future<Object?> _showVariations(
      BuildContext context, List<String> variations) {
    return showPopover(
        context: context,
        height: (emojiStyle?.size ?? 30) * 2,
        arrowWidth: 10,
        transitionDuration: const Duration(milliseconds: 150),
        arrowHeight: 10,
        bodyBuilder: (ctx) => ListView.builder(
              itemCount: variations.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ReactionWidget(
                    emojiStyle: emojiStyle,
                    disableVariations: true,
                    reaction: variations[index],
                    disableDefaultAction: true,
                    onReactionSelected: (s) {
                      Navigator.of(context).pop();
                      _handleReact(context, s);
                    },
                  ),
                );
              },
            ));
  }

  void _handleReact(BuildContext context, String reaction) async {
    if (!disableDefaultAction) {
      ReactionProvider provider = ReactionProvider();
      await provider.insert(Reaction(
          emoji: reaction, timestamp: DateTime.now().millisecondsSinceEpoch));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    if (onReactionSelected != null) {
      onReactionSelected!(reaction);
    }
  }
}
