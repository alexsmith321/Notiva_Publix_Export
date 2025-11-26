import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml
import QtQuick.Layouts
import "Common/Controls"

Item {
    anchors.fill: parent

    FontLoader { id: garamond; source: "Common/Fonts/Allura-Regular.ttf" }
    FontLoader { id: ebgaramond; source: "Common/Fonts/EBGaramond-Bold.ttf" }

    Image {
        id: appTitle
        source: "Common/Images/Notiva-Logo-Smoothed.png"
        height: parent.height * 0.4
        width: parent.width * 0.8
        fillMode: Image.PreserveAspectFit
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        // much smoother downscaling:
        smooth: true
        mipmap: true

        // request an image close to on-screen pixel size (handles HiDPI too)
        onWidthChanged:  sourceSize.width  = Math.round(width  * Screen.devicePixelRatio)
        onHeightChanged: sourceSize.height = Math.round(height * Screen.devicePixelRatio)

        // (Optional) force its own texture layer with smoothing
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
    }

    Column {
        anchors.centerIn: parent
        spacing: 12
        anchors.horizontalCenter: parent.horizontalCenter
        MainButton  {
            id: practice
            height: appView.height * 0.1
            width: height * 2
            mainButtonClicked.onClicked: appSettings.firstLaunch ? loaderSource = "SetGoal.qml" : loaderSource = "SightReadingActive.qml"
            parchmentOverlay: 0.3
            mainButtonText: "Practice"
        }
        MainButton {
            id: test
            height: appView.height * 0.1
            width: height * 2
            parchmentOverlay: 0.3
            mainButtonText: "Test Mode\nComing Soon"
        }
    }
}


