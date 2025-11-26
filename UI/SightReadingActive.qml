import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import "Common/Controls"

Item {
    anchors.fill: parent
    function start() {
        startTime = Date.now() - elapsedMs
        goalTimer.running = true
    }

    Component.onCompleted: {
        noteSelector.nextNote()
        console.log("NEW NOTE")
        winStreakModel.setStreakPopup()
        elapsedMs = appSettings.savedElapsedMs
        start()
    }

    property real lineSpacing: canvas.height / 10
    property real staffTop: canvas.height / 4

    property real staffHeight: 4 * lineSpacing       // 5-line staff spans 4 spacings
    property real staffCenterY: staffTop + staffHeight / 2

    property int smallerText: 16
    property int correctStreak: 0

    property int startTime: 0
    property int elapsedMs: appSettings.savedElapsedMs

    property string lastCorrectPitch: ""

    property bool wiggleEnabled: appSettings.wiggleEnabled

    onCorrectStreakChanged: {
        if (correctStreak > 0 && correctStreak % 10 === 0) {
            successPopup.runCycle()
        }
    }

    Shortcut {
      sequences: ["Q"]
      context: Qt.ApplicationShortcut
      onActivated: testerCorrectNote()
    }
    Shortcut {
      sequences: ["E"]
      context: Qt.ApplicationShortcut
      onActivated: testerWrongNote()
    }
    // test function for CORRECT NOTE
    function testerCorrectNote()
    {
        console.log("[TESTER]:: Correct note forced.")
        microphoneInput.pitchDetectedTester(noteSelector.currentNote);
    }
    // test function for WRONG NOTE
    function testerWrongNote()
    {
        console.log("[TESTER]:: Wrong note forced.")
        microphoneInput.pitchDetectedTester("XX");
    }


    Connections {
        target: microphoneInput
        function onPitchDetectedChanged()
        {
            var pitchDetected = microphoneInput.pitchDetected
            // IGNORE unstable or placeholder detections
            if (pitchDetected === "-" || pitchDetected === "" || pitchDetected === undefined)
                return;

            console.log("Raw pitch detected:", pitchDetected)

            function isCorrect(detected, shown)
            {
                const nd = normalize(detected)
                const ns = normalize(shown)
                console.log("Comparing Detected:", nd, "Shown:", ns)

                // TREBLE CLEF → strict match only
                if (whichClef === "treble")
                    return nd === ns

                // ---- BASS CLEF: allow same note 1 octave higher ----

                // Extract pitch class + octave
                const det = nd.match(/^([A-G]#?)(\d)$/)
                const sho = ns.match(/^([A-G]#?)(\d)$/)
                if (!det || !sho)
                    return false

                const detClass = det[1]
                const detOct   = parseInt(det[2])
                const shoClass = sho[1]
                const shoOct   = parseInt(sho[2])

                // Must match pitch class first
                if (detClass !== shoClass)
                    return false

                // Accept exact octave
                if (detOct === shoOct)
                    return true

                // Accept same pitch but one octave higher (bass clef only)
                if (detOct === shoOct + 1)
                    return true

                return false
            }

            if (isCorrect(pitchDetected, currentNote))
            {
                lastCorrectPitch = pitchDetected   // << NEW
                correctStreak+= 1
                noteHeadColor = "green";
                canvas.requestPaint()
                console.log("CORRECT!!!")
                noteHeadGreenCorrect.start()
                canWiggle = true // Reset cooldown
            }
            else if (wiggleEnabled && canWiggle && pitchDetected !== lastCorrectPitch)
            {
                console.log("Incorrect pitch, triggering wiggle.")
                correctStreak = 0
                wiggleAnimation.restart()
                canvas.requestPaint()
                canWiggle = false

                // Reset canWiggle after 300ms
                Qt.createQmlObject(`
                    import QtQuick 2.15;
                    Timer {
                        interval: 300; running: true; repeat: false
                        onTriggered: canWiggle = true
                    }
                `, canvas, "ResetWiggleCooldown")
            }

            function normalize(note) {
                console.log("NORMALIZE NOTE CALLED");

                // --- Octave Fix: All notes C6 and above count as one octave lower ---
                if (note.match(/^([A-G][#b]?)([6-8])$/)) {
                    let parts = note.match(/^([A-G][#b]?)(\d)$/)
                    let base = parts[1]
                    let oct = parseInt(parts[2])
                    return base + (oct - 1)    // shift down 1 octave
                }

                const map = {
                    "Cb": ["B", -1],
                    "Db": ["C#", 0],
                    "Eb": ["D#", 0],
                    "Fb": ["E", 0],
                    "Gb": ["F#", 0],
                    "Ab": ["G#", 0],
                    "Bb": ["A#", 0],
                    "E#": ["F", 0],
                    "B#": ["C", 1]
                }

                const match = note.match(/^([A-Ga-g])([b#]?)(\d)$/)
                if (!match) return note

                const [, letter, accidental, octaveStr] = match
                const base = letter.toUpperCase() + accidental
                const [normalizedBase, octaveShift] = map[base] || [base, 0]
                const normalizedOctave = parseInt(octaveStr) + octaveShift

                return normalizedBase + normalizedOctave
            }
        }
    }

    Connections {
        target: noteSelector
        function onCurrentNoteChanged()
        {
            currentNote = noteSelector.currentNote
            canvas.requestPaint()
        }
    }

    Timer {
        id: noteHeadGreenCorrect
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            noteHeadColor = "black"
            noteSelector.nextNote()
            canvas.requestPaint()
            noteHeadGreenCorrect.stop()
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.preferredHeight: parent.height / 8 * 1
            Layout.margins: 5

            MainButton {
                mainButtonText: "Range";
                mainButtonClicked.onClicked: {
                    appSettings.savedElapsedMs = elapsedMs
                    loader.source = "RangeSelector.qml"
                }
            }

            Item{ Layout.fillHeight: true; Layout.fillWidth: true }

            MainButton {
                mainButtonText: "Settings";
                mainButtonClicked.onClicked: {
                    appSettings.savedElapsedMs = elapsedMs
                    loader.source = "Settings.qml"
                }
            }
        }

        Timer {
            id: goalTimer
            interval: 1000/30
            repeat: true
            running: false
            onTriggered: {
                elapsedMs = Date.now() - startTime
            }
        }

        Rectangle {
            id: container
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: parent.height / 8 * 6
            Layout.preferredWidth: parent.width
            Layout.margins: 0
            property real wiggleAngle: 0
            onWiggleAngleChanged: {
                canvas.requestPaint()
            }
            color: "transparent"

            SequentialAnimation {
                id: wiggleAnimation
                running: false
                PropertyAnimation { target: container; property: "wiggleAngle"; to: -5; duration: 50 }
                PropertyAnimation { target: container; property: "wiggleAngle"; to: 5; duration: 50 }
                PropertyAnimation { target: container; property: "wiggleAngle"; to: -3; duration: 40 }
                PropertyAnimation { target: container; property: "wiggleAngle"; to: 3; duration: 40 }
                PropertyAnimation { target: container; property: "wiggleAngle"; to: 0; duration: 30 }
            }

            property real noteX: canvas.width * 0.6
            property real noteY: yForNote(currentNote)

            function yForNote(note) {
                // remove accidental from note name for positioning
                let base = note
                if(note.length === 3 && (note[1] === "#" || note[1] === "b"))
                {
                    base = note[0] + note[2]
                }

                const offset = lineSpacing * 0.25

                const treblePositions = ["G3","A3","B3","C4","D4","E4","F4","G4","A4","B4","C5","D5","E5","F5","G5","A5","B5","C6","D6","E6"];
                const bassPositions   = ["B1","C2","D2","E2","F2","G2","A2","B2","C3","D3","E3","F3","G3","A3","B3","C4","D4","E4","F4","G4"];
                const positions = (whichClef === "treble") ? treblePositions : bassPositions;

                const index = positions.indexOf(base)
                if (index === -1) return -100

                // G3 starts at 6.5 lineSpacings from staffTop, and each step goes up by 0.5
                return staffTop + (6.5 - index * 0.5) * lineSpacing - offset
            }

            Canvas {
                id: canvas
                anchors.fill: parent
                onPaint: {
                    let ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.save()
                    ctx.translate(width / 2, height / 2)
                    ctx.scale(0.8, 0.8)
                    ctx.rotate(container.wiggleAngle * Math.PI / 180)
                    ctx.translate(-width / 2, -height / 2)

                    ctx.lineCap = "round"

                    // Draw staff lines
                    let staffSegments = 30
                    let variance = 1.5
                    let passes = 3
                    for (let lineIndex = 0; lineIndex < staffLineCount; lineIndex++) {
                        let yBase = staffTop + lineIndex * lineSpacing

                        for (let pass = 0; pass < passes; pass++) {
                            ctx.beginPath()
                            let inkAlpha = 0.65 + Math.random() * 0.2
                            ctx.strokeStyle = "rgba(35, 25, 25, " + inkAlpha + ")"
                            ctx.lineWidth = 1 + Math.random() * 1.2

                            ctx.moveTo(0, yBase + (Math.random() - 0.5) * variance)

                            for (let j = 1; j <= staffSegments; j++) {
                                let t = j / staffSegments
                                let x = width * t
                                let wobble = Math.sin(t * Math.PI * 2 + lineIndex) * 0.5
                                let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 + (Math.random() - 0.5) + wobble) * variance
                                ctx.lineTo(x, yBase + yOffset)
                            }
                            ctx.stroke()
                        }
                    }
                    // Draw the notehead
                    let noteY = container.yForNote(currentNote)
                    let noteX = width * 0.6

                    if (noteY !== -100) {
                        ctx.save()
                        ctx.translate(noteX, noteY)
                        ctx.rotate(-15 * Math.PI / 180)
                        // Main notehead
                        ctx.beginPath()
                        ctx.ellipse(0, 0, lineSpacing * 1, lineSpacing * 0.8, 0, 0, Math.PI * 2)
                        ctx.fillStyle = noteHeadColor
                        ctx.fill()
                        ctx.restore()
                    }
                    // Ledger lines above
                    let topLineY = staffTop
                    let dyAbove = topLineY - noteY
                    if (noteY < topLineY) {
                        let stepsAbove = Math.floor(dyAbove / (lineSpacing / 2))
                        let fullLedgerAbove = Math.floor(stepsAbove / 2)
                        let ledgerLength = lineSpacing * 2.1
                        let ledgerOffset = lineSpacing * 0.5
                        let xStart = noteX - ledgerLength / 2 + ledgerOffset
                        let xEnd = noteX + ledgerLength / 2 + ledgerOffset

                        for (let lineNum = 0; lineNum < fullLedgerAbove && lineNum < 5; lineNum++) {
                            let yLedger = topLineY - lineSpacing * (lineNum + 1)
                            for (let pass = 0; pass < 3; pass++) {
                                ctx.beginPath()
                                let alpha = 0.65 + Math.random() * 0.15
                                ctx.strokeStyle = "rgba(35, 25, 25, " + alpha + ")"
                                ctx.lineWidth = 1 + Math.random() * 1
                                let jitter = (Math.random() - 0.5) * 1.5

                                ctx.moveTo(xStart, yLedger + jitter)

                                let segs = 5
                                for (let j = 1; j <= segs; j++) {
                                    let t = j / segs
                                    let x = xStart + (xEnd - xStart) * t
                                    let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 + (Math.random() - 0.5)) * 1.5
                                    ctx.lineTo(x, yLedger + yOffset)
                                }
                                ctx.stroke()
                            }
                        }
                    }
                    // Ledger lines below
                    let bottomLineY = staffTop + 4 * lineSpacing
                    let dyBelow = noteY - bottomLineY
                    if (noteY > bottomLineY) {
                        let stepsBelow = Math.floor(dyBelow / (lineSpacing / 2))
                        let isOnLine = stepsBelow % 2 === 0
                        let fullLedgerBelow = Math.floor((stepsBelow + (isOnLine ? 0 : 1)) / 2)

                        let ledgerLength2 = lineSpacing * 2.1
                        let ledgerOffset2 = lineSpacing * 0.5
                        let xStart2 = noteX - ledgerLength2 / 2 + ledgerOffset2
                        let xEnd2 = noteX + ledgerLength2 / 2 + ledgerOffset2

                        for (let lineNum = 0; lineNum < fullLedgerBelow && lineNum < 5; lineNum++) {
                            let yLedger = bottomLineY + lineSpacing * (lineNum + 1)

                            for (let pass = 0; pass < 3; pass++) {
                                ctx.beginPath()
                                let alpha = 0.65 + Math.random() * 0.15
                                ctx.strokeStyle = "rgba(35, 25, 25, " + alpha + ")"
                                ctx.lineWidth = 1 + Math.random() * 1
                                let jitter = (Math.random() - 0.5) * 1.5

                                ctx.moveTo(xStart2, yLedger + jitter)

                                let segs = 5
                                for (let j = 1; j <= segs; j++) {
                                    let t = j / segs
                                    let x = xStart2 + (xEnd2 - xStart2) * t
                                    let yOffset = (Math.sin(t * Math.PI * 4 + Math.random()) * 0.5 + (Math.random() - 0.5)) * 1.5
                                    ctx.lineTo(x, yLedger + yOffset)
                                }
                                ctx.stroke()
                            }
                        }
                    }
                    ctx.restore()
                }

                Image {
                    id: treble
                    source: whichClef === "treble" ? "Common/Images/treble-clef-manuscript-style.png" : "Common/Images/bass-clef-manuscript-style.png"
                    fillMode: Image.PreserveAspectFit

                    // SIZE BY STAFF, NOT BY CANVAS
                    // ~7 staff spaces tall is a nice clef size (tweak 6.5–8 to taste)
                    height: whichClef === "treble" ? lineSpacing * 6 : lineSpacing * 4.75
                    // PreserveAspectFit will compute width automatically from height

                    // PLACE CENTERED ON THE STAFF VERTICALLY
                    y: whichClef === "treble" ? (staffCenterY - height / 2) + 4 : (staffCenterY - height / 2) + 3 // -2 for aligning to E4 line by a few px
                    // PLACE A BIT LEFT OF THE NOTEHEAD (tweak the 0.08)
                    x: whichClef === "treble" ? canvas.width * 0.06 : canvas.width * 0.01
                    z: 1
                }
                Image {
                    visible: if(currentNote.includes("b")) true; else false
                    source: "Common/Images/flat.svg"
                    width: lineSpacing * 1
                    height: lineSpacing * 1.5
                    //visible: container.noteY !== -100
                    x: container.noteX - (width * 1.2) + lineSpacing * 0.1
                    y: canvas.height / 2 + (container.noteY - canvas.height / 2) * 0.8 - height / 2 - lineSpacing * 0.2
                    z: 1
                }

                Image {
                    source: "Common/Images/noun-sharp.svg"
                    visible: if(currentNote.includes("#")) true; else false
                    width: lineSpacing * 1.8
                    height: lineSpacing * 1.5
                    //visible: container.noteY !== -100
                    x: container.noteX - (width * 1.2) + lineSpacing * 0.6
                    y: canvas.height / 2 + (container.noteY - canvas.height / 2) * 0.8 - height / 2 + lineSpacing * 0.2
                    z: 2
                }
            }

            // Success Pop Up
            Rectangle {
                id: successPopup
                property bool popupBottom: false   // <-- latched side for this cycle

                height: parent.height * 0.20
                width: (parent.width / 6) * 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                // *latched* side for positioning (no jump mid-fade)
                y: popupBottom
                   ? canvas.mapToItem(parent, 0, canvas.height).y - height - 8  // bottom
                   : canvas.mapToItem(parent, 0, 0).y + 8                       // top
                visible: false  // start hidden
                opacity: 0  // and transparent
                layer.enabled: true
                layer.smooth: true
                enabled: opacity > 0.01 // ignore clicks while hidden
                Rectangle {
                    id: portrait
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.4
                    color: "Transparent"
                    Image{
                        anchors.fill: parent
                        source: "Common/Images/ComposerPortraits/" + winStreakModel.portrait
                    }
                }
                Rectangle {
                    anchors.left: portrait.right
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: "transparent"
                    FontLoader {
                       id: garamond
                       source: "Common/Fonts/Allura-Regular.ttf"
                    }
                    Text {
                       id: congrats
                       text: winStreakModel.quote
                       horizontalAlignment: Text.AlignLeft
                       verticalAlignment: Text.AlignVCenter
                       font.family: garamond.name
                       anchors.fill: parent
                       fontSizeMode: Text.Fit
                       minimumPointSize: 1
                       font.pointSize: 28
                       color: "#3b2a1b"
                    }
                }

                // call this to (re)run the whole cycle
                function runCycle() {
                    // Latch the side for this cycle: bottom if last correct was upper ledger
                    popupBottom = !noteSelector.isLowerLedger

                    // Block the side that would overlap the popup while it's visible
                    if (popupBottom) {
                        noteSelector.setBlockLowerLedger(true)   // popup below → block lower ledger notes
                    }
                    else {
                        noteSelector.setBlockUpperLedger(true)   // popup above → block upper ledger notes
                    }

                    visible = true
                    opacity = 0
                    fadeCycle.restart()
                }

                // child updates
                function updateChildrenWhileHidden() {
                    winStreakModel.setStreakPopup()
                }

                SequentialAnimation {
                    id: fadeCycle
                    running: false
                    PropertyAnimation { target: successPopup; property: "opacity"; from: 0; to: 1; duration: 300 }
                    PauseAnimation { duration: 5000 } // stay visible
                    PropertyAnimation { target: successPopup; property: "opacity"; to: 0; duration: 250 }
                    ScriptAction {
                        script: {
                            successPopup.updateChildrenWhileHidden()
                            // Clear blocks after fade completes
                            noteSelector.setBlockUpperLedger(false)
                            noteSelector.setBlockLowerLedger(false)
                            successPopup.visible = false
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height / 8 * 1

            Rectangle{
                anchors.fill: parent
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    height: parent.height
                    anchors.left: parent.left
                    width: parent.width / 4
                    color: "Transparent"
                    Text {
                       id: text
                       anchors.leftMargin: 10
                       anchors.fill: parent
                       text: {
                           let m = Math.floor(elapsedMs / 60000);
                           let s = Math.floor((elapsedMs / 1000) % 60);
                           return m + " : " + (s < 10 ? "0" + s : s);
                       }
                       horizontalAlignment: Text.AlignHCenter
                       verticalAlignment: Text.AlignVCenter
                       font.family: garamond.name
                       fontSizeMode: Text.Fit
                       minimumPointSize: 1
                       font.pointSize: 100
                       color: { elapsedMs >= appSettings.goalTime * 60 * 1000
                              ? "green"
                              : "black"
                       }
                    }
                }

                Rectangle {
                    id: nextContainer
                    anchors.top: parent.top
                    height: parent.height / 2
                    anchors.right: parent.right
                    width: parent.width / 3
                    color: "transparent"
                    Text {
                       id: nextArrow
                       text: "Skip"
                       horizontalAlignment: Text.AlignHCenter
                       verticalAlignment: Text.AlignVCenter
                       font.family: garamond.name
                       anchors.fill: parent
                       anchors.margins: 10
                       fontSizeMode: Text.Fit
                       minimumPointSize: 28
                       font.pointSize: 28
                       color: "#3b2a1b"
                    }
                }


                Rectangle{
                    anchors.right: parent.right
                    anchors.top: nextContainer.bottom
                    anchors.bottom: parent.bottom
                    color: "transparent"
                    width: parent.width / 3
                    Image{
                       id: nextImage
                       scale: mouseArea.pressed ? 0.75 : 0.8
                       anchors.fill: parent
                       fillMode: Image.PreserveAspectFit
                       source: "Common/Images/Next.svg"
                    }
                    MouseArea {
                       id: mouseArea
                       anchors.fill: parent
                       onClicked: { noteSelector.nextNote() }
                    }
                }
            }
        }
    }
}
