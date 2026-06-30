pragma Singleton
import QtQuick
QtObject {
  property color background: "#200e0c"
  property color surface: "#200e0c"
  property color surfaceBright: "#4b3331"
  property color surfaceDim: "#200e0c"
  property color surfaceContainer: "#2e1a18"
  property color surfaceVariant: "#5f3f3b"
  property color primary: "#ffb4ab"
  property color primaryFg: "#690005"
  property color secondary: "#ffb4ab"
  property color tertiary: "#9ecaff"
  property color backgroundFg: "#ffdad6"
  property color surfaceFg: "#ffdad6"
  property color surfaceVariantFg: "#e9bcb6"
  property color outline: "#af8782"
  property color outlineVariant: "#5f3f3b"
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
