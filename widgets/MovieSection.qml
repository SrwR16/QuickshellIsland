import "../overlay"
import "../widgets"
import "../services"
import "../theme"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: movieSection
    property string activeView: "list" // "list" or "detail"
    property var selectedMovie: null

    Process { id: playProc }

    // Header Search & Filter Bar (Only visible in list view)
    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 12
        visible: activeView === "list"

        // Search Bar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
            color: Theme.surfaceLight
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                Text { text: "󰍉"; color: Theme.subtext; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font { family: "Inter"; pixelSize: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onAccepted: {
                        if (text.trim() !== "") {
                            MovieService.searchMovies(text)
                        } else {
                            MovieService.searchResults.clear()
                        }
                    }
                }
                
                Text { 
                    text: "Hit Enter to search"; color: Theme.subtext; font.pixelSize: 10 
                    visible: searchInput.text !== "" && !MovieService.isSearching
                }
                
                Text {
                    text: "󱑑"; color: Theme.primary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                    visible: MovieService.isSearching || MovieService.isFetchingMovies
                    RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                }
            }
        }

        // Filter Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Repeater {
                model: [
                    { label: "Trending", cat: "top" },
                    { label: "Action", cat: "action" },
                    { label: "Comedy", cat: "comedy" },
                    { label: "Sci-Fi", cat: "sci-fi" }
                ]
                Rectangle {
                    width: tabText.implicitWidth + 24
                    height: 28
                    radius: 14
                    color: Theme.surfaceLight
                    
                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Theme.text
                        font { family: "Inter"; pixelSize: 12; weight: 500 }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = ""
                            MovieService.searchResults.clear()
                            MovieService.fetchMovies(modelData.cat)
                        }
                    }
                }
            }
        }
    }

    // Grid View
    GridView {
        id: moviesGrid
        anchors.top: parent.top
        anchors.topMargin: 104 // Below header
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        
        visible: activeView === "list"
        clip: true
        cellWidth: (width) / 3
        cellHeight: cellWidth * 1.5 + 40
        
        model: MovieService.searchResults.count > 0 ? MovieService.searchResults : MovieService.trendingMovies
        
        delegate: Item {
            width: moviesGrid.cellWidth - 10
            height: moviesGrid.cellHeight - 10
            
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                
                Image {
                    id: posterImg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: width * 1.5
                    source: model.poster
                    fillMode: Image.PreserveAspectCrop
                    
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Theme.border
                        border.width: 1
                        radius: 12
                    }
                }
                
                Text {
                    anchors.top: posterImg.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: model.title
                    color: Theme.text
                    font { family: "Inter"; pixelSize: 12; weight: 600 }
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        selectedMovie = model
                        activeView = "detail"
                    }
                }
            }
        }
    }

    // Detail View
    Item {
        anchors.fill: parent
        anchors.margins: 16
        visible: activeView === "detail"

        Rectangle {
            width: 40; height: 40; radius: 20
            color: Theme.surfaceLight
            z: 10
            Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.text; font.family: "JetBrainsMono Nerd Font" }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: activeView = "list"
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 24

            // Left side poster
            Image {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                source: selectedMovie ? selectedMovie.poster : ""
                fillMode: Image.PreserveAspectCrop
                
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: Theme.border; border.width: 1; radius: 16 }
            }

            // Right side details
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Text {
                    text: selectedMovie ? selectedMovie.title : ""
                    color: Theme.text
                    font { family: "Inter"; pixelSize: 24; weight: 800 }
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 16
                    Text { text: selectedMovie ? selectedMovie.year : ""; color: Theme.subtext; font.pixelSize: 14 }
                    Row {
                        spacing: 4
                        Text { text: "⭐"; font.pixelSize: 12 }
                        Text { text: selectedMovie ? selectedMovie.rating : ""; color: Theme.text; font.pixelSize: 14; font.weight: 700 }
                    }
                }

                Text {
                    text: selectedMovie ? selectedMovie.description : ""
                    color: Theme.subtext
                    font { family: "Inter"; pixelSize: 14 }
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignTop
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 24
                    color: Theme.primary
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "󰐊"; color: Theme.onPrimary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
                        Text { text: "Play Movie"; color: Theme.onPrimary; font { family: "Inter"; pixelSize: 16; weight: 700 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedMovie) {
                                playProc.command = ["xdg-open", "https://vidsrc.net/embed/movie?imdb=" + selectedMovie.id]
                                playProc.running = true
                            }
                        }
                    }
                }
            }
        }
    }
}
