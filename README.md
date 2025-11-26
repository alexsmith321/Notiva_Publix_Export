# Notiva – Open Source Components (LGPL 3)

This repository contains the **open-source portions** of the Notiva app, as required under the terms of the **GNU Lesser General Public License (LGPL) version 3**.

Notiva is a music sight-reading training tool developed using Qt (QML + C++).  
This public repository includes only the components that must be provided under LGPL to allow rebuilding and relinking with the Qt libraries.

**Important:**  
This repository does *not* include any proprietary artwork, images, icons, fonts, audio files, or other assets.  
These are not required for compliance with LGPL and remain the intellectual property of the developer.

---

## Included in this repository

### C++ Source (`src/`)
Contains all application logic written in C++.

### QML Source (`UI/`)
Contains all user-interface logic written in QML (no assets included).

### Qt Resource Files (`*.qrc`)
Included for completeness.  
These list asset paths but do **not** include the assets themselves.

### Android Project Templates (`android/`)
Contains:
- AndroidManifest.xml  
- build.gradle  
- gradlew / gradlew.bat  
- gradle/wrapper files  

The `res/` directory has been intentionally removed to avoid distributing proprietary images.

### CMake Build Configuration
Allows rebuilding the application with a different Qt version.

### LGPL v3 License
Included as required.

---

## Not included

The following items remain private and proprietary:

- App icons  
- Notehead graphics  
- Staff parchment background  
- All PNG/SVG assets  
- Custom fonts  
- Audio samples  
- Android `res/` imagery  
- iOS asset catalogs  
- Keystores or signing files  
- App Store / Play Store promotional artwork  

These are not covered under LGPL and are not required for relinking the Qt libraries.

---

## Building from Source

To rebuild the open-source portion of Notiva:

### **Prerequisites**
- Qt 6.9 or newer  
- CMake 3.16+  
- Ninja or Make  
- Android SDK/NDK (optional for Android)

### **Steps**
1. Install Qt with QML, Quick, and necessary toolchains.  
2. Clone this repository.  
3. Configure the build:

   ```
   cmake -S . -B build
   cmake --build build
   ```
4. Provide your own assets or modify the `.qrc` files accordingly.

---

## License

All files in this repository are licensed under **LGPL v3**, unless noted otherwise.  
See `LICENSE.LGPL` for details.

Proprietary assets, brand elements, and artwork are **NOT** included in this license.

---

## Contact
For questions or licensing inquiries, please contact:

**Alexander Smith**  
alex_smith321@yahoo.com
SwissMailBox - 397
12 Rue Le Corbusier
1208 Gevena
Switzerland