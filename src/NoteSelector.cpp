#include "NoteSelector.h"
#include <QDebug>
NoteSelector::NoteSelector(QObject *parent) : QObject{parent}
{

}


void NoteSelector::setNotePool(bool usingTrebleClef, bool trebleClef,
                               bool trebleUpperLedger, bool trebleLowerLedger,
                               bool usingBassClef, bool bassClef,
                               bool bassUpperLedger, bool bassLowerLedger,
                               bool trebleSharps, bool trebleFlats,
                               bool bassSharps, bool bassFlats)
{
    m_notePool.clear();
    m_poolClef.clear();

    auto appendWithClef = [&](const QStringList& notes, char clef){
        for (const QString& n : notes) {
            m_notePool.append(n);
            m_poolClef.append(clef);
        }
    };

    if(usingTrebleClef)
    {
        QStringList trebleClefNotes;
        QStringList trebleUpperLedgerNotes;
        QStringList trebleLowerLedgerNotes;
        //QStringList sharpNotes;
        //QStringList flatNotes;

        if(trebleClef) trebleClefNotes = {"E4","F4","G4","A4","B4","C5","D5","E5","F5"};
        else trebleClefNotes.clear();

        if(trebleUpperLedger) trebleUpperLedgerNotes = {"G5","A5","B5","C6","D6","E6"};
        else trebleUpperLedgerNotes.clear();

        if(trebleLowerLedger) trebleLowerLedgerNotes = {"A3","B3","C4","D4"};
        else trebleLowerLedgerNotes.clear();

        QStringList baseT = trebleClefNotes + trebleLowerLedgerNotes + trebleUpperLedgerNotes;
        appendWithClef(baseT, 'T');


        // m_notePool.append(trebleClefNotes + trebleLowerLedgerNotes + trebleUpperLedgerNotes);

        if (trebleSharps) {
            QStringList sharpsT;
            for (const QString& note : baseT) {
                if (note.length() >= 2) {
                    sharpsT.append(note.left(1) + "#" + note.mid(1));
                }
            }
            appendWithClef(sharpsT, 'T');
        }
        if (trebleFlats) {
            QStringList flatsT;
            for (const QString& note : baseT) {
                if (note.length() >= 2) {
                    flatsT.append(note.left(1) + "b" + note.mid(1));
                }
            }
            appendWithClef(flatsT, 'T');
        }
    }
    if (usingBassClef)
    {
        QStringList bassClefNotes;
        QStringList bassUpperLedgerNotes;
        QStringList bassLowerLedgerNotes;
        QStringList sharpNotes;
        QStringList flatNotes;

        // Main staff notes
        if (bassClef)
            bassClefNotes = {"G2","A2","B2","C3","D3","E3","F3","G3","A3"};
        else
            bassClefNotes.clear();

        // LOWER ledger notes (below staff) – in ASCENDING PITCH ORDER
        if (bassLowerLedger)
            bassLowerLedgerNotes = {"C2","D2","E2","F2"};
        else
            bassLowerLedgerNotes.clear();

        // UPPER ledger notes (above staff)
        if (bassUpperLedger)
            bassUpperLedgerNotes = {"B3","C4","D4","E4","F4","G4"};
        else
            bassUpperLedgerNotes.clear();

        // IMPORTANT: lower → staff → upper (ascending overall)
        QStringList baseB = bassLowerLedgerNotes + bassClefNotes + bassUpperLedgerNotes;
        appendWithClef(baseB, 'B');

        // If you want sharps/flats active for bass too:
        if (bassSharps) {
            QStringList sharpsB;
            for (const QString& note : baseB) {
                if (note.length() >= 2) {
                    sharpsB.append(note.left(1) + "#" + note.mid(1));
                }
            }
            appendWithClef(sharpsB, 'B');
        }
        if (bassFlats) {
            QStringList flatsB;
            for (const QString& note : baseB) {
                if (note.length() >= 2) {
                    flatsB.append(note.left(1) + "b" + note.mid(1));
                }
            }
            appendWithClef(flatsB, 'B');
        }
    }
        qDebug() << m_notePool;
        emit notePoolChanged();
}

QStringList NoteSelector::notePool() { return m_notePool; }

void NoteSelector::nextNote()
{
    if (m_notePool.isEmpty())
        return;

    QString newNote;
    int pickedIndex = -1;
    int guard = 0;

    do {
        int index = QRandomGenerator::global()->bounded(m_notePool.size());
        newNote = m_notePool.at(index);
        pickedIndex = index;
        guard++;
        if (guard > 1000) break; // safety if pool is over-filtered
    } while (newNote == m_currentNote
             || (m_blockUpper && isUpperLedgerNote(newNote))
             || (m_blockLower && isLowerLedgerNote(newNote)));

    m_currentNote = newNote;
    emit currentNoteChanged();

    // which clef did THIS instance of the note come from?
    if (pickedIndex >= 0 && pickedIndex < m_poolClef.size()) {
        m_whichClef = (m_poolClef.at(pickedIndex) == 'T') ? QStringLiteral("treble") : QStringLiteral("bass");
        emit whichClefChanged();
    }

    m_isUpperLedger = isUpperLedgerNote(m_currentNote);
    emit isUpperLedgerChanged();

    qDebug() << "NEXT NOTE --- " << m_currentNote
             << "clef:" << m_whichClef
             << (m_blockUpper ? "[blockUpper]" : "")
             << (m_blockLower ? "[blockLower]" : "");
}

QString NoteSelector::currentNote() const { return m_currentNote; }

bool NoteSelector::isUpperLedger() { return m_isUpperLedger; }

QString NoteSelector::whichClef() { return m_whichClef; }
