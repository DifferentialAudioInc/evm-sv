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
    
    # Buffered streaming support
    parser.add_argument('--start', type=int, default=0, help='Start sample index (for buffered streaming)')
    parser.add_argument('--count', type=int, help='Number of samples to generate (overrides duration)')
    
    args = parser.parse_args()
    
    # Determine number of samples
    if args.count:
        num_samples = args.count
        duration_actual = num_samples / args.fs
    else:
        duration_actual = args.duration
        num_samples = int(duration_actual * args.fs)
    
    # Calculate starting time based on start sample (for phase continuity)
    start_time = args.start / args.fs
    
    # Generate waveform based on type (starting from start_time for phase continuity)
    if args.type == 'sine':
        phase_rad = np.deg2rad(args.phase)
        # Generate from start_time to maintain phase continuity
        t = np.arange(num_samples) / args.fs + start_time
        samples = args.amp * np.sin(2 * np.pi * args.freq * t + phase_rad)
    elif args.type == 'chirp':
        end_freq = args.freq2 if args.freq2 else args.freq * 2
        # For chirp, we need to account for starting position
        t = np.arange(num_samples) / args.fs + start_time
        # Use linear chirp formula with offset
        samples = args.amp * np.sin(2 * np.pi * (args.freq * t + (end_freq - args.freq) * t**2 / (2 * duration_actual)))
    elif args.type == 'noise':
        # Noise is random, seed based on start sample for reproducibility
        np.random.seed(args.start)
        samples = generate_noise(args.fs, duration_actual, args.amp)
    elif args.type == 'multi_tone':
        if args.tones:
            freqs = [float(f) for f in args.tones.split(',')]
        else:
            freqs = [args.freq, args.freq*2, args.freq*3]
        # Generate multi-tone with phase continuity
        t = np.arange(num_samples) / args.fs + start_time
        samples = np.zeros(len(t))
        for freq in freqs:
            samples += np.sin(2 * np.pi * freq * t)
        samples = args.amp * samples / len(freqs)
    
    # Create output directory if needed
    output_dir = os.path.dirname(args.output) if os.path.dirname(args.output) else '.'
    if output_dir and output_dir != '.':
        os.makedirs(output_dir, exist_ok=True)
    
    # Write to file
    with open(args.output, 'w') as f:
        f.write(f"# EVM Stimulus File\n")
        f.write(f"# Type: {args.type}\n")
        f.write(f"# Frequency: {args.freq/1e6:.3f} MHz\n")
        f.write(f"# Sample Rate: {args.fs/1e6:.3f} MHz\n")
        f.write(f"# Start Sample: {args.start}\n")
        f.write(f"# Samples: {len(samples)}\n")
        f.write(f"# Channels: {args.channels}\n")
        f.write(f"#\n")
        f.write(f"# Format: time")
        for ch in range(args.channels):
            f.write(f", ch{ch}")
        f.write(f"\n")
        
        for i, sample in enumerate(samples):
            # Absolute time includes start offset
            time = (args.start + i) / args.fs
            f.write(f"{time:.9f}")
            for ch in range(args.channels):
                # Apply phase shift per channel
                phase_shift = ch * (90.0 / args.channels) if args.channels > 1 else 0
                if args.type == 'sine':
                    # Recalculate with phase shift for this channel
                    ch_sample = args.amp * np.sin(2 * np.pi * args.freq * time + 
                                                   np.deg2rad(args.phase + phase_shift))
                else:
                    ch_sample = sample  # Same for all channels
                f.write(f", {ch_sample:.6f}")
            f.write(f"\n")
    
    # Print summary
    if args.start > 0:
        print(f"✓ Generated buffer: samples {args.start} to {args.start + len(samples) - 1}")
    else:
        print(f"✓ Generated {len(samples)} samples to {args.output}")
    print(f"  Type: {args.type}")
    print(f"  Frequency: {args.freq/1e6:.3f} MHz")
    print(f"  Sample Rate: {args.fs/1e6:.3f} MHz")
    if args.count:
        print(f"  Samples: {args.count} (buffered mode)")
    else:
        print(f"  Duration: {args.duration*1e6:.3f} µs")
    print(f"  Channels: {args.channels}")

if __name__ == '__main__':
    main()
