import 'package:flutter_test/flutter_test.dart';
import 'package:ruki_reactions/reaction.dart';


void main() {
  //test react provider
  test('ReactionProvider', () {
    ReactionProvider provider = ReactionProvider();
    expect(provider.maxCustomEmojis, 5);
    provider.maxCustomEmojis = 10;
    expect(provider.maxCustomEmojis, 10);
  });

}
