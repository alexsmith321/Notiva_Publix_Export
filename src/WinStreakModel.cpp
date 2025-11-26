#include "WinStreakModel.h"

WinStreakModel::WinStreakModel(QObject *parent)
    : QObject{parent}
{}


void WinStreakModel::setStreakPopup()
{

    QStringList portraitOptions = {
        "bach.svg",
        "beethoven.svg",
        "Debussy.png",
        "haydn.png",
        "mozart.png"
    };

    QStringList quoteOptions = {
        "Bravo!",
        "Wonderful!",
        "A true musician!",
        "You read fast!",
        "That was a hard one!",
        "Well done!",
        "Wonderful job!",
        "Excellent work!"
    };
    srand(static_cast<unsigned>(time(nullptr)));
    m_portrait = portraitOptions[rand() % portraitOptions.size()];
    m_quote = quoteOptions[rand() % quoteOptions.size()];

    emit quoteChanged();
    emit portraitChanged();
}

QString WinStreakModel::portrait()
{
    return m_portrait;
}

QString WinStreakModel::quote()
{
    return m_quote;
}
