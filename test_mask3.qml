import QtQuick
import Quickshell

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 1080
    color: "transparent"
    
    mask: Region {
        Region { item: rect }
        Region { item: rect2 }
    }
    
    Rectangle {
        id: rect
        width: 200; height: 200; color: "red"; anchors.centerIn: parent
    }
    Rectangle {
        id: rect2
        width: 200; height: 200; color: "blue"; anchors.top: parent.top
    }
}
