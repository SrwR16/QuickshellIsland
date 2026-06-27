import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property bool isOpen: false
  property var wallpaperModel: []
  property var wallService: null

  signal closed()

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      close()
      event.accepted = true
    }
  }

  // Global opacity animation
  opacity: root.isOpen ? 1 : 0
  visible: root.isOpen || opacity > 0
  Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }

  // Dim backdrop
  Rectangle {
    anchors.fill: parent
    color: "#000000"
    opacity: root.isOpen ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
  }

  // Click-outside catcher — only fires when click is NOT inside the panel
  MouseArea {
    anchors.fill: parent
    enabled: root.isOpen
    onClicked: {
      var p = mapToItem(panel, mouse.x, mouse.y)
      if (!(p.x >= 0 && p.x <= panel.width && p.y >= 0 && p.y <= panel.height))
        close()
    }
  }

  // Centered panel
  Rectangle {
    id: panel
    width: 640
    height: 440
    radius: 28
    color: "#cc0a1411"

    border.width: 1
    border.color: "#1d2a25"

    // Position & scale animation
    transform: [
      Translate {
        y: root.isOpen ? 0 : 40
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
      },
      Scale {
        origin.x: panel.width / 2
        origin.y: panel.height / 2
        xScale: root.isOpen ? 1 : 0.92
        yScale: root.isOpen ? 1 : 0.92
        Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
        Behavior on yScale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
      }
    ]

    anchors.centerIn: parent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 16

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: ""
          color: "#61afef"
          font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
        }

        Text {
          text: "Wallpapers"
          color: "#eae6dc"
          font { family: "Inter"; pixelSize: 15; weight: Font.Bold }
          Layout.fillWidth: true
        }

        Text {
          text: "✕"
          color: "#eae6dc"
          opacity: 0.5
          font { family: "Inter"; pixelSize: 14 }
          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: close()
          }
        }
      }

      // Grid container
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16
        color: "#0d1f19"
        clip: true

        WallpaperGrid {
          id: wallpaperGrid
          anchors.fill: parent
          anchors.margins: 8
          wallpaperModel: root.wallpaperModel
          wallService: root.wallService
          cellSize: Math.min(
            Math.max((parent.width - 3 * 12) / 4, 90),
            150
          )
          onWallpaperChosen: function(path) {
            root.close()
          }
        }
      }
    }
  }

  Timer {
    id: closeTimer
    interval: 200
    onTriggered: root.closed()
  }

  function open() {
    closeTimer.stop()
    root.isOpen = true
    root.forceActiveFocus()
  }

  function close() {
    root.isOpen = false
    closeTimer.restart()
  }
}
