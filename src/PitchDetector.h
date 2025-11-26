#ifndef PITCHDETECTOR_H
#define PITCHDETECTOR_H

#include <QObject>
#include <vector>
#include <deque>
#include <QStringList>
#include <cmath>

class PitchDetector : public QObject
{
    Q_OBJECT

public:
    explicit PitchDetector(int sampleRate = 44100,
                           int hopSize = 1024,
                           int winSize = 2048,
                           QObject* parent = nullptr);

    // Config
    void setSampleRate(int rate);
    void setFrequencyRange(float min, float max);
    void setSmoothingWindow(int window);
    void setStabilityThreshold(float threshold, int requiredFrames);

    // Legacy-compatible: separate fast/slow detectors
    float detectPitchFast(const float* input);
    float detectPitchSlow(const float* input);

    // Unified dual-YIN detection (if you want to bypass MicrophoneInput)
    float detectPitch(const float* fastInput, const float* slowInput);
    float detectPitch(const qint16* input);

    // YIN implementation
    float runYIN(const float* input, int winSize, float& confidence);

    // Note name conversion
    QString frequencyToNoteName(float frequency) const;

    // --- Accessors expected by MicrophoneInput ---
    int getWinSize() const { return winSize; }
    int getHopSize() const { return hopSize; }
    float getFastConfidence() const { return lastFastConfidence; }
    float getSlowConfidence() const { return lastSlowConfidence; }
    float getLastConfidence() const { return lastConfidence; }

    // Debug toggle
    void setDebugEnabled(bool enabled) { debugEnabled = enabled; }

signals:
    void pitchUpdated(float pitch);

private:
    // Config
    int sampleRate;
    int hopSize;
    int winSize;

    float minFrequency = 65.41f;   // C2
    float maxFrequency = 1396.91f; // F6

    // Confidence tracking
    float lastConfidence      = 0.0f;
    float lastFastConfidence  = 0.0f;
    float lastSlowConfidence  = 0.0f;

    // Stability & smoothing
    std::deque<float> pitchHistory;
    int smoothingWindow = 3;
    float pitchThreshold = 0.25f;
    int requiredStableFrames = 2;
    float lastPitch = -1.0f;

    // Debug toggle
    bool debugEnabled = false;

    // Constants for clamping
    static constexpr float MIN_FREQUENCY = 65.41f;   // C2
    static constexpr float MAX_FREQUENCY = 1396.91f; // F6
};

#endif // PITCHDETECTOR_H
