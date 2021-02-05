#!/usr/bin/env python3
"""Install rust & cargo on a mac."""

# TODO(ebrown): Make something that works on mac & linux
# TODO(ebrown): Install a specific version of rust/cargo
# TODO(ebrown): Tweak khan startup scripts instead of rustup-init doing it

import subprocess

subprocess.run(['brew', 'install', 'rustup-init'], check=True)
subprocess.run(['rustup-init', '-y', '-t', 'wasm32-wasi', '--no-modify-path'],
               check=True)
