import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../core"

Item {
    id: largeMedia
    
    property string trackTitle: "No Media"
    property string trackArtist: "Unknown Artist"
    property string trackArt: ""
    property string mediaState: "Idle"
    property var barHeights: [2, 2, 2, 2]
    property bool isHovered: false

    function checkHover() {
        var h = false;
        if (typeof prevMouse !== "undefined") h = h || prevMouse.containsMouse;
        if (typeof playMouse !== "undefined") h = h || playMouse.containsMouse;
        if (typeof nextMouse !== "undefined") h = h || nextMouse.containsMouse;
        isHovered = h;
    }

    Process { id: prevProc; command: ["playerctl", "previous"] }
    Process { id: playProc; command: ["playerctl", "play-pause"] }
    Process { id: nextProc; command: ["playerctl", "next"] }

    // Top Row: Album Art + Track Info + Cava
    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 64
        spacing: 16

        Rectangle {
            width: 64
            height: 64
            radius: 14
            color: Theme.surfaceLight
            clip: true

            Image {
                anchors.fill: parent
                source: largeMedia.trackArt || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceLight
                    visible: parent.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "󰎆"
                        color: Theme.primary
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 24 }
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            Text {
                text: largeMedia.trackTitle
                color: largeMedia.mediaState === "Idle" ? Theme.subtext : Theme.text
                opacity: largeMedia.mediaState === "Idle" ? 0.6 : 1.0
                elide: Text.ElideRight
                Layout.fillWidth: true
                font { family: "Inter"; pixelSize: 18; weight: 700 }
            }

            Text {
                text: largeMedia.mediaState === "Idle" ? "" : largeMedia.trackArtist
                color: Theme.text
                opacity: 0.5
                elide: Text.ElideRight
                Layout.fillWidth: true
                font { family: "Inter"; pixelSize: 14 }
            }
        }

        Row {
            spacing: 4
            height: 24
            visible: largeMedia.mediaState === "Playing"
            Layout.alignment: Qt.AlignVCenter

            Rectangle { width: 4; height: Math.min(24, largeMedia.barHeights[0] * 2.4); radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 4; height: Math.min(24, largeMedia.barHeights[1] * 2.4); radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 4; height: Math.min(24, largeMedia.barHeights[2] * 2.4); radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 4; height: Math.min(24, largeMedia.barHeights[3] * 2.4); radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // Bottom Row: Media Controls
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48
        
        Item { Layout.fillWidth: true } // Spacer

        RowLayout {
            spacing: 40

            Text {
                text: "󰒮"
                color: prevMouse.containsMouse ? Theme.primary : Theme.text
                opacity: prevMouse.containsMouse ? 1.0 : 0.8
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 32 }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: prevProc.running = true
                    onContainsMouseChanged: largeMedia.checkHover()
                }
            }
            Text {
                text: largeMedia.mediaState === "Playing" ? "󰏤" : "󰐊"
                color: playMouse.containsMouse ? Theme.primary : Theme.text
                opacity: playMouse.containsMouse ? 1.0 : 1.0
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 42 }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: playProc.running = true
                    onContainsMouseChanged: largeMedia.checkHover()
                }
            }
            Text {
                text: "󰒭"
                color: nextMouse.containsMouse ? Theme.primary : Theme.text
                opacity: nextMouse.containsMouse ? 1.0 : 0.8
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 32 }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nextProc.running = true
                    onContainsMouseChanged: largeMedia.checkHover()
                }
            }
        }

        Item { Layout.fillWidth: true } // Spacer
    }
}
