import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import "Common/Controls"

Item {
    anchors.fill: parent

    property int decrementSpeed: 500
    property int maxSpeed: 100
    property int decrementSize: 1
    property int incrementSpeed: 500
    property int incrementSize: 1

    FontLoader {
       id: garamond
       source: "Common/Fonts/Allura-Regular.ttf"
    }

    FontLoader {
       id: ebgaramond
       source: "Common/Fonts/EBGaramond-Bold.ttf"
    }

    Rectangle {
        id: setGoal
        height: parent.height * 0.3
        width: parent.width * 0.75
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: "Transparent"
        Text {
           id: text
           text: "What's your daily \npractice time goal?"
           horizontalAlignment: Text.AlignHCenter
           verticalAlignment: Text.AlignVCenter
           font.family: garamond.name
           anchors.fill: parent
           fontSizeMode: Text.Fit
           minimumPointSize: 1
           font.pointSize: 100
           color: "#3b2a1b"
        }
    }

    Row {
        height: parent.height * 0.33
        width: parent.width
        anchors.centerIn: parent
        Rectangle {
            height: parent.height
            width: parent.width / 3
            color: "transparent"
            Timer {
                id: decrementHoldTimer
                interval: decrementSpeed
                running: false
                repeat: true
                onTriggered: {
                    if(goalTime <= 0)
                    {
                        goalTime = 60
                    }
                    else
                    {
                        goalTime-= decrementSize
                    }
                    decrementSpeed = Math.max(maxSpeed, decrementSpeed - 100)

                }
            }

            Rectangle {
                anchors.fill: parent
                color: "Transparent"

                Text {
                   text: "-"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                   font.family: garamond.name
                   anchors.fill: parent
                   fontSizeMode: Text.Fit
                   minimumPointSize: 1
                   font.pointSize: 100
                   color: "#3b2a1b"
                }
                MouseArea {
                    id: decrement
                    anchors.fill: parent
                    onPressed: {
                        decrementSpeed = 500
                        decrementSize = 1
                        if(goalTime <= 0)
                        {
                            goalTime = 60
                        }
                        else
                        {
                            goalTime-= 1
                        }

                        decrementHoldTimer.start()
                    }
                    onReleased: {
                        decrementHoldTimer.stop()
                    }
                }
            }
        }

        Rectangle {
            height: parent.height
            width: parent.width / 3
            color: "transparent"
            Text {
               text: goalTime
               horizontalAlignment: Text.AlignHCenter
               verticalAlignment: Text.AlignVCenter
               font.family: garamond.name
               anchors.fill: parent
               fontSizeMode: Text.Fit
               minimumPointSize: 1
               font.pointSize: 100
               color: "#3b2a1b"
            }
        }


        Rectangle {
            height: parent.height
            width: parent.width / 3
            color: "transparent"

            Timer {
                id: incrementHoldTimer
                interval: incrementSpeed
                running: false
                repeat: true
                onTriggered: {
                    if(goalTime >= 25000)
                    {
                        goalTime = 0
                    }
                    else
                    {
                        goalTime+= incrementSize
                    }
                    incrementSpeed = Math.max(maxSpeed, incrementSpeed - 100)

                }
            }

            Rectangle {
                anchors.fill: parent
                color: "Transparent"
                Text {
                   text: "+"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                   font.family: garamond.name
                   anchors.fill: parent
                   fontSizeMode: Text.Fit
                   minimumPointSize: 1
                   font.pointSize: 100
                   color: "#3b2a1b"
                }
                MouseArea {
                    id: increment
                    anchors.fill: parent
                    onPressed: {
                        incrementSpeed = 500
                        incrementSize = 1
                        if(goalTime >= 25000)
                        {
                            goalTime = 0
                        }
                        else
                        {
                            goalTime+= 1
                        }
                        incrementHoldTimer.start()
                    }
                    onReleased: {
                        incrementHoldTimer.stop()
                    }
                }
            }
        }
    }

    Row {
        id: bottomButtons
        visible: appSettings.firstLaunch ? true : false
        height: parent.height * 0.1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 12

        // The max button width so two buttons + spacing always fit on screen
        property real maxButtonWidth: (parent.width - spacing) / 2

        MainButton {
            id: back
            height: bottomButtons.height
            // Keep 2:1 ratio but cap width if screen is narrow
            width: Math.min(height * 2, bottomButtons.maxButtonWidth)
            mainButtonText: "Back"
            mainButtonClicked.onClicked: {
                loaderSource = "StartPage.qml"
            }
        }

        MainButton {
            id: next
            height: bottomButtons.height
            width: Math.min(height * 2, bottomButtons.maxButtonWidth)
            mainButtonText: "Next"
            mainButtonClicked.onClicked: {
                appSettings.setGoalTime(goalTime)
                loaderSource = "TrebleSettings.qml"
            }
        }
    }
}
