pragma Singleton
import QtQuick
QtObject {
  property color background: "#131318"
  property color surface: "#131318"
  property color surfaceBright: "#3a383e"
  property color surfaceDim: "#131318"
  property color surfaceContainer: "#201f25"
  property color surfaceVariant: "#47464f"
  property color primary: "#c6bfff"
  property color primaryFg: "#2e295f"
  property color secondary: "#c8c3dc"
  property color tertiary: "#ebb8cf"
  property color backgroundFg: "#e5e1e9"
  property color surfaceFg: "#e5e1e9"
  property color surfaceVariantFg: "#c9c5d0"
  property color outline: "#928f99"
  property color outlineVariant: "#47464f"
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
