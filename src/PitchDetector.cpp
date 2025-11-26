#include "PitchDetector.h"
#include <QDebug>
#include <cmath>
#include <algorithm>

PitchDetector::PitchDetector(int sampleRate, int hopSize,int winSize, QObject* parent)
                            : QObject(parent), sampleRate(sampleRate),hopSize(hopSize),winSize(winSize)
{
    pitchHistory.clear();
}

// ==========================
// Dual Pitch Detection Entry
// ==========================
float PitchDetector::detectPitchFast(const float* input) {
    float conf = 0.0f;
    float pitch = runYIN(input, 1024, conf);
    lastFastConfidence = conf;
    lastConfidence = conf;
    return pitch;
}

float PitchDetector::detectPitchSlow(const float* input) {
    float conf = 0.0f;
    float pitch = runYIN(input, 4096, conf);
    lastSlowConfidence = conf;
    lastConfidence = conf;  // add this
    return pitch;
}


// ==========================
// Core YIN Implementation
// ==========================
float PitchDetector::runYIN(const float* input, int winSize, float& confidence)
{
    int minLag = std::max(1, static_cast<int>(sampleRate / maxFrequency));
    int maxLag = std::min(winSize / 2, static_cast<int>(sampleRate / minFrequency));

    std::vector<float> diff(winSize, 0.0f);
    std::vector<float> cmnd(winSize, 0.0f);

    // Step 1: Difference function
    for (int tau = minLag; tau < maxLag; ++tau) {
        float sum = 0.0f;
        for (int i = 0; i < winSize - tau; ++i) {
            float delta = input[i] - input[i + tau];
            sum += delta * delta;
        }
        diff[tau] = sum;
    }

    // Step 2: Cumulative mean normalized difference (CMND)
    cmnd[0] = 1.0f;
    float runningSum = 0.0f;
    for (int tau = 1; tau < maxLag; ++tau) {
        runningSum += diff[tau];
        cmnd[tau] = diff[tau] * tau / runningSum;
    }

    if (winSize >= 4096 && debugEnabled) {
        float minCmnd = 1.0f;
        int minIndex = -1;
        for (int tau = minLag; tau < maxLag; ++tau) {
            if (cmnd[tau] < minCmnd) {
                minCmnd = cmnd[tau];
                minIndex = tau;
            }
        }
        qDebug() << "[DEBUG] SlowYIN: best cmnd =" << minCmnd
                 << "at tau =" << minIndex
                 << "freq ~" << (sampleRate / static_cast<float>(minIndex));
    }


    // Step 3: Adaptive threshold — looser for bigger windows
    float baseThreshold = (winSize >= 4096) ? 0.30f : 0.15f;
#ifdef Q_OS_ANDROID
    baseThreshold += 0.15f;
#endif

    int tauEstimate = -1;
    for (int tau = minLag + 2; tau < maxLag; ++tau) {
        if (cmnd[tau] < baseThreshold) {
            // climb to local minimum
            while (tau + 1 < maxLag && cmnd[tau + 1] < cmnd[tau])
                tau++;
            tauEstimate = tau;
            break;
        }
    }

    if (tauEstimate == -1) {
        confidence = 0.0f;
        return -1.0f;
    }

    // Step 4: Parabolic interpolation for sub-sample accuracy
    int x0 = (tauEstimate < 1) ? tauEstimate : tauEstimate - 1;
    int x2 = (tauEstimate + 1 < maxLag) ? tauEstimate + 1 : tauEstimate;
    float betterTau = tauEstimate;
    if (x0 != tauEstimate && x2 != tauEstimate) {
        float s0 = cmnd[x0];
        float s1 = cmnd[tauEstimate];
        float s2 = cmnd[x2];
        betterTau = tauEstimate + (s2 - s0) / (2.0f * (2.0f * s1 - s2 - s0));
    }

    float pitch = static_cast<float>(sampleRate) / betterTau;
    confidence = 1.0f - cmnd[tauEstimate];

    return pitch;
}


// ==========================
// Helpers
// ==========================
void PitchDetector::setSampleRate(int rate) { sampleRate = rate; }
void PitchDetector::setFrequencyRange(float min, float max) {
    minFrequency = min;
    maxFrequency = max;
}
void PitchDetector::setSmoothingWindow(int window) { smoothingWindow = window; }
void PitchDetector::setStabilityThreshold(float threshold, int frames) {
    pitchThreshold = threshold;
    requiredStableFrames = frames;
}

QString PitchDetector::frequencyToNoteName(float frequency) const
{
    if (frequency <= 0.0f)
        return "-";

    int midiNote = static_cast<int>(std::round(69 + 12 * log2(frequency / 440.0f)));
    if (midiNote < 36 || midiNote > 89) // C2–F6
        return "?";

    static QStringList noteNames =
        {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    QString note = noteNames[midiNote % 12];
    int octave = (midiNote / 12) - 1;

    return note + QString::number(octave);
}
