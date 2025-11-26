#ifndef MICROPHONEINPUT_H
#define MICROPHONEINPUT_H


#include <QAudioSink>
#include <QMediaDevices>
#include <QAudioSource>
#include <QIODevice>
#include <QDebug>
#include <QByteArray>
#include <QBuffer>
#include <QAudioFormat>
#include <algorithm>
#include <QtConcurrent/QtConcurrent>
#include "PitchDetector.h"
#include <QElapsedTimer>
#include <cmath>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

class MicrophoneInput : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString pitchDetected READ pitchDetected NOTIFY pitchDetectedChanged)


public:
    MicrophoneInput(QObject* parent = nullptr) : QObject(parent), pitchDetector(44100)
    {
        globalTimer.start();
    }

    ~MicrophoneInput()
    {
        if(audioSource)
        {
            audioSource->stop();
        }
    }

    void requestMicrophonePermission()
    {
        QMicrophonePermission permission;
        auto perm = QCoreApplication::instance()->checkPermission(permission);
        if (perm == Qt::PermissionStatus::Granted)
        {
            qDebug() << "Microhone permissions GRANTED";
            setupAudio();
            emit microphoneReady();
        }
        else
        {
            QCoreApplication::instance()->requestPermission(permission, [this](const QPermission &p) {
                if (p.status() == Qt::PermissionStatus::Granted) {
                    setupAudio();
                    emit microphoneReady();
                } else {
                    qWarning() << "Microphone permission denied.";
                }
            });
        }
    }

    void setupAudio()
    {
        QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();

        QAudioFormat format;
        format.setSampleRate(44100);
        format.setChannelCount(1);
        format.setSampleFormat(QAudioFormat::Int16);

        if(!inputDevice.isFormatSupported(format))
        {
            qWarning() << "Format not supported, using preferred format.";
            format = inputDevice.preferredFormat();
            if (format.channelCount() != 2)
            {
                format.setChannelCount(1);
                //qWarning() << "Warning: Audio device is not mono. This may break pitch detection.";
            }
            qDebug() << "Format is now == " << format;
        }
        m_format = format;
        qDebug() << "Audio Format" << format;
        hopSize = pitchDetector.getHopSize();
        pitchDetector.setSampleRate(format.sampleRate());
        pitchDetector.setFrequencyRange(65.41f, 1396.91f);


        // constructor
        audioSource = new QAudioSource(inputDevice, format, this);
        audioDevice = audioSource->start();

        qDebug() << "[AUDIO] Final format:"
                 << "rate=" << m_format.sampleRate()
                 << "channels=" << m_format.channelCount()
                 << "bytesPerFrame=" << m_format.bytesPerFrame();
        qDebug() << "[PITCH] winSize=" << pitchDetector.getWinSize()
                 << "hopSize=" << pitchDetector.getHopSize();

        connect(audioDevice, &QIODevice::readyRead, this, &MicrophoneInput::onDataReady);
    }

    // restart audio to reset mic usage on mic hanging
    void restartAudioInput()
    {
        if (audioSource) {
            audioSource->stop();
            audioSource->deleteLater();
            audioSource = nullptr;
        }
        QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();

        QAudioFormat format;
        format.setSampleRate(44100);
        format.setChannelCount(1);
        format.setSampleFormat(QAudioFormat::Int16);

        if(!inputDevice.isFormatSupported(format))
        {
            qWarning() << "Format not supported, using preferred format.";
            format = inputDevice.preferredFormat();
            if (format.channelCount() != 2)
            {
                format.setChannelCount(1);
                //qWarning() << "Warning: Audio device is not mono. This may break pitch detection.";
            }
            qDebug() << "Format is now == " << format;
        }

        m_format = format;
        qDebug() << "Audio Format" << format;
        hopSize = pitchDetector.getHopSize();
        pitchDetector.setSampleRate(format.sampleRate());  // Add this line


        // constructor
        audioSource = new QAudioSource(inputDevice, format, this);
        audioDevice = audioSource->start();

        connect(audioDevice, &QIODevice::readyRead, this, &MicrophoneInput::onDataReady);

        buffer.clear();  // Flush any leftover junk
        emptyReadCounter = 0;

        qWarning() << "[MIC] Audio input restarted successfully";
    }


    QString pitchDetected()
    {
        qDebug() << "PITCH DETECTED: " << m_pitchDetected;
        return m_pitchDetected;
    }

    // tester function (keystroke)
    Q_INVOKABLE void pitchDetectedTester(QString pitch)
    {
        qDebug() << "[TESTER]:: Pitch Detected = " << m_pitchDetected;
        m_pitchDetected = pitch;
        emit pitchDetectedChanged();
    }

    // Check Format of device
    void logAudioFormat(const QAudioFormat &format)
    {
        qDebug() << "Audio Format:";
        qDebug() << "  Sample Rate:" << format.sampleRate();
        qDebug() << "  Channel Count:" << format.channelCount();

        QString formatName;
        switch (format.sampleFormat())
        {
        case QAudioFormat::UInt8: formatName = "Unsigned 8-bit"; break;
        case QAudioFormat::Int16: formatName = "Signed 16-bit"; break;
        case QAudioFormat::Int32: formatName = "Signed 32-bit"; break;
        case QAudioFormat::Float: formatName = "Float"; break;
        default: formatName = "Unknown"; break;
        }
        qDebug() << "  Sample Format:" << formatName;
        qDebug() << "  Bytes per Frame:" << format.bytesPerFrame();
    }

