import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
  id: root
  height: 22
  implicitWidth: 5 * (24 + 6) - 6

  property var _items: []
  property int _focused: -1
  property int _count: 0

  function windowCount(ws) {
    if (!ws || !ws.toplevels) return 0
    try { return ws.toplevels.values.length } catch (e) { return 0 }
  }

  function update() {
    try {
      if (!Hyprland || !Hyprland.workspaces) return
      var vals = Hyprland.workspaces.values
      if (!vals) return

      var list = []
      for (var i = 0; i < vals.length; i++) {
        var ws = vals[i]
        if (ws && (ws.focused || windowCount(ws) > 0))
          list.push(ws)
      }
      list.sort(function(a, b) { return a.id - b.id })
      _items = list
      _count = list.length

      _focused = -1
      for (var j = 0; j < list.length; j++) {
        if (list[j].focused) { _focused = j; break }
      }
    } catch (e) {}
  }

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.update() }
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.update() }
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    onTriggered: {
      root.update()
      if (root._count > 0)
        running = false
    }
  }

  Component.onCompleted: Qt.callLater(root.update)

  Row {
    id: row
    spacing: 6
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      model: root._count

      delegate: Item {
        required property int index
        readonly property var ws: root._items.length > index ? root._items[index] : null
        readonly property bool isActive: index === root._focused
        readonly property bool hasWindows: ws ? root.windowCount(ws) > 0 : false

        width: 24
        height: 22

        Rectangle {
          anchors.fill: parent
          radius: 5
          color: isActive ? Theme.tertiary : (hasWindows ? Theme.surfaceContainer : Theme.surface)
        }

        Text {
          anchors.centerIn: parent
          text: ws ? ws.id : ""
          color: isActive ? Theme.onPrimary : Theme.text
          font {
            family: "Inter"
            pixelSize: 12
            weight: isActive ? Font.Bold : Font.Medium
          }
        }
      }
    }
  }
}
