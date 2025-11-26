#include "AppSettings.h"
#include <QObject>
#include <QSettings>
#include <QCloseEvent>
#include <QWindow>
#include <QDebug>
#include <QList>



AppSettings::AppSettings(QObject *parent)
    : QObject{parent}
{
    loadSettings();
}


void AppSettings::setRange(QList<bool> newRange)
{
    if (newRange.size() < 8) {
        // Safety check — your list should always be 12.
        qWarning() << "range list too small!";
    } else {
        // GROUP A: Clef group checks
        bool clefValid = newRange[0] || newRange[4];

        // GROUP B: Staff/ledger group checks
        bool staffValid =
            newRange[1] || newRange[2] || newRange[3] ||
            newRange[5] || newRange[6] || newRange[7];

        // If invalid -> reset defaults
        if (!clefValid || !staffValid) {
            qDebug() << "Invalid range configuration — resetting to default (0,1).";

            // Default treble clef + treble staff
            newRange[0] = true;
            newRange[1] = true;
        }
    }

    m_range = newRange;
    qDebug() << "RANGE: " << m_range;
    emit rangeChanged();
}

QList<bool> AppSettings::range()
{
    return m_range;
}

bool AppSettings::firstLaunch()
{
    return m_firstLaunch;
}

void AppSettings::setFirstLaunch(bool value)
{
    if (m_firstLaunch != value) {
        m_firstLaunch = value;
        emit firstLaunchChanged();
    }
}

void AppSettings::setGoalTime(int value)
{
    m_goalTime = value;
    emit goalTimeChanged();
}
int AppSettings::goalTime()
{
    return m_goalTime;
}

void AppSettings::setSavedElapsedMs(int value)
{
    if (m_savedElapsedMs == value)
        return;

    m_savedElapsedMs = value;
    emit savedElapsedMsChanged();
}

void AppSettings::setWiggleEnabled(bool value)
{
    if (m_wiggleEnabled == value)
        return;

    m_wiggleEnabled = value;
    emit wiggleEnabledChanged();
}

void AppSettings::saveSettings()
{
    QSettings settings("SmithPercussion", "SightReadingApp");

    QVariantList boolList;
    for (bool b : m_range)
        boolList.append(b);
    settings.setValue("range", boolList);

    settings.setValue("firstLaunch", m_firstLaunch);
    settings.setValue("goalTime", m_goalTime);

    qDebug() << "Saved Settings.";
}

void AppSettings::loadSettings()
{
    //QList<bool> defaultRange = {true, true, true, true, true};
    QSettings settings("SmithPercussion", "SightReadingApp");
    QVariantList storedList = settings.value("range", QVariant::fromValue(QVariantList{ true, true, false, false, false, false,
                                                                                       false, false, false, false, false, false })).toList();
    m_range.clear();
    for (const QVariant& v : storedList)
    {
        m_range.append(v.toBool());
    }

    m_goalTime = settings.value ("goalTime", 5).toInt();

    // Load first launch status (default = true)
    m_firstLaunch = settings.value("firstLaunch", true).toBool();

    qDebug() << "Settings Loaded -- " << m_range;
}
