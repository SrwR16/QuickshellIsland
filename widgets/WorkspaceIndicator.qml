import Quickshell.Hyprland
import QtQuick
import "../theme"

Item {
  id: root
  height: 24
  implicitWidth: maxPills * (pillWidth + pillSpacing) - pillSpacing + 8

  readonly property int maxPills: 5
  readonly property int pillWidth: 24
  readonly property int pillHeight: 22
  readonly property int pillSpacing: 4

  property var items: []

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
      items = list
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
      if (root.items.length > 0)
        running = false
    }
  }

  Component.onCompleted: Qt.callLater(root.update)

  Rectangle {
    id: container
    anchors.fill: parent
    radius: 6
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
        spacing: pillSpacing

        Repeater {
          model: root.items

          delegate: Rectangle {
            id: pill
            required property var modelData

            width: pillWidth
            height: pillHeight
            radius: 6
            color: modelData.focused ? Theme.primary : (mouseArea.containsMouse ? Theme.surfaceHover : "transparent")

            Text {
              anchors.centerIn: parent
              text: modelData.id
              color: modelData.focused ? Theme.onPrimary : (mouseArea.containsMouse ? Theme.text : Theme.muted)
              font {
                family: "Inter"
                pixelSize: 11
                weight: modelData.focused ? Font.Bold : Font.Medium
              }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              anchors.horizontalCenter: parent.horizontalCenter
              width: 3; height: 3; radius: 1.5
              visible: root.windowCount(modelData) > 0 && !modelData.focused
              color: Theme.primary
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent; anchors.margins: -2
              hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
          }
        }
      }
    }
  }
}
