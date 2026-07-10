import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
  id: root
  height: 28

  property var items: []

  function update() {
    var vals = []

    try {
      if (typeof Hyprland !== "undefined" && Hyprland !== null &&
          typeof Hyprland.workspaces !== "undefined" && Hyprland.workspaces !== null) {
        vals = Hyprland.workspaces.values || []
      } else {
        return
      }
    } catch (e) {
      return
    }

    var list = []
    for (var i = 0; i < vals.length; i++) {
      var ws = vals[i]
      if (ws && (ws.focused || (ws.toplevels && ws.toplevels.length > 0)))
        list.push(ws)
    }
    list.sort(function(a, b) { return a.id - b.id })
    items = list
  }

  Connections {
    target: Hyprland.workspaces
    enabled: typeof Hyprland !== "undefined" && Hyprland !== null &&
             typeof Hyprland.workspaces !== "undefined" && Hyprland.workspaces !== null
    function onValuesChanged() { root.update() }
  }

  Connections {
    target: Hyprland
    enabled: typeof Hyprland !== "undefined" && Hyprland !== null
    function onFocusedWorkspaceChanged() { root.update() }
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    onTriggered: {
      root.update()
      if (root.items.length > 0)
        running = false
    }
  }

  Component.onCompleted: Qt.callLater(root.update)

  Rectangle {
    anchors.fill: parent
    radius: 8
    color: Theme.surfaceContainer
    border.color: Theme.border
    border.width: 1

    Flickable {
      anchors.fill: parent
      anchors.margins: 2
      contentWidth: row.width
      contentHeight: row.height
      clip: true
      interactive: contentWidth > width
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.HorizontalFlick

      Row {
        id: row
        height: parent.height
        spacing: 2

        Repeater {
          model: root.items

          delegate: Rectangle {
            id: pill
            required property var modelData

            width: 28
            height: 22
            radius: 5

            color: modelData.focused ? Theme.primary : (mouseArea.containsMouse ? Theme.surfaceHover : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
              anchors.centerIn: parent
              text: modelData.id
              color: modelData.focused ? Theme.onPrimary : Theme.text
              font { family: "Inter"; pixelSize: 12; weight: modelData.focused ? Font.Bold : Font.Normal }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              anchors.horizontalCenter: parent.horizontalCenter
              width: 4; height: 4; radius: 2
              visible: modelData.toplevels && modelData.toplevels.length > 0 && !modelData.focused
              color: Theme.primary
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent; anchors.margins: -2
              hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (typeof Hyprland !== "undefined" && Hyprland !== null)
                  Hyprland.dispatch("workspace " + modelData.id)
              }
            }
          }
        }
      }
    }
  }
}
