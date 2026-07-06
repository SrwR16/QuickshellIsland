import QtQuick
import Quickshell

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 1080
    color: "transparent"
    
    mask: Region {
        item: rect
        Item {
            width: 10
            height: 10
        }
    }
    
    Rectangle {
        id: rect
        width: 200
        height: 200
        color: "red"
        anchors.centerIn: parent
    }
}
