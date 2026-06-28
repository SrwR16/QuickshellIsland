pragma Singleton
import QtQuick
QtObject {
  property color background: "#131318"
  property color surface: "#131318"
  property color surfaceBright: "#39393f"
  property color surfaceDim: "#131318"
  property color surfaceContainer: "#1f1f25"
  property color surfaceVariant: "#46464f"
  property color primary: "#bbc3ff"
  property color primaryFg: "#242c61"
  property color secondary: "#c4c5dd"
  property color tertiary: "#e6bad7"
  property color backgroundFg: "#e4e1e9"
  property color surfaceFg: "#e4e1e9"
  property color surfaceVariantFg: "#c7c5d0"
  property color outline: "#90909a"
  property color outlineVariant: "#46464f"
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
