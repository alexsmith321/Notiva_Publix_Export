import QtQuick
import QtQuick.Controls.Basic

Switch {
    id: control

    // Hints only — parent decides actual size
    property real aspect: 2.5      // width : height
    implicitWidth: 120
    implicitHeight: implicitWidth / aspect

    indicator: Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.checked ? "#8b3a2f" : "#3b2a1b"
        border.color: "#3b2a1b"

        Rectangle {
            width: parent.height
            height: parent.height
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: control.checked ? parent.width - width : 0
            color: control.down ? "#cccccc" : "#ffffff"
            border.color: "#3b2a1b"
        }
    }
}
