#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "MicrophoneInput.h"
#include "NoteSelector.h"


#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "MicrophoneInput.h"
#include "NoteSelector.h"
#include "AppSettings.h"
#include "WinStreakModel.h"

int main(int argc, char *argv[])
{
    int retval = -1;

    try {
        QGuiApplication app(argc, argv);

        MicrophoneInput microphoneInput;
        NoteSelector noteSelector;
        AppSettings appSettings;
        WinStreakModel winStreakModel;
        QQmlApplicationEngine engine;

        QQmlContext *rootContext = engine.rootContext();
        rootContext->setContextProperty("noteSelector", &noteSelector);
        rootContext->setContextProperty("microphoneInput", &microphoneInput);
        rootContext->setContextProperty("appSettings", &appSettings);
        rootContext->setContextProperty("winStreakModel", &winStreakModel);

        // Load QML right away so signal handlers can bind
        const QUrl url(QStringLiteral("qrc:/UI/Main.qml"));
        QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                         &app, [url](QObject *obj, const QUrl &objUrl) {
                             if (!obj && url == objUrl)
                             {
                                 QCoreApplication::exit(-1);
                             }
                         }, Qt::QueuedConnection);

        engine.load(url);

        // Start microphone permission request
        qDebug() << "[MAIN] About to call microphoneInput.requestMicrophonePermission()";
        microphoneInput.requestMicrophonePermission();

        retval = app.exec();

        qInfo() << "App exiting, returned" << retval;

    }
    catch (std::exception ex)
    {
        qCritical() << "App-wide exception caught";
        qCritical("%s", ex.what());
    }

    return retval;
}

