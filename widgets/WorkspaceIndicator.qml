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

  on_CountChanged: updateItems()

  function windowCount(ws) {
    if (!ws || !ws.toplevels) return 0
    try { return ws.toplevels.values.length } catch (e) { return 0 }
  }

  function updateItems() {
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
    function onValuesChanged() { root.updateItems() }
  }

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() { root.updateItems() }
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    onTriggered: {
      root.updateItems()
      if (root._count > 0)
        running = false
    }
  }

  Component.onCompleted: Qt.callLater(updateItems)

  Row {
    id: row
    spacing: 6
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      model: root._count

      delegate: Item {
        id: pill
        required property int index
        readonly property var ws: root._items.length > index ? root._items[index] : null
        readonly property bool isActive: index === root._focused
        readonly property bool hasWindows: ws ? root.windowCount(ws) > 0 : false

        width: 24
        height: 22

        Rectangle {
          anchors.fill: parent
          radius: 5
          color: isActive ? Theme.tertiary : (mouseArea.containsMouse ? Theme.surfaceBright : (hasWindows ? Theme.surfaceContainer : "transparent"))
          visible: isActive || hasWindows || mouseArea.containsMouse
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

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: { if (ws) Hyprland.dispatch("workspace " + ws.id) }
        }
      }
    }
  }
}
