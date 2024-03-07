import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animator/flutter_animator.dart';
import 'package:ruki_reactions/components/reaction_widget.dart';
import 'package:ruki_reactions/misc/flutter_scale_tab.dart';
import 'package:ruki_reactions/ruki_reactions.dart';

class CustomizableListController {
  Function() refresh = () {};
}

class CustomizableList extends StatefulWidget {
  final Future<List<String>> Function() getCustomReactions;
  final Function(String)? onReactionSelected;
  final Function(String)? onChangeReactionSelected;
  final EmojiStyle emojiStyle;
  final int limit;
  final Size? size;
  final CustomizableListController? controller;
  final bool disableVariation;
  final bool showVariationsOnHold;
  const CustomizableList(
      {super.key,
      required this.getCustomReactions,
      required this.onReactionSelected,
      required this.onChangeReactionSelected,
      this.disableVariation = false,
      this.showVariationsOnHold = false,
      this.controller,
      this.emojiStyle = const EmojiStyle(),
      this.size,
      this.limit = 5});
  @override
  CustomizableListState createState() => CustomizableListState();
}

class CustomizableListState extends State<CustomizableList> {
  bool editMode = false;
  String? selectedReaction;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.refresh = () {
        if (mounted) {
          setState(() {
            editMode = false;
            selectedReaction = null;
          });
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildCustomizableEmojiList(context),
    );
  }

  _buildCustomizableEmojiList(BuildContext contecxt) {
    return FutureBuilder(
      future: widget.getCustomReactions(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.hasData) {
            List<String> reactions = snapshot.data as List<String>;
            reactions = reactions
                .toSet()
                .toList()
                .sublist(0, min(widget.limit, reactions.length));
            return SizedBox(
              // width: size?.width ?? MediaQuery.of(context).size.width * 0.6,
              height: widget.emojiStyle.size * 2.6,
              child: Column(
                children: [
                  Text(
                    (editMode
                            ? 'Choose a Replacement Below'
                            : 'Hold to customize reaction')
                        .toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontSize: 10),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reactions.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: ScaleTap(
                              onLongPress: () {
                                selectedReaction = reactions[index];
                                _handleEmojiSelected();
                              },
                              child: AnimatedOpacity(
                                opacity: editMode &&
                                        selectedReaction != reactions[index]
                                    ? 0.4
                                    : 1,
                                duration: const Duration(milliseconds: 300),
                                child: Pulse(
                                  preferences: AnimationPreferences(
                                    autoPlay: editMode
                                        ? selectedReaction == reactions[index]
                                            ? AnimationPlayStates.Loop
                                            : AnimationPlayStates.None
                                        : AnimationPlayStates.None,
                                  ),
                                  child: ReactionWidget(
                                    disableDefaultAction: editMode,
                                    onReactionSelected: (s) {
                                      if (!editMode) {
                                        widget.onReactionSelected?.call(s);
                                        return;
                                      }
                                      setState(() {
                                        editMode = false;
                                      });
                                    },
                                    disableVariations: widget.disableVariation,
                                    showVariationsOnHold: false,
                                    emojiStyle: const EmojiStyle(size: 24),
                                    reaction: reactions[index],
                                  ),
                                ),
                              )),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  _handleEmojiSelected() {
    setState(() {
      editMode = true;
    });

    widget.onChangeReactionSelected?.call(selectedReaction!);
  }
}
