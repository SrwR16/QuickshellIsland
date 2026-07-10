import "./widgets"
import QtQuick
import QtQuick.Window
import Quickshell

FloatingWindow {
  id: root
  visible: true
  flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
  color: "transparent"
  width: 980
  height: 660

  Component.onCompleted: {
    var s = root.screen
    root.x = (s.width - width) / 2
    root.y = (s.height - height) / 2
  }

  Keys.onEscapePressed: Qt.quit()

  MovieWidget {
    id: movieWidget
    anchors.fill: parent
    onCloseRequested: Qt.quit()
  }
}
