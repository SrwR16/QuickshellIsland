import QtQuick
import QtQuick.Layouts
import "../../core"
import "."

ColumnLayout {
  id: movieSection
  spacing: 8

  RowLayout {
    Layout.fillWidth: true
    Text {
      text: "Trending Movies"
      color: Theme.text
      font.family: "Inter"
      font.pixelSize: 14
      font.weight: 600
      Layout.fillWidth: true
    }
    Text {
      text: MovieService.isFetchingMovies ? "Loading..." : "Cinemeta"
      color: Theme.subtext
      font.family: "Inter"
      font.pixelSize: 12
    }
  }

  ListView {
    id: movieCarousel
    Layout.fillWidth: true
    Layout.preferredHeight: 120
    orientation: ListView.Horizontal
    spacing: 12
    model: MovieService.trendingMovies
    clip: true

    delegate: Item {
      width: 80
      height: 120
      
      Rectangle {
        id: posterRect
        anchors.fill: parent
        radius: 8
        color: Theme.surfaceLight
        clip: true

        Image {
          anchors.fill: parent
          source: model.poster
          fillMode: Image.PreserveAspectCrop
        }
        
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 30
          gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#aa000000" }
          }
          opacity: mouseArea.containsMouse ? 1.0 : 0.0
          Behavior on opacity { NumberAnimation { duration: 150 } }
          
          Text {
            anchors.centerIn: parent
            text: "⭐ " + model.rating
            color: "white"
            font.pixelSize: 11
            font.weight: 600
          }
        }
      }

      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: posterRect.scale = 1.05
        onExited: posterRect.scale = 1.0
        Behavior on scale { NumberAnimation { duration: 150 } }
        onClicked: {
          var cmd = ["xdg-open", "https://vidsrc.net/embed/movie/" + model.id]
          var p = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process { command: ' + JSON.stringify(cmd) + ' }', movieSection)
          p.exited.connect(function() { p.destroy() })
          p.running = true
        }
      }
    }
  }
}
