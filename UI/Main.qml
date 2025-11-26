import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import "Common/Controls"

/// NOTIVA. AN EASY READ. ///
ApplicationWindow {
    id: appView
    visible: true
    title: "Sight Reading App"
    width: 260
    height: 560
    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    property int staffLineCount: 5
    property string currentNote // Example pitch, update this via signal

    property string noteHeadColor: "black"
    property bool canWiggle: true

    // note selection startup values (for now)
    property var range: appSettings.range

    property bool usingTrebleClef: range[0]
    property bool trebleClef: range[1]
    property bool trebleUpperLedger: range[2]
    property bool trebleLowerLedger: range[3]

    property bool usingBassClef: range[4]
    property bool bassClef: range[5]
    property bool bassUpperLedger: range[6]
    property bool bassLowerLedger: range[7]

    property bool trebleSharps: range[8]
    property bool trebleFlats: range[9]
    property bool bassSharps: range[10]
    property bool bassFlats: range[11]

    //
    property string whichClef: noteSelector.whichClef

    property int activeRangeStart: 1
    property int activeRangeEnd: 3

    property string loaderSource: "StartPage.qml"

    property bool currentNoteIsUpperLedger: noteSelector.isUpperLedger

    property int goalTime: appSettings.goalTime
    property bool wiggleOnOff: true
    Component.onCompleted: { winStreakModel.setStreakPopup() }


    Connections {
        target: microphoneInput
        function onMicrophoneReady()
        {
            console.log("Microphone is READY")
            noteSelector.setNotePool(usingTrebleClef, trebleClef,
                                    trebleUpperLedger, trebleLowerLedger,
                                    usingBassClef, bassClef,
                                    bassUpperLedger, bassLowerLedger,
                                    trebleSharps, trebleFlats,
                                    bassSharps, bassFlats)
            noteSelector.nextNote()
            currentNote = noteSelector.currentNote
        }
    }

    Image {
        id: appBackground
        anchors.fill: parent
        source: "Common/Images/parchment_paper.png"
    }

    Loader {
        id: loader
        source: loaderSource
        anchors.fill: parent
        anchors.topMargin: 25
        anchors.bottomMargin: 35
    }
    FocusScope {
        id: root
        anchors.fill: parent
        focus: true    // <-- MUST HAVE
        //DEV FUNCTIONS
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_F12) {
                console.log("RESETTING FIRST TIME LOAD IN APP SETTINGS");
                appSettings.setFirstLaunch(true);
                event.accepted = true; // optional, stops propagation
                appSettings.saveSettings()
            }
        }
    }
}


