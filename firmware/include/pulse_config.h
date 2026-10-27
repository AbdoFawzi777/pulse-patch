#pragma once
// ============================================================
// PulsePatch Lite — Centralized Tunable Configuration
// All hardware-facing tunables are defined here with comments.
// HARDWARE STATUS: Not yet tested on physical breadboard.
// ============================================================

// --- I2C Bus ---
#define PULSE_I2C_SDA        4      // GPIO4 — SDA
#define PULSE_I2C_SCL        5      // GPIO5 — SCL
// IMPORTANT: MAX30102 runs at 3.3 V only. Do NOT supply 5 V.
#define MAX30102_I2C_ADDR    0x57   // 7-bit address per datasheet

// --- Sampling ---
#define SAMPLE_RATE_HZ       100    // MAX30102 sample rate (samples/s)
#define LED_CURRENT_MA       6      // IR + Red LED current (mA)
#define PULSE_WIDTH_US       411    // Pulse width (µs) — affects ADC resolution
#define ADC_RANGE            4096   // 18-bit ADC full-scale

// --- Signal Filtering ---
#define FILTER_WINDOW        5      // Moving-median window (samples); must be odd
#define DC_REMOVAL_ALPHA     0.95f  // High-pass IIR alpha (DC blocker)

// --- BPM Gating ---
#define BPM_MIN              40     // Below this -> invalid reading
#define BPM_MAX              200    // Above this -> invalid reading
#define RATE_JUMP_MAX        30     // Max BPM change per sample before clamp

// --- Signal Quality Index (SQI) ---
#define SQI_THRESHOLD        60     // Minimum SQI to accept a sample (0–100)

// --- BLE Packet ---
#define BLE_PROTOCOL_VERSION 1
#define BLE_PACKET_BYTES     12

// --- Serial Debug ---
#define SERIAL_BAUD_RATE     115200