signals:
    void pitchDetectedChanged();
    void micLevelChanged(float level);

    void microphoneReady();

private slots:

    // process data in buffer
    void onDataReady()
    {
        QElapsedTimer dataReadyTimer;
        dataReadyTimer.start();

        QByteArray data = audioDevice->readAll();
        if (data.isEmpty())
        {
            emptyReadCounter++;
            qWarning() << "[MIC] Warning: readAll() returned 0 bytes";
            if (emptyReadCounter >= MAX_EMPTY_READS)
            {
                qWarning() << "[MIC] Too many empty reads. Restarting mic input...";
                restartAudioInput();
            }
            return;
        }
        emptyReadCounter = 0;

        const int channels = m_format.channelCount();
        const int winSize = pitchDetector.getWinSize();
        const int hop = pitchDetector.getHopSize();
        const int bytesPerSample = (m_format.sampleFormat() == QAudioFormat::Float)
                                       ? sizeof(float)
                                       : sizeof(int16_t);

        buffer.append(data);
        const int maxWin = 8192;
        while (buffer.size() >= maxWin * bytesPerSample * channels)
        {
            std::vector<float> monoBuffer(maxWin, 0.0f);

            if (m_format.sampleFormat() == QAudioFormat::Float)
            {
                const float* samples = reinterpret_cast<const float*>(buffer.constData());
                for (int i = 0; i < maxWin; ++i)
                {
                    float sum = 0.0f;
                    for (int ch = 0; ch < channels; ++ch)
                        sum += samples[i * channels + ch];
                    monoBuffer[i] = sum / channels;
                }
            }
            else if (m_format.sampleFormat() == QAudioFormat::Int16)
            {
                const int16_t* samples = reinterpret_cast<const int16_t*>(buffer.constData());
                for (int i = 0; i < maxWin; ++i)
                {
                    float sum = 0.0f;
                    for (int ch = 0; ch < channels; ++ch)
                        sum += samples[i * channels + ch] / 32768.0f;
                    monoBuffer[i] = sum / channels;
                }
            }



            // --- RMS calculation ---
            float sumSquares = 0.0f;
            float maxAmplitude = 0.0f;
            for (int i = 0; i < winSize; ++i)
            {
                sumSquares += monoBuffer[i] * monoBuffer[i];
                maxAmplitude = std::max(maxAmplitude, std::fabs(monoBuffer[i]));
            }
            float rms = std::sqrt(sumSquares / winSize);

            // Update mic level for UI feedback
            float clampedRMS = std::min(rms, 0.5f);
            float micLevel = std::clamp(clampedRMS * 2.0f, 0.0f, 1.0f);
            emit micLevelChanged(micLevel);

            // --- Gating: skip if too quiet ---
            if (rms < 0.0015f)
            {
                buffer.remove(0, hop * bytesPerSample * channels);
                continue;
            }


            // --- Detect pitch ---
            // --- Prepare two analysis windows ---
            // FAST: 1024 samples for mid/treble notes
            const int fastWin = 1024;
            std::vector<float> fastBuffer(fastWin);
            std::copy_n(monoBuffer.begin(), fastWin, fastBuffer.begin());

            // Apply Hann only to fastBuffer
            for (int i = 0; i < fastWin; ++i) {
                float hann = 0.5f * (1.0f - std::cos((2.0f * M_PI * i) / (fastWin - 1)));
                fastBuffer[i] *= hann;
            }

            // SLOW: 8192 samples for low bass notes
            const int slowWin = 4096;
            std::vector<float> slowBuffer(slowWin);
            std::copy_n(monoBuffer.begin(), slowWin, slowBuffer.begin());
            // No Hann here — keep raw low-frequency energy


            // --- Run fast-YIN first ---
            float fastPitch = pitchDetector.detectPitchFast(fastBuffer.data());
            float fastConf  = pitchDetector.getFastConfidence();

            // --- Run slow-YIN *only when needed* ---
            float slowPitch = -1.0f;
            float slowConf  = 0.0f;

            bool needSlow = (fastPitch <= 0.0f || fastConf < 0.25f);
            if (needSlow) {
                slowPitch = pitchDetector.detectPitchSlow(slowBuffer.data());
                slowConf  = pitchDetector.getSlowConfidence();
            }

            // --- Choose best pitch based on frequency and confidence ---
            float pitch = -1.0f;
            float confidence = 0.0f;

            // 1. FAST is primary for everything above 150 Hz
            if (fastPitch > 0 && fastConf > 0.3f && fastPitch >= 150.0f) {
                pitch = fastPitch;
                confidence = fastConf;
            }
            // 2. SLOW only for true bass
            else if (slowPitch > 0 && slowConf > 0.3f && slowPitch < 150.0f) {
                pitch = slowPitch;
                confidence = slowConf;
            }
            // 3. fallback: accept fast first
            else if (fastPitch > 0 && fastConf > 0.2f) {
                pitch = fastPitch;
                confidence = fastConf;
            }
            // 4. fallback slow:
            else if (slowPitch > 0 && slowConf > 0.2f) {
                pitch = slowPitch;
                confidence = slowConf;
            }

            // Map frequency to note name
            QString newPitch = pitchDetector.frequencyToNoteName(pitch);


            if (pitchDetector.getLastConfidence() < 0.4f)
            {
                buffer.remove(0, hop * bytesPerSample * channels);
                continue;
            }

            qint64 now = globalTimer.elapsed();

            // ----------------------
            // Attack suppression
            // ----------------------
            if (now < suppressUntilTime) {
                buffer.remove(0, hop * bytesPerSample * channels);
                continue;          // 💥 DO NOT UPDATE m_pitchDetected here
            }

            // ----------------------
            // Sticky debounce
            // ----------------------
            if (newPitch != "-" && newPitch == m_pitchDetected) {
                stableMatchCount++;
            } else {
                stableMatchCount = 1;
                m_pitchDetected = newPitch;    // <-- only update after suppression
            }

            // ----------------------
            // Emit only when stable
            // ----------------------
            if (stableMatchCount >= REQUIRED_STABLE_MATCHES &&
                newPitch != lastEmittedPitch)
            {
                lastGoodTime = now;
                suppressUntilTime = now + 160;     // NEW: larger tail window
                lastEmittedPitch = newPitch;
                emit pitchDetectedChanged();
            }

            buffer.remove(0, hop * bytesPerSample * channels);
        }

        //qDebug() << "Data Ready Timer:" << dataReadyTimer.elapsed() << "ms";
    }


private:

    QAudioSource* audioSource = nullptr;
    QIODevice* audioDevice = nullptr;
    QAudioFormat m_format;

    PitchDetector pitchDetector;
    QString m_pitchDetected;
    QByteArray buffer;
    int hopSize;

    // count empty buffers - 10 means mic hanging; reset mic
    int emptyReadCounter = 0;
    const int MAX_EMPTY_READS = 10;  // Threshold to trigger mic restart

    // STICKY DEBOUNCE FILTER
    QString lastEmittedPitch;
    int stableMatchCount = 0;
    const int REQUIRED_STABLE_MATCHES = 2; // adjust for latency vs accuracy


    qint64 lastGoodTime = 0;
    qint64 suppressUntilTime = 0;
    QElapsedTimer globalTimer;

};

#endif // MICROPHONEINPUT_H
