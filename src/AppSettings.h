#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<bool> range READ range WRITE setRange NOTIFY rangeChanged)
    Q_PROPERTY(bool firstLaunch READ firstLaunch WRITE setFirstLaunch NOTIFY firstLaunchChanged)
    Q_PROPERTY(int goalTime READ goalTime WRITE setGoalTime NOTIFY goalTimeChanged)
    Q_PROPERTY(int savedElapsedMs READ savedElapsedMs WRITE setSavedElapsedMs NOTIFY savedElapsedMsChanged)
    Q_PROPERTY(bool wiggleEnabled READ wiggleEnabled WRITE setWiggleEnabled NOTIFY wiggleEnabledChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    QList<bool> range();
    bool firstLaunch();
    int goalTime();
    int savedElapsedMs() const { return m_savedElapsedMs; }
    bool wiggleEnabled() const { return m_wiggleEnabled; }
signals:

    void rangeChanged();
    void firstLaunchChanged();
    void goalTimeChanged();
    void savedElapsedMsChanged();
    void wiggleEnabledChanged();

public slots:

    void saveSettings();
    void setRange(QList<bool>);
    void setFirstLaunch(bool);
    void setGoalTime(int);
    void setSavedElapsedMs(int value);
    void setWiggleEnabled(bool value);

private:

    void loadSettings();
    QList<bool> m_range;
    bool m_firstLaunch;
    int m_goalTime;
    int m_savedElapsedMs = 0;
    bool m_wiggleEnabled = true;
};

#endif // APPSETTINGS_H
