import "./Overview/common"
import "./Overview/services"
import "./Overview/modules/overview"
import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
  id: root

  Component.onCompleted: GlobalStates.overviewOpen = true

  Keys.onEscapePressed: Qt.quit()

  Connections {
    target: GlobalStates
    function onOverviewOpenChanged() {
      if (!GlobalStates.overviewOpen) Qt.quit()
    }
  }

  Overview {
    id: overview
  }
}
