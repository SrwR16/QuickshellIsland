import QtQuick
import Quickshell

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 1080
    color: "transparent"
    
    property bool isActive: false
    
    mask: isActive ? fullMask : smallMask
    
    Region {
        id: fullMask
        Region { item: win }
    }
    
    Region {
        id: smallMask
        Region { item: rect }
    }
    
    Rectangle {
        id: rect
        width: 200; height: 200; color: "red"; anchors.centerIn: parent
    }
}
