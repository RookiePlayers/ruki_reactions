import 'package:flutter/material.dart';


extension ColorExtention on Color {
  Color withShade(double factor) => ColorMisc.withShade(this, factor);

  Color withTint(double factor) => ColorMisc.withTint(this, factor);
}
class ColorMisc {
  ///This class Applies values to colors and return either a darker shade or lighter tone of the same color

  ///shade_factor < 1.0
  static Color withShade(Color color, num shade_factor) {
    var r = color.red * (1 - shade_factor);
    var g = color.green * (1 - shade_factor);
    var b = color.blue * (1 - shade_factor);
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), color.opacity);
  }

  ///tint_factor < 1.0
  static Color withTint(Color color, num tint_factor) {
    var r = color.red + (255 - color.red) * tint_factor;
    var g = color.green + (255 - color.green) * tint_factor;
    var b = color.blue + (255 - color.blue) * tint_factor;
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), color.opacity);
  }

  static Color nameToColor(String name) {
    assert(name.length > 1);
    final int hash = name.hashCode & 0xffff;
    final double hue = (360.0 * hash / (1 << 15)) % 360.0;
    return new HSVColor.fromAHSV(1.0, hue, 0.4, 0.90).toColor();
  }
}