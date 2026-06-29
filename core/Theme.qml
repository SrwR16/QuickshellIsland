pragma Singleton
import QtQuick
QtObject {
  property color background: "#1a1111"
  property color surface: "#1a1111"
  property color surfaceBright: "#423736"
  property color surfaceDim: "#1a1111"
  property color surfaceContainer: "#271d1d"
  property color surfaceVariant: "#534342"
  property color primary: "#ffb3ae"
  property color primaryFg: "#571e1c"
  property color secondary: "#e7bdb9"
  property color tertiary: "#e2c28c"
  property color backgroundFg: "#f1dedd"
  property color surfaceFg: "#f1dedd"
  property color surfaceVariantFg: "#d8c2bf"
  property color outline: "#a08c8a"
  property color outlineVariant: "#534342"
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
