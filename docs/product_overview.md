## The Problem

**Manual LLM workflow is broken:**

- Copy text → paste into ChatGPT → copy response → paste back = flow disruption
- Voice dictation creates messy, ungrammatical notes that need cleanup
- Can't send sensitive documents (journals, work notes) to public AI services
- No way to batch-clean accumulated rough drafts

## The Solution

A simple macOS utility that refines highlighted text using your local LLM - keeping everything private while automating the cleanup process.

## Key Features

### ⌨️ Instant Text Cleanup

- Highlight any text, press `Cmd+Shift+R`
- Refined version appears below with `-Refined Version--` header
- Works in any app: Obsidian, Apple Notes, browsers, etc.
- Original text stays untouched

### 🗂️ Batch Processing

- Drop rough drafts in a "Draft" folder
- Utility automatically cleans them up daily
- Processed files move to "Processed" folder
- Perfect for cleaning up week's worth of voice notes

### 🔒 Completely Private

- Uses local Ollama LLM (runs on your Mac)
- No internet required, no data sent anywhere
- Works great on M3 MacBook Air with recommended models

## How to Use

### Setup (5 minutes)

1. Download and install the app
2. Install Ollama: `brew install ollama`
3. Download a model: `ollama pull llama3.1:8b`
4. Set your folders in app settings

### Daily Usage

- **Manual:** Highlight text → `Cmd+Shift+R` → done
- **Batch:** Drop notes in Draft folder → check Processed folder next day

## Download & Installation

**Requirements:**

- macOS 12.0+
- 8GB+ RAM
- Ollama installed

**Installation:**

1. Download `.dmg` from GitHub releases
2. Drag to Applications folder
3. Follow setup wizard

**GitHub:** `github.com/[username]/llm-text-refiner`

## Perfect For

- Note-takers who use voice dictation
- Privacy-conscious users with sensitive documents
- Anyone tired of copy-pasting to ChatGPT for text cleanup
- Obsidian/Notion users who accumulate rough drafts

---

*Open source project built for personal use, shared with the community.