pragma Singleton
import QtQuick
QtObject {
  property color background: "#18130b"
  property color surface: "#18130b"
  property color surfaceBright: "#3f382f"
  property color surfaceDim: "#18130b"
  property color surfaceContainer: "#241f17"
  property color surfaceVariant: "#4f4539"
  property color primary: "#f2be6e"
  property color primaryFg: "#442c00"
  property color secondary: "#dcc3a1"
  property color tertiary: "#b6cea3"
  property color backgroundFg: "#ede1d4"
  property color surfaceFg: "#ede1d4"
  property color surfaceVariantFg: "#d2c4b4"
  property color outline: "#9b8f80"
  property color outlineVariant: "#4f4539"
  property color error: "#ffb4ab"
  property color accent: primary
  property color surfaceLight: surfaceVariant
  property color surfaceHover: surfaceBright
  property color container: surfaceContainer
  property color text: backgroundFg
  property color muted: outline
  property color subtext: surfaceVariantFg
  property color border: outlineVariant
  property color warning: tertiary
  property color success: primary
  property color danger: error
  property color overlay: "#00000099"
}
