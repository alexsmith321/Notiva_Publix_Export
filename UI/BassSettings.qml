import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "Common/Controls"

/* MAGIC NUMBERS
0 usingTrebleClef
1 trebleClef
2 trebleUpperLedger
3 trebleLowerLedger
4 usingBassClef
5 bassClef
6 bassUpperLedger
7 bassLowerLedger
8 sharps
9 flats
*/

Item {
    anchors.fill: parent

    Component.onCompleted: myPopup.open()

    property string tip1: "When playing an instrument with a lot of overtones in the bass, or playing in a very resonant room, you can turn the 'Wiggle' on wrong note animation OFF in the App Settings.\n\nThis will prevent seeing unusual false negatives."
    property string tip2: "You can also play the bass clef an octave higher to improve accuracy."
    property bool firstTipActive: true
    property var rangeSettings: appSettings.range

    property bool upperLedgers: switch1.checked
    property bool staff: switch2.checked
    property bool lowerLedgers: switch3.checked
    property bool flatsActive: flatsSwitch.checked
    property bool sharpsActive: sharpSwitch.checked

    property real mainSwitchW: switch1 ? switch1.width : 120
    property real mainSwitchH: switch1 ? switch1.height : 48

    property bool showTrebleClef: false

    property real lineSpacing: container.height / 12
    property real staffTop: container.height / 3
    property int staffLineCount: 5
    property real staffHeight: 4 * lineSpacing       // 5-line staff spans 4 spacings
    property real staffCenterY: staffTop + staffHeight / 2

    property real parentHeight: parent.height
    property real parentWidth: parent.width


    // Convenience function to convert from container-local y to local y
    function alignedY(containerY) {
        return container.mapToItem(switchColumn, 0, containerY).y
    }


    ColumnLayout {
        anchors.fill: parent


        FontLoader {
           id: garamond
           source: "Common/Fonts/Allura-Regular.ttf"
        }

        Row{
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height / 6 * 1
            Rectangle {
                id: title
                color: "transparent"
                width: parent.width / 6 * 5
                height: parent.height
                Text {
                   id: text
                   text: "Range Selection"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                   font.family: garamond.name
                   anchors.fill: parent
                   fontSizeMode: Text.Fit
                   minimumPointSize: 1
                   font.pointSize: 46
                   color: "#3b2a1b"
                }
            }
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.75
            //Layout.preferredWidth: parent.width / 3 * 2
            Layout.margins: 10
            Rectangle {
                id: container

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3 * 2

                Layout.margins: 0
                color: "transparent"

                Item { id: guideHigh;  y: staffTop - 2 * lineSpacing; width: 1; height: 1 }
                Item { id: guideMid;   y: staffTop + 2 * lineSpacing; width: 1; height: 1 }
                Item { id: guideLow;   y: staffTop + 6 * lineSpacing; width: 1; height: 1 }

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    onPaint: {
                        let ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        ctx.save()

                        // Apply rotation and scaling
                        ctx.translate(width / 2, height / 2)
                        //ctx.scale(0.8, 0.8)
                        ctx.translate(-width / 2, -height / 2)

                        ctx.lineCap = "round"

                        let staffSegments = 30
                        let variance = 1.5
                        let passes = 3

                        // === STAFF LINES ===
                        for (let lineIndex = 0; lineIndex < staffLineCount; lineIndex++) {
                            let yBase = staffTop + lineIndex * lineSpacing

                            for (let pass = 0; pass < passes; pass++) {
                                ctx.beginPath()
                                let inkAlpha = 0.65 + Math.random() * 0.2
                                if(staff){
                                    ctx.strokeStyle = `rgba(35, 25, 25, ${inkAlpha})`
                                }
                                else {
                                    ctx.strokeStyle = `rgba(120, 105, 90, 0.28)`  // warm gray, soft visibility
                                }

                                ctx.lineWidth = 1 + Math.random() * 1.2
                                ctx.moveTo(0, yBase + (Math.random() - 0.5) * variance)

                                for (let j = 1; j <= staffSegments; j++) {
                                    let t = j / staffSegments
                                    let x = width * t
                                    let wobble = Math.sin(t * Math.PI * 2 + lineIndex) * 0.5
                                    let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 +
                                                  (Math.random() - 0.5) + wobble) * variance
                                    ctx.lineTo(x, yBase + yOffset)
                                }
                                ctx.stroke()
                            }
                        }

                        // === LEDGER LINES ===
                        let noteX = width * 0.6
                        let ledgerLength = lineSpacing * 2.1
                        let ledgerOffset = lineSpacing * 0.5
                        let xStart = noteX - ledgerLength / 2 + ledgerOffset
                        let xEnd = noteX + ledgerLength / 2 + ledgerOffset

                        if(upperLedgers)
                        {
                            // Top ledger lines
                            for (let lineNum = 0; lineNum < 3; lineNum++) {
                                let yLedger = staffTop - lineSpacing * (lineNum + 1)
                                for (let pass = 0; pass < 3; pass++) {
                                    ctx.beginPath()
                                    let alpha = 0.65 + Math.random() * 0.15
                                    ctx.strokeStyle = `rgba(35, 25, 25, ${alpha})`
                                    ctx.lineWidth = 1 + Math.random()
                                    let jitter = (Math.random() - 0.5) * 1.5
                                    ctx.moveTo(xStart, yLedger + jitter)

                                    for (let j = 1; j <= 5; j++) {
                                        let t = j / 5
                                        let x = xStart + (xEnd - xStart) * t
                                        let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 +
                                                      (Math.random() - 0.5)) * 1.5
                                        ctx.lineTo(x, yLedger + yOffset)
                                    }
                                    ctx.stroke()
                                }
                            }
                        }

                        if(lowerLedgers)
                        {
                            // Bottom ledger lines
                            let bottomLineY = staffTop + 4 * lineSpacing
                            for (let lineNum = 0; lineNum < 3; lineNum++) {
                                let yLedger = bottomLineY + lineSpacing * (lineNum + 1)
                                for (let pass = 0; pass < 3; pass++) {
                                    ctx.beginPath()
                                    let alpha = 0.65 + Math.random() * 0.15
                                    ctx.strokeStyle = `rgba(35, 25, 25, ${alpha})`
                                    ctx.lineWidth = 1 + Math.random()
                                    let jitter = (Math.random() - 0.5) * 1.5
                                    ctx.moveTo(xStart, yLedger + jitter)

                                    for (let j = 1; j <= 5; j++) {
                                        let t = j / 5
                                        let x = xStart + (xEnd - xStart) * t
                                        let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 +
                                                      (Math.random() - 0.5)) * 1.5
                                        ctx.lineTo(x, yLedger + yOffset)
                                    }
                                    ctx.stroke()
                                }
                            }
                        }

                        ctx.restore()
                    }
                }


                Image {
                    id: clef
                    source: showTrebleClef ? "Common/Images/treble-clef-manuscript-style.png" : "Common/Images/bass-clef-manuscript-style.png"
                    height: showTrebleClef ? lineSpacing * 6 : lineSpacing * 6
                    fillMode: Image.PreserveAspectFit
                    x: lineSpacing * 0.6
                    // Align vertically with center of staff
                    y: showTrebleClef ? (staffCenterY - height / 2) + 10 : (staffCenterY - height / 2) + 1 // -xx for aligning to E4 line by a few px
                    z: 1
                }
            }



            Item {
                id: switchColumn
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3 * 1

                Item {
                    id: switchWrapper1
                    width: parent.width
                    y: switchColumn.mapFromItem(container, 0, guideHigh.y).y - switch1.height/2

                    Text {
                        text: "Ledgers"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: switch1.top
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 20
                        color: "#3b2a1b"
                    }
                    SwitchButton {
                        id: switch1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width * 0.5, 120)  // cap here
                        height: width / aspect
                        checked: showTrebleClef ? rangeSettings[2] : rangeSettings[6]
                    }
                }

                Item {
                    id: switchWrapper2
                    width: parent.width
                    y: switchColumn.mapFromItem(container, 0, guideMid.y).y - switch2.height/2

                    Text {
                        text: "Staff"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: switch2.top
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 20
                        color: "#3b2a1b"
                    }
                    SwitchButton {
                        id: switch2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width * 0.5, 120)  // cap here
                        height: width / aspect
                        checked: showTrebleClef ? rangeSettings[1] : rangeSettings[5]
                    }
                }

                Item {
                    id: switchWrapper3
                    width: parent.width
                    y: switchColumn.mapFromItem(container, 0, guideLow.y).y - switch3.height/2

                    Text {
                        text: "Ledgers"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: switch3.top
                        font.family: garamond.name
                        fontSizeMode: Text.Fit
                        minimumPointSize: 1
                        font.pointSize: 20
                        color: "#3b2a1b"
                    }
                    SwitchButton {
                        id: switch3
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width * 0.5, 120)  // cap here
                        height: width / aspect
                        checked: showTrebleClef ? rangeSettings[3] : rangeSettings[7]
                    }
                }

                Connections {
                    target: switch1
                    function onCheckedChanged() {
                        if(showTrebleClef) {
                            rangeSettings[2] = switch1.checked
                        }
                        else{
                            rangeSettings[6] = switch1.checked
                        }
                        canvas.requestPaint()
                    }
                }
                Connections {
                    target: switch2
                    function onCheckedChanged() {
                        if(showTrebleClef) {
                            rangeSettings[1] = switch2.checked
                        }
                        else{
                            rangeSettings[5] = switch2.checked
                        }
                        canvas.requestPaint()
                    }
                }
                Connections {
                    target: switch3
                    function onCheckedChanged() {
                        if(showTrebleClef) {
                            rangeSettings[3] = switch3.checked
                        }
                        else{
                            rangeSettings[7] = switch3.checked
                        }
                        canvas.requestPaint()
                    }
                }
            }
        }
        RowLayout {
            id: bottomControls
            Layout.fillWidth: true
            //Layout.preferredHeight: switch1.height * 2
            //Layout.preferredWidth: parent.width / 3 * 2

            Item { Layout.fillWidth: true } // spacer to center content

            Column {
                Layout.preferredWidth: switch1.width * 1.2
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                spacing: 5
                Image {
                    source: "Common/Images/noun-sharp.svg"
                    fillMode: Image.PreserveAspectFit
                    width: sharpSwitch.width * 0.8
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                SwitchButton {
                    id: sharpSwitch
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: mainSwitchW
                    height: mainSwitchH
                    checked: rangeSettings[10]
                }
                Connections {
                    target: sharpSwitch
                    function onCheckedChanged(){
                        rangeSettings[10] = sharpSwitch.checked
                    }
                }
            }

            Item { Layout.preferredWidth: mainSwitchW / 2  } // spacer to center content

            Column {
                //Layout.preferredWidth: switch1.width * 1.2
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                spacing: 5
                Image {
                    source: "Common/Images/flat.svg"
                    fillMode: Image.PreserveAspectFit
                    width: flatsSwitch.width * 0.8
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                SwitchButton {
                    id: flatsSwitch
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: mainSwitchW
                    height: mainSwitchH
                    checked: rangeSettings[11]
                }
                Connections {
                    target: flatsSwitch
                    function onCheckedChanged(){
                        rangeSettings[11] = flatsSwitch.checked
                    }
                }
            }


           Item { Layout.fillWidth: true } // spacer to center content

        }
        Item { Layout.fillWidth: true; Layout.preferredHeight: mainSwitchH / 2 }

        RowLayout {
            id: bottomButtons
            Layout.preferredHeight: parent.height * 0.1
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            spacing: 12

            Item { Layout.fillWidth: true } // left spacer

            MainButton {
                id: back
                Layout.preferredHeight: bottomButtons.height
                Layout.preferredWidth: Layout.preferredHeight * 2
                Layout.maximumWidth: Layout.preferredHeight * 2   // ✅ hard cap
                mainButtonText: "Back"
                mainButtonClicked.onClicked: loaderSource = "TrebleSettings.qml"
            }

            MainButton {
                id: next
                Layout.preferredHeight: bottomButtons.height
                Layout.preferredWidth: Layout.preferredHeight * 2
                Layout.maximumWidth: Layout.preferredHeight * 2   // ✅ hard cap
                mainButtonText: "Next"
                mainButtonClicked.onClicked: {
                        if(rangeSettings[5] === true || rangeSettings[6] === true || rangeSettings[7] === true){
                            rangeSettings[4] = true
                        }
                        else{
                            rangeSettings[4] = false
                        }
                        if(rangeSettings[1] === true || rangeSettings[2] === true || rangeSettings[3] === true){
                            rangeSettings[0] = true
                        }
                        else{
                            rangeSettings[0] = false
                        }
                    appSettings.setRange(rangeSettings)
                    noteSelector.setNotePool(usingTrebleClef, trebleClef,
                                             trebleUpperLedger, trebleLowerLedger,
                                             usingBassClef, bassClef,
                                             bassUpperLedger, bassLowerLedger,
                                             trebleSharps, bassFlats,
                                             bassSharps, bassFlats)
                    appSettings.setFirstLaunch(false)

                    appSettings.saveSettings()
                    loader.source = "SightReadingActive.qml"
                }
            }

            // Spacer on the right to center buttons
            Item { Layout.fillWidth: true }
        }
    }


    Popup {
        id: myPopup
        modal: true
        dim: true
        focus: true
        z: 9999

        width: parentWidth * 0.75
        height: parentHeight * 0.6

        // Qt 6.9 REQUIRED
        contentWidth: width * 0.85
        contentHeight: height * 0.95

        anchors.centerIn: parent
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            radius: 20
            border.color: "#3b2a1b"
            border.width: 2
            Image {
                anchors.fill: parent
                source: "Common/Images/parchment_paper.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.92
            }
        }

        contentItem: Item {
            id: popupRoot
            width: myPopup.contentWidth
            height: myPopup.contentHeight

            // Text block (column)
            Column {
                id: textColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: parentHeight * 0.03

                Text {
                    text: "TIP:\n"
                    font.pointSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Text {
                    text: firstTipActive ? tip1 : tip2
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }

            // BUTTON ANCHORED TO BOTTOM
            MainButton {
                id: okButton
                width: parent.width * 0.3
                height: parent.height * 0.12
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.03
                mainButtonText: firstTipActive ? "Next" : "OK"

                mainButtonClicked.onClicked: {
                    if (firstTipActive)
                        firstTipActive = false
                    else
                        myPopup.close()
                }
            }
        }
    }
}

