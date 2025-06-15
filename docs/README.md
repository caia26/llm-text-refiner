# LLM Text Refiner

A privacy-focused macOS utility that refines text using local LLM processing. Perfect for cleaning up voice dictation notes, rough drafts, and any text that needs polishing - all while keeping your data completely private.

## Overview

LLM Text Refiner is a native macOS application that leverages local Ollama LLM models to refine and improve text. It offers both instant text refinement through keyboard shortcuts and batch processing capabilities, making it ideal for note-takers, writers, and privacy-conscious users.

## Features

- **Instant Text Refinement**

  - Highlight text and press `Cmd+Shift+R` in any app
  - Refined version appears below with clear formatting
  - Works across macOS apps (Obsidian, Apple Notes, browsers, etc.)
  - Preserves original text

- **Batch Processing**

  - Drop files in a designated "Draft" folder
  - Automatic daily processing
  - Processed files moved to "Processed" folder
  - Ideal for cleaning up accumulated voice notes

- **Privacy-First**
  - Uses local Ollama LLM (runs on your Mac)
  - No internet connection required
  - No data leaves your device
  - Compatible with M-series Macs

## Requirements

- macOS 12.0 or later
- 8GB RAM minimum
- [Ollama](https://ollama.ai) installed
- Recommended: M-series Mac for optimal performance

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/[username]/llm-text-refiner/releases)
2. Drag to Applications folder
3. Install Ollama:
   ```bash
   brew install ollama
   ```
4. Download recommended model:
   ```bash
   ollama pull llama3.1:8b
   ```
5. Launch LLM Text Refiner and complete setup wizard

## Usage

### Manual Mode

1. Highlight text in any app
2. Press `Cmd+Shift+R`
3. Refined text appears below original

### Batch Mode

1. Configure Draft and Processed folders in app settings
2. Drop files in Draft folder
3. Check Processed folder for refined versions

## Development Setup

### Prerequisites

- Xcode 14.0+
- Swift 5.7+
- SwiftUI
- Ollama running locally

### Building

1. Clone the repository:
   ```bash
   git clone https://github.com/[username]/llm-text-refiner.git
   ```
2. Open `LLMTextRefiner.xcodeproj`
3. Build and run

### Architecture

- SwiftUI-based UI
- Local Ollama API integration
- File system monitoring for batch processing
- Global keyboard shortcut handling

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

Copyright (c) 2024 LLM Text Refiner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

_Built with ❤️ for the privacy-conscious community_
