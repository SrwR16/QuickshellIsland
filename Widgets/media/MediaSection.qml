import QtQuick
import QtQuick.Layouts

RowLayout {
    id: mediaSection
    spacing: 10

    property string trackTitle: "No Media"
    property string trackArtist: "Unknown Artist"
    property string trackArt: ""
    property bool isPlaying: false
    property var barHeights: [2, 2, 2, 2]

    Rectangle {
        width: 44
        height: 44
        radius: 10
        color: "#14221d"
        clip: true

        Image {
            anchors.fill: parent
            source: mediaSection.trackArt || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true

            Rectangle {
                anchors.fill: parent
                color: "#14221d"
                visible: parent.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: "#3ba889"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
                }
            }
        }
    }

    ColumnLayout {
        spacing: 1
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            spacing: 6

            Row {
                spacing: 2
                height: 10
                visible: mediaSection.isPlaying
                Layout.alignment: Qt.AlignVCenter

                Rectangle { width: 2; height: Math.min(10, mediaSection.barHeights[0]); radius: 0.5; color: "#3ba889"; anchors.bottom: parent.bottom }
                Rectangle { width: 2; height: Math.min(10, mediaSection.barHeights[1]); radius: 0.5; color: "#3ba889"; anchors.bottom: parent.bottom }
                Rectangle { width: 2; height: Math.min(10, mediaSection.barHeights[2]); radius: 0.5; color: "#3ba889"; anchors.bottom: parent.bottom }
                Rectangle { width: 2; height: Math.min(10, mediaSection.barHeights[3]); radius: 0.5; color: "#3ba889"; anchors.bottom: parent.bottom }
            }

            Text {
                text: mediaSection.trackTitle
                color: "#eae6dc"
                elide: Text.ElideRight
                Layout.maximumWidth: 120
                font { family: "Inter"; pixelSize: 13; weight: 600 }
            }
        }

        Text {
            text: mediaSection.trackArtist
            color: "#eae6dc"
            opacity: 0.6
            elide: Text.ElideRight
            Layout.maximumWidth: 120
            font { family: "Inter"; pixelSize: 11 }
        }
    }
}
