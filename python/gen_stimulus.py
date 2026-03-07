#!/usr/bin/env python3
"""
EVM Stream Stimulus Generator
Generates waveform stimulus files for streaming agents
"""

import numpy as np
import argparse
import os

def generate_sine(freq_hz, sample_rate_hz, duration_sec, amplitude=1.0, phase=0.0):
    """Generate sine wave"""
    t = np.arange(0, duration_sec, 1/sample_rate_hz)
    return amplitude * np.sin(2 * np.pi * freq_hz * t + phase)

def generate_chirp(start_freq, end_freq, sample_rate_hz, duration_sec, amplitude=1.0):
    """Generate chirp (swept frequency)"""
    from scipy.signal import chirp as scipy_chirp
    t = np.arange(0, duration_sec, 1/sample_rate_hz)
    return amplitude * scipy_chirp(t, start_freq, duration_sec, end_freq, method='linear')

def generate_noise(sample_rate_hz, duration_sec, amplitude=1.0):
    """Generate white noise"""
    num_samples = int(duration_sec * sample_rate_hz)
    return amplitude * (2 * np.random.random(num_samples) - 1)

def generate_multi_tone(freqs, sample_rate_hz, duration_sec, amplitude=1.0):
    """Generate multiple tones"""
    t = np.arange(0, duration_sec, 1/sample_rate_hz)
    signal = np.zeros(len(t))
    for freq in freqs:
        signal += np.sin(2 * np.pi * freq * t)
    return amplitude * signal / len(freqs)

def main():
    parser = argparse.ArgumentParser(description='Generate stimulus waveforms for EVM streaming agents')
    parser.add_argument('--type', default='sine', choices=['sine', 'chirp', 'noise', 'multi_tone'],
                        help='Waveform type')
    parser.add_argument('--freq', type=float, default=10e6, help='Frequency in Hz')
    parser.add_argument('--freq2', type=float, help='End frequency for chirp (Hz)')
    parser.add_argument('--fs', type=float, default=100e6, help='Sample rate in Hz')
    parser.add_argument('--duration', type=float, default=100e-6, help='Duration in seconds')
    parser.add_argument('--amp', type=float, default=1.0, help='Amplitude (0.0 to 1.0)')
    parser.add_argument('--phase', type=float, default=0.0, help='Phase in degrees')
    parser.add_argument('--channels', type=int, default=1, help='Number of channels')
    parser.add_argument('--output', default='stimulus.txt', help='Output file')
    parser.add_argument('--tones', type=str, help='Comma-separated frequencies for multi_tone')
    args = parser.parse_args()
    
    # Generate waveform based on type
    if args.type == 'sine':
        phase_rad = np.deg2rad(args.phase)
        samples = generate_sine(args.freq, args.fs, args.duration, args.amp, phase_rad)
    elif args.type == 'chirp':
        end_freq = args.freq2 if args.freq2 else args.freq * 2
        samples = generate_chirp(args.freq, end_freq, args.fs, args.duration, args.amp)
    elif args.type == 'noise':
        samples = generate_noise(args.fs, args.duration, args.amp)
    elif args.type == 'multi_tone':
        if args.tones:
            freqs = [float(f) for f in args.tones.split(',')]
        else:
            freqs = [args.freq, args.freq*2, args.freq*3]
        samples = generate_multi_tone(freqs, args.fs, args.duration, args.amp)
    
    # Create output directory if needed
    os.makedirs(os.path.dirname(args.output) if os.path.dirname(args.output) else '.', exist_ok=True)
    
    # Write to file
    with open(args.output, 'w') as f:
        f.write(f"# EVM Stimulus File\n")
        f.write(f"# Type: {args.type}\n")
        f.write(f"# Frequency: {args.freq/1e6:.3f} MHz\n")
        f.write(f"# Sample Rate: {args.fs/1e6:.3f} MHz\n")
        f.write(f"# Duration: {args.duration*1e6:.3f} µs\n")
        f.write(f"# Samples: {len(samples)}\n")
        f.write(f"# Channels: {args.channels}\n")
        f.write(f"#\n")
        f.write(f"# Format: time")
        for ch in range(args.channels):
            f.write(f", ch{ch}")
        f.write(f"\n")
        
        for i, sample in enumerate(samples):
            time = i / args.fs
            f.write(f"{time:.9f}")
            for ch in range(args.channels):
                # Apply phase shift per channel
                phase_shift = ch * (90.0 / args.channels) if args.channels > 1 else 0
                if args.type == 'sine':
                    ch_sample = args.amp * np.sin(2 * np.pi * args.freq * time + 
                                                   np.deg2rad(args.phase + phase_shift))
                else:
                    ch_sample = sample  # Same for all channels
                f.write(f", {ch_sample:.6f}")
            f.write(f"\n")
    
    print(f"✓ Generated {len(samples)} samples to {args.output}")
    print(f"  Type: {args.type}")
    print(f"  Frequency: {args.freq/1e6:.3f} MHz")
    print(f"  Sample Rate: {args.fs/1e6:.3f} MHz")
    print(f"  Duration: {args.duration*1e6:.3f} µs")
    print(f"  Channels: {args.channels}")

if __name__ == '__main__':
    main()
