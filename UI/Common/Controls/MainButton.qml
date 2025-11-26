import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

Item {
   Layout.fillHeight: true
   Layout.fillWidth: true

   property alias mainButtonText: text.text
   property alias mainButtonClicked: mouseArea
   property alias parchmentOverlay: parchmentOverlay.opacity
   property alias mainButtonTextColor: text.color
   property bool nextImageVisible: false
   // Button container for layout
   Item {
      id: buttonWrapper
      anchors.fill: parent
      transformOrigin: Item.Center
      scale: mouseArea.pressed ? 0.95 : 1.0  // Now this works!

      Rectangle {
         id: antiqueButton
         anchors.fill: parent
         radius: 8
         color: "#f3e0b5"
         border.color: "#6e4f2d"
         border.width: 2
         scale: mouseArea.pressed ? 0.95 : 1.0
         clip: true  // Prevent texture from overflowing corners

         // Parchment texture overlay
         Image {
            id: parchmentOverlay
            anchors.fill: parent
            source: "../Images/Button-Overlay-parchment.png"   // You must provide this image
            opacity: 0.6 // Subtle effect
            clip: true
         }

         FontLoader {
            id: garamond
            source: "../Fonts/Allura-Regular.ttf"
         }

         Image{
            id: nextImage
            visible: nextImageVisible
            anchors.fill: parent
            anchors.leftMargin: 12
            source: "../Images/Next.svg"
         }
         Text {
            id: text
            visible: !nextImageVisible
            text: mainButtonText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: garamond.name
            anchors.fill: parent
            anchors.margins: 10
            fontSizeMode: Text.Fit
            minimumPointSize: 1
            font.pointSize: 32
            color: "#3b2a1b"
         }

         MouseArea {
            id: mouseArea
            anchors.fill: parent
         }
      }
   }
}


