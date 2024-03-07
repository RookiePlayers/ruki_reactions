import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:ruki_reactions/ruki_reactions.dart';

import 'lazy_loading_emojis.dart';
import 'reaction_widget.dart';

class MoreReactionsPageView extends StatelessWidget {
  final PageController pageController;
  final bool useHistory;
  final EmojiGroup selectedGroup;
  final List<EmojiGroup> emojiGroups;
  final Function(String)? onReactionSelected;
  final Function(EmojiGroup)? onGroupSelected;
  final Function(int)? onPageChanged;
  final EmojiStyle emojiStyle;
  final Widget recenclyUsed;
  final bool disableDefaultAction;
  final bool disableSkinToneGrouping;
  final double emojiHorizontalFit;
  final double emojiVerticalFit;
  final bool showVariationsOnHold;

  const MoreReactionsPageView(
      {super.key,
      required this.pageController,
      required this.selectedGroup,
      required this.emojiGroups,
      this.emojiHorizontalFit = 0.4,
      this.emojiVerticalFit = 0.4,
      this.onGroupSelected,
      this.onPageChanged,
      this.onReactionSelected,
      this.useHistory = true,
      this.disableDefaultAction = false,
      this.disableSkinToneGrouping = false,
      this.showVariationsOnHold = false,
      required this.recenclyUsed,
      this.emojiStyle = const EmojiStyle()});
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
        controller: pageController,
        itemCount: EmojiGroup.objects.all.length + (useHistory ? 1 : 0),
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          if (useHistory && index == 0) {
            return recenclyUsed;
          }
          EmojiGroup e = (index == 0 && useHistory)
              ? EmojiGroup.component
              : EmojiGroup.objects.all[index - (useHistory ? 1 : 0)];

          List<String> emojis = EmojiExt.sortEmojis(
              emojiList: Emoji.byGroup(e).toList(),
              skinToneGrouping: !disableSkinToneGrouping);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  e.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: LazyLoadingEmojis(
                  size: MediaQuery.of(context).size,
                  horizontalFit: emojiHorizontalFit,
                  verticalFit: emojiVerticalFit,
                  emojis: emojis,
                  useGridView: true,
                  selectedGroup: selectedGroup,
                  onGroupSelected: onGroupSelected,
                  builder: (emoji) => ReactionWidget(
                    disableDefaultAction: disableDefaultAction,
                    onReactionSelected: onReactionSelected,
                    disableVariations: disableSkinToneGrouping,
                    showVariationsOnHold: showVariationsOnHold,
                    emojiStyle: emojiStyle,
                    reaction: emoji ?? '',
                  ),
                  emojiStyle: emojiStyle,
                ),
              )
            ],
          );
        });
  }
}
