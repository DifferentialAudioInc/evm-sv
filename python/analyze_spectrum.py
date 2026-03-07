#!/usr/bin/env python3
"""
EVM Stream Analyzer
Performs FFT and signal analysis on captured data
"""

import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
from scipy import signal
import argparse
import os

def read_capture_file(filename):
    """Read captured data file"""
    data = []
    metadata = {}
    
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('#'):
                # Parse metadata
                if ':' in line:
                    parts = line[1:].split(':', 1)
                    if len(parts) == 2:
                        key = parts[0].strip()
                        value = parts[1].strip()
                        metadata[key] = value
                continue
            if not line:
                continue
            
            # Parse data line
            parts = line.split(',')
            if len(parts) >= 2:
                try:
                    time_val = float(parts[0])
                    samples = [float(p) for p in parts[1:]]
                    data.append([time_val] + samples)
                except ValueError:
                    continue
    
    return np.array(data), metadata

def compute_fft(samples, sample_rate, window='blackmanharris'):
    """Compute FFT with windowing"""
    N = len(samples)
    
    # Apply window
    if window and N > 0:
        try:
            w = signal.get_window(window, N)
            samples_windowed = samples * w
            coherent_gain = np.mean(w)
        except:
            samples_windowed = samples
            coherent_gain = 1.0
    else:
        samples_windowed = samples
        coherent_gain = 1.0
    
    # Compute FFT
    fft_result = np.fft.fft(samples_windowed)
    freq = np.fft.fftfreq(N, 1/sample_rate)
    
    # Power spectrum (dBFS)
    # Account for coherent gain and convert to dBFS
    power = 20 * np.log10(np.abs(fft_result) / (N * coherent_gain) + 1e-12)
    
    return freq[:N//2], power[:N//2]

def compute_metrics(freq, power, signal_freq, num_harmonics=5):
    """Compute SNR, THD, SFDR, ENOB"""
    if len(freq) == 0 or len(power) == 0:
        return {'snr': 0, 'thd': 0, 'sfdr': 0, 'enob': 0, 'signal_power': -200}
    
    # Find signal bin
    signal_bin = np.argmin(np.abs(freq - signal_freq))
    signal_power = power[signal_bin]
    
    # Find harmonics
    harmonics = []
    for n in range(2, num_harmonics+1):
        harm_freq = signal_freq * n
        if harm_freq < freq[-1]:
            harm_bin = np.argmin(np.abs(freq - harm_freq))
            harmonics.append(power[harm_bin])
    
    # SFDR (Spurious-Free Dynamic Range)
    spurious = np.copy(power)
    mask_width = max(5, int(len(freq) * 0.001))  # Adaptive mask width
    spurious[max(0, signal_bin-mask_width):min(len(spurious), signal_bin+mask_width)] = -200
    sfdr = signal_power - np.max(spurious) if len(spurious) > 0 else 0
    
    # THD (Total Harmonic Distortion)
    if len(harmonics) > 0:
        thd_power_lin = 10 ** (np.array(harmonics) / 10)
        thd = 10 * np.log10(np.sum(thd_power_lin) + 1e-12)
    else:
        thd = -200
    
    # SNR (Signal-to-Noise Ratio)
    noise_power = 10 ** (power / 10)
    noise_power[max(0, signal_bin-mask_width):min(len(noise_power), signal_bin+mask_width)] = 0
    snr = signal_power - 10 * np.log10(np.sum(noise_power) + 1e-12)
    
    # ENOB (Effective Number of Bits)
    enob = (snr - 1.76) / 6.02
    
    return {
        'snr': snr,
        'thd': thd,
        'sfdr': sfdr,
        'enob': enob,
        'signal_power': signal_power
    }

def main():
    parser = argparse.ArgumentParser(description='Analyze captured streaming data')
    parser.add_argument('input', help='Captured data file')
    parser.add_argument('--fs', type=float, default=100e6, help='Sample rate in Hz')
    parser.add_argument('--freq', type=float, default=10e6, help='Signal frequency in Hz')
    parser.add_argument('--channel', type=int, default=0, help='Channel to analyze')
    parser.add_argument('--window', default='blackmanharris', help='FFT window type')
    parser.add_argument('--output', help='Output plot filename')
    args = parser.parse_args()
    
    # Read captured data
    print(f"Reading {args.input}...")
    data, metadata = read_capture_file(args.input)
    
    if len(data) == 0:
        print("ERROR: No data found in file")
        return 1
    
    # Extract requested channel
    if data.shape[1] <= args.channel + 1:
        print(f"ERROR: Channel {args.channel} not found (file has {data.shape[1]-1} channels)")
        return 1
    
    time = data[:, 0]
    samples = data[:, args.channel + 1]
    
    print(f"  Samples: {len(samples)}")
    print(f"  Duration: {time[-1]*1e6:.3f} µs")
    print(f"  Channel: {args.channel}")
    
    # Compute FFT
    freq, power = compute_fft(samples, args.fs, args.window)
    
    # Compute metrics
    metrics = compute_metrics(freq, power, args.freq)
    
    # Print results
    print(f"\n=== Analysis Results ===")
    print(f"Signal Power: {metrics['signal_power']:.2f} dBFS")
    print(f"SNR:   {metrics['snr']:.2f} dB")
    print(f"THD:   {metrics['thd']:.2f} dBc")
    print(f"SFDR:  {metrics['sfdr']:.2f} dBc")
    print(f"ENOB:  {metrics['enob']:.2f} bits")
    
    # Create plots
    output_file = args.output if args.output else args.input.replace('.txt', '_analysis.png')
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
    
    # Time domain
    time_us = time * 1e6
    ax1.plot(time_us, samples, linewidth=0.5)
    ax1.set_xlabel('Time (µs)')
    ax1.set_ylabel('Amplitude (normalized)')
    ax1.set_title(f'Time Domain - Channel {args.channel}')
    ax1.grid(True, alpha=0.3)
    ax1.set_xlim([time_us[0], min(time_us[-1], 10)])  # Show first 10µs
    
    # Frequency domain
    freq_mhz = freq / 1e6
    ax2.plot(freq_mhz, power, linewidth=0.5)
    ax2.set_xlabel('Frequency (MHz)')
    ax2.set_ylabel('Power (dBFS)')
    ax2.set_title(f'Frequency Domain - SNR={metrics["snr"]:.1f}dB, SFDR={metrics["sfdr"]:.1f}dB, ENOB={metrics["enob"]:.1f}bits')
    ax2.set_xlim([0, args.fs/2e6])
    ax2.set_ylim([max(power.min(), -140), power.max() + 10])
    ax2.grid(True, alpha=0.3)
    
    # Mark signal frequency
    ax2.axvline(args.freq/1e6, color='r', linestyle='--', alpha=0.5, label=f'Signal ({args.freq/1e6:.1f} MHz)')
    ax2.legend()
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=150)
    print(f"\n✓ Plot saved to {output_file}")
    
    # Save metrics to text file
    metrics_file = output_file.replace('.png', '_metrics.txt')
    with open(metrics_file, 'w') as f:
        f.write(f"=== Analysis Results ===\n")
        f.write(f"Input File: {args.input}\n")
        f.write(f"Sample Rate: {args.fs/1e6:.3f} MHz\n")
        f.write(f"Signal Frequency: {args.freq/1e6:.3f} MHz\n")
        f.write(f"Channel: {args.channel}\n")
        f.write(f"Samples: {len(samples)}\n")
        f.write(f"\nMetrics:\n")
        f.write(f"  Signal Power: {metrics['signal_power']:.2f} dBFS\n")
        f.write(f"  SNR:  {metrics['snr']:.2f} dB\n")
        f.write(f"  THD:  {metrics['thd']:.2f} dBc\n")
        f.write(f"  SFDR: {metrics['sfdr']:.2f} dBc\n")
        f.write(f"  ENOB: {metrics['enob']:.2f} bits\n")
    
    print(f"✓ Metrics saved to {metrics_file}")
    
    return 0

if __name__ == '__main__':
    exit(main())
