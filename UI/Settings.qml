import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import "Common/Controls"

Item {
    anchors.fill: parent

    /* MASTER SCALING UNIT (height-based) */
    property real hUnit: height
    // Use hUnit * 0.1 instead of parent.height * 0.1
    // Use hUnit * 0.33 instead of parent.width * 0.33 (height-based!)
    // Use fontSizeMode: Text.Fit (no pointSize)

    property int decrementSpeed: 500
    property int maxSpeed: 100
    property int decrementSize: 1
    property int incrementSpeed: 500
    property int incrementSize: 1

    MainButton {
        id: top
        height: hUnit * 0.083     // = parent.height / 12
        width: parent.width * 0.33
        anchors.leftMargin: 5
        anchors.top: parent.top
        anchors.left: parent.left
        mainButtonText: "Done";

        mainButtonClicked.onClicked: {
            appSettings.setGoalTime(goalTime)
            loader.source = "SightReadingActive.qml"
        }
    }

    FontLoader { id: garamond; source: "Common/Fonts/Allura-Regular.ttf" }
    FontLoader { id: ebgaramond; source: "Common/Fonts/EBGaramond-Bold.ttf" }

    Column {
        anchors {
            top: top.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        // TITLE
        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            Text {
                text: "Adjust daily practice goal:"
                anchors.fill: parent
                font.family: garamond.name
                fontSizeMode: Text.Fit
                minimumPointSize: 1
                font.pointSize: 50
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
            }
        }

        // --- GOAL ADJUST ROW (- / number / +) ---
        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            Row {
                id: adjustGoalRow
                spacing: hUnit * 0.04
                anchors.centerIn: parent

                // Left button "-"
                Rectangle {
                    id: minusBox
                    width: hUnit * 0.10      // fixed scaling instead of parent.width/3
                    height: hUnit * 0.10
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        text: "-"
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 50
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            decrementSpeed = 500
                            decrementSize = 1
                            goalTime = (goalTime <= 0 ? 60 : goalTime - 1)
                            decrementHoldTimer.start()
                        }
                        onReleased: decrementHoldTimer.stop()
                    }
                }

                // Center number
                Rectangle {
                    id: numberBox
                    width: hUnit * 0.12      // slightly wider to fit numbers
                    height: hUnit * 0.10
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        text: goalTime
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 50
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Right button "+"
                Rectangle {
                    id: plusBox
                    width: hUnit * 0.10
                    height: hUnit * 0.10
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        text: "+"
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 50
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            incrementSpeed = 500
                            incrementSize = 1
                            goalTime = (goalTime >= 25000 ? 0 : goalTime + 1)
                            incrementHoldTimer.start()
                        }
                        onReleased: incrementHoldTimer.stop()
                    }
                }
            }

            // The timers stay here unchanged
            Timer {
                id: decrementHoldTimer
                interval: decrementSpeed
                repeat: true
                onTriggered: {
                    goalTime = (goalTime <= 0 ? 60 : goalTime - decrementSize)
                    decrementSpeed = Math.max(maxSpeed, decrementSpeed - 100)
                }
            }

            Timer {
                id: incrementHoldTimer
                interval: incrementSpeed
                repeat: true
                onTriggered: {
                    goalTime = (goalTime >= 25000 ? 0 : goalTime + incrementSize)
                    incrementSpeed = Math.max(maxSpeed, incrementSpeed - 100)
                }
            }
        }


        Rectangle {
            height: hUnit * 0.20
            width: parent.width
            color: "transparent"

            Row {
                id: wiggleRow
                spacing: hUnit * 0.04
                anchors.centerIn: parent

                Rectangle {
                    id: textBox
                    width: parent.width * 0.75      // same effective width as labels
                    height: hUnit * 0.10            // same height as other label rows
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        text: "Wiggle on wrong note:"
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 50          // WILL NOW DISPLAY AT 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item {
                    id: switchWrapper
                    width: hUnit * 0.07
                    height: hUnit * 0.10

                    SwitchButton {
                        id: wiggle
                        checked: appSettings.wiggleEnabled
                        width: hUnit * 0.07
                        height: width / aspect
                        anchors.centerIn: parent
                    }
                }
            }

            Connections {
                target: wiggle
                function onCheckedChanged() {
                    appSettings.setWiggleEnabled(wiggle.checked)
                }
            }
        }

        // SUPPORT TEXT
        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            Text {
                text: "Want to support Smith Percussion further?"
                anchors.fill: parent
                font.family: garamond.name
                fontSizeMode: Text.Fit
                minimumPointSize: 1
                font.pointSize: 50
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // DONATE BUTTON
        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            MainButton {
                id: donate
                mainButtonText: "PayPal"
                width: hUnit * 0.20
                height: width / 2.5
                anchors.centerIn: parent
                mainButtonClicked.onClicked: Qt.openUrlExternally("https://www.paypal.me/smithpercussion")
            }
        }

        Item {
            height: hUnit * 0.10
            width: parent.width
        }

        // SUPPORT TEXT
        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            Text {
                text: "More from Smith Percussion:"
                anchors.fill: parent
                font.family: garamond.name
                fontSizeMode: Text.Fit
                minimumPointSize: 1
                font.pointSize: 50
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            height: hUnit * 0.10
            width: parent.width
            color: "transparent"

            Row {
                id: more
                spacing: hUnit * 0.03
                // the row sizes itself to its content (buttons)
                width: moreLink1.width + spacing + moreLink2.width
                height: hUnit * 0.10

                anchors.centerIn: parent

                MainButton {
                    id: moreLink1
                    mainButtonText: "Website"
                    width: hUnit * 0.20
                    height: width / 2.5
                    mainButtonClicked.onClicked:
                        Qt.openUrlExternally("https://www.alexandermfsmith.com")
                }

                MainButton {
                    id: moreLink2
                    mainButtonText: "YouTube"
                    width: hUnit * 0.20
                    height: width / 2.5
                    mainButtonClicked.onClicked:
                        Qt.openUrlExternally("https://www.youtube.com/@SmithPercussion")
                }
            }
        }
    }
}
