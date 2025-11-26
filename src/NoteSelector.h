#ifndef NOTESELECTOR_H
#define NOTESELECTOR_H

#include <QObject>
#include <QRandomGenerator>
#include <QSet>

class NoteSelector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentNote READ currentNote NOTIFY currentNoteChanged)
    Q_PROPERTY(QStringList notePool READ notePool NOTIFY notePoolChanged)
    Q_PROPERTY(bool isUpperLedger READ isUpperLedger NOTIFY isUpperLedgerChanged)
    Q_PROPERTY(bool blockUpperLedger READ blockUpperLedger WRITE setBlockUpperLedger NOTIFY blockUpperLedgerChanged)
    Q_PROPERTY(bool blockLowerLedger READ blockLowerLedger WRITE setBlockLowerLedger NOTIFY blockLowerLedgerChanged)

    Q_PROPERTY(QString whichClef READ whichClef NOTIFY whichClefChanged)

public:
    explicit NoteSelector(QObject *parent = nullptr);

    QString currentNote() const;
    Q_INVOKABLE void nextNote();
    QStringList notePool();
    bool isUpperLedger();

    // block flags (opposite-ledge logic)
    bool blockUpperLedger() const { return m_blockUpper; }
    bool blockLowerLedger() const { return m_blockLower; }
    Q_INVOKABLE void setBlockUpperLedger(bool v){ if (m_blockUpper==v) return; m_blockUpper=v; emit blockUpperLedgerChanged(); }
    Q_INVOKABLE void setBlockLowerLedger(bool v){ if (m_blockLower==v) return; m_blockLower=v; emit blockLowerLedgerChanged(); }

    QString whichClef();

signals:
    void currentNoteChanged();
    void notePoolChanged();
    void isUpperLedgerChanged();
    void blockUpperLedgerChanged();
    void blockLowerLedgerChanged();

    void whichClefChanged();

public slots:
    void setNotePool(bool usingTrebleClef, bool trebleClef,
                    bool trebleUpperLedger, bool trebleLowerLedger,
                    bool usingBassClef, bool bassClef,
                    bool bassUpperLedger, bool bassLowerLedger,
                    bool trebleSharps, bool trebleFlats,
                     bool bassSharps, bool bassFlats);

private:
    QStringList m_notePool;
    QString m_currentNote;
    bool m_isUpperLedger = false;

    bool m_blockUpper = false;
    bool m_blockLower = false;

    inline bool isUpperLedgerNote(const QString& n) const {
        static const QSet<QString> trebleUpper = {
            "G5","A5","B5","C6","D6","E6",
            "Gb5","Ab5","Bb5","Cb6","Db6","Eb6",
            "G#5","A#5","B#5","C#6","D#6","E#6"
        };

        static const QSet<QString> bassUpper = {
            "B3","C4","D4","E4","F4","G4",
            "Bb3","Cb4","Db4","Eb4","F#4","G#4",
            "B#3","C#4","D#4","E#4","F#4","G#4"
        };

        return trebleUpper.contains(n) || bassUpper.contains(n);
    }

    inline bool isLowerLedgerNote(const QString& n) const {
        static const QSet<QString> trebleLower = {
            "A3","B3","C4","D4",
            "Ab3","Bb3","Cb4","Db4",
            "A#3","B#3","C#4","D#4"
        };

        static const QSet<QString> bassLower = {
            "C2","D2","E2","F2",
            "C#2","D#2","E#2","F#2",
            "Db","Eb2","Fb2",
        };

        return trebleLower.contains(n) || bassLower.contains(n);
    }

    QVector<char> m_poolClef;   // 'T' for treble, 'B' for bass
    QString m_whichClef;
};

#endif // NOTESELECTOR_H
