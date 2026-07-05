pragma Singleton
import QtQuick

Item {
  id: root
  property string sessionState: "Idle" // "Idle", "Work", "Break"
  property int totalTime: 25 * 60
  property int timeRemaining: 0
  property real progress: 0
  property bool isPaused: false

  Timer {
    id: tickTimer
    interval: 1000
    repeat: true
    running: root.sessionState !== "Idle" && !root.isPaused
    onTriggered: {
      if (root.timeRemaining > 0) {
        root.timeRemaining--
        root.progress = 1.0 - (root.timeRemaining / root.totalTime)
      } else {
        root.nextState()
      }
    }
  }

  function startWork() {
    sessionState = "Work"
    totalTime = 25 * 60
    timeRemaining = totalTime
    progress = 0
    isPaused = false
  }

  function startBreak() {
    sessionState = "Break"
    totalTime = 5 * 60
    timeRemaining = totalTime
    progress = 0
    isPaused = false
  }

  function stop() {
    sessionState = "Idle"
    timeRemaining = 0
    progress = 0
    isPaused = false
  }

  function togglePause() {
    if (sessionState !== "Idle") {
      isPaused = !isPaused
    } else {
      startWork()
    }
  }

  function nextState() {
    if (sessionState === "Work") startBreak()
    else stop()
  }

  function formatTime() {
    if (sessionState === "Idle") return "25:00"
    let m = Math.floor(timeRemaining / 60)
    let s = timeRemaining % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }
}
