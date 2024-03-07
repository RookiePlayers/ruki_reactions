
import 'package:flutter/material.dart';
import 'package:ruki_reactions/color_extensions.dart';

class EmojiSearchField extends StatelessWidget {
  const EmojiSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSearchBar(context);
  }

  _buildSearchBar(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Emoji',
          hintStyle:
              Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          fillColor: Theme.of(context).cardColor.withTint(0.1),
          suffixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).cardColor.withShade(0.01))),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        ),
      ),
    );
  }
}

