import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
  id: sv
  padding: 0
  contentWidth: width
  required property bool nlEnabled
  required property string nlMode
  required property int nlTemp
  required property int nlDayTemp
  required property int nlNightTemp

  signal backRequested()
  signal toggleNightLight()
  signal setNightLightTemp(int temp)
  signal setNightLightAutoTemp(int day, int night)
  signal setNightLightMode(string mode)
  signal applyNightLight()
  signal saveNightLight()

  ColumnLayout {
    width: parent.width
    spacing: 10

    Text {
      text: "Mode"
      color: "#8fa59c"
      font { family: "Inter"; pixelSize: 11; weight: 700 }
      leftPadding: 4
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Rectangle {
        Layout.fillWidth: true
        height: 36
        radius: 10
        color: nlMode === "manual" ? "#1d2a25" : "#16241f"

        Text {
          anchors.centerIn: parent
          text: "Manual"
          color: nlMode === "manual" ? "#eae6dc" : "#6a8078"
          font { family: "Inter"; pixelSize: 12; weight: nlMode === "manual" ? 600 : 400 }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            setNightLightMode("manual");
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 36
        radius: 10
        color: nlMode === "auto" ? "#1d2a25" : "#16241f"

        Text {
          anchors.centerIn: parent
          text: "Auto"
          color: nlMode === "auto" ? "#eae6dc" : "#6a8078"
          font { family: "Inter"; pixelSize: 12; weight: nlMode === "auto" ? 600 : 400 }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            setNightLightMode("auto");
          }
        }
      }
    }

    // Temperature slider for manual mode
    ColumnLayout {
      visible: nlMode === "manual"
      Layout.fillWidth: true
      spacing: 6

      Text {
        text: "Temperature"
        color: "#8fa59c"
        font { family: "Inter"; pixelSize: 11; weight: 700 }
        leftPadding: 4
      }

      Item { height: 4 }

      IconSlider {
        iconText: "󰂚"
        value: (nlTemp - 1000) / 7000
        onMoved: val => setNightLightTemp(1000 + Math.round(val * 7000))
      }

      Text {
        text: nlTemp + "K"
        color: "#eae6dc"
        font { family: "Inter"; pixelSize: 11 }
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }
    }

    // Temperature sliders for auto mode
    ColumnLayout {
      visible: nlMode === "auto"
      Layout.fillWidth: true
      spacing: 6

      Text {
        text: "Day Temperature"
        color: "#8fa59c"
        font { family: "Inter"; pixelSize: 11; weight: 700 }
        leftPadding: 4
      }

      IconSlider {
        iconText: "󰖕"
        value: (nlDayTemp - 1000) / 7000
        onMoved: val => setNightLightAutoTemp(
          1000 + Math.round(val * 7000),
          nlNightTemp
        )
      }

      Text {
        text: nlDayTemp + "K"
        color: "#eae6dc"
        font { family: "Inter"; pixelSize: 11 }
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }

      Item { height: 4 }

      Text {
        text: "Night Temperature"
        color: "#8fa59c"
        font { family: "Inter"; pixelSize: 11; weight: 700 }
        leftPadding: 4
      }

      IconSlider {
        iconText: "󰖔"
        value: (nlNightTemp - 1000) / 7000
        onMoved: val => setNightLightAutoTemp(
          nlDayTemp,
          1000 + Math.round(val * 7000)
        )
      }

      Text {
        text: nlNightTemp + "K"
        color: "#eae6dc"
        font { family: "Inter"; pixelSize: 11 }
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }

      Text {
        text: "Requires geoclue2 service for sunset/sunrise"
        color: "#6a8078"
        font { family: "Inter"; pixelSize: 9 }
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.topMargin: 4
      }
    }

    Item { Layout.preferredHeight: 4 }
  }
}
