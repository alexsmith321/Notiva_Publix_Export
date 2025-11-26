#ifndef WINSTREAKMODEL_H
#define WINSTREAKMODEL_H

#include <QObject>

class WinStreakModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString portrait READ portrait NOTIFY portraitChanged)
    Q_PROPERTY(QString quote READ quote NOTIFY quoteChanged)

public:
    explicit WinStreakModel(QObject *parent = nullptr);

    QString portrait();
    QString quote();

public slots:
    void setStreakPopup();


signals:
    void portraitChanged();
    void quoteChanged();

private:
    QString m_portrait;
    QString m_quote;
};

#endif // WINSTREAKMODEL_H
