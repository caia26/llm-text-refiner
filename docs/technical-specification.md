## Product Overview

A macOS system-level utility that refines highlighted text using a locally hosted LLM (Ollama), designed for note-taking workflows with emphasis on data privacy and zero data loss.

**Primary Use Case:** Clean up grammatically incorrect notes and voice dictation errors in real-time and batch processing modes.

## Core Requirements

### Functional Requirements

**FR-1: Manual Text Refinement**

- User highlights text in any macOS application
- Keyboard shortcut triggers refinement process
- Refined text is pasted below original with header "--Refined Version--"
- Original text remains unchanged (zero-loss principle)

**FR-2: Batch Processing**

- Automated processing of markdown files in specified Obsidian folders
- Daily scheduling with user-configurable time
- Folder structure: Draft → Processed workflow
- In-place refinement with original + refined sections in same file

**FR-3: Local LLM Integration**

- Primary support for Ollama with OpenAI-compatible API
- Recommended models with hardware compatibility guidance
- Custom model selection capability

**FR-4: Error Handling & Reliability**

- Retry mechanism: 3 attempts total with 1-hour intervals
- Queue failed requests for retry
- Comprehensive error logging
- Simple undo functionality

## Technical Architecture

### System Components

**1. Core Application (macOS Native)**

- Swift/SwiftUI application
- Menu bar utility (no dock icon)
- Runs as background service
- Accessibility permissions required

**2. Text Capture Engine**

- Clipboard-based text capture
- Global keyboard shortcut registration
- Automatic clipboard restoration

**3. LLM Interface Module**

- HTTP client for Ollama API communication
- Request/response handling with timeouts
- Retry logic implementation

**4. File Processing Engine**

- File system monitoring for batch processing
- Markdown file parsing and manipulation
- Folder management and organization

**5. Scheduler Service**

- Configurable batch processing timing
- File modification timestamp checking
- Processing queue management

## Feature Specifications

### Manual Mode Operation

**Trigger:** User-configurable keyboard shortcut (default: Cmd+Shift+R)

**Workflow:**

1. User highlights text in any application
2. Presses keyboard shortcut
3. System copies highlighted text to clipboard
4. Sends text to local LLM with refinement prompt
5. Receives refined version
6. Pastes refined text below original with header
7. Restores original clipboard contents
8. **If file is in Draft folder:** Move file to Processed folder to prevent duplicate processing

**Output Format:**

```
[Original highlighted text remains unchanged]

--Refined Version--
[LLM-refined text appears here]

```

### Batch Processing Mode

**Target Directory Structure:**

```
[User-specified parent path]/
├── Draft/           # Input folder for unprocessed notes
├── Processed/       # Output folder for refined notes
└── .refinement_log  # Processing history and errors

```

**Processing Logic:**

- Scan Draft folder for .md files
- Skip files modified within last 2 hours (active editing protection)
- Skip files that already contain "--Refined Version--" headers (already processed manually)
- Process each file: add refined sections below original content
- Move processed files to Processed folder
- Log all operations and errors

**Scheduling:**

- Daily execution at user-configured time (default: 9:00 PM)
- Option to manually trigger batch processing
- Background processing with minimal system impact

### LLM Configuration

**Primary Target: Ollama Integration**

**Recommended Models (M3 MacBook Air optimized):**

- **Tier 1 (Recommended):** Llama 3.1 8B, Phi-3 Mini
- **Tier 2 (Alternative):** Mistral 7B, Gemma 2:2B
- **Tier 3 (Advanced):** Llama 3.1 13B (slower but higher quality)

**API Configuration:**

- Default endpoint: `http://localhost:11434/v1/chat/completions`
- Configurable endpoint URL and model name
- API timeout: 30 seconds per request
- Model availability validation on startup

**Refinement Prompt:**

```
You are a text refinement assistant. Clean up the following text by correcting grammar, improving clarity, and fixing any voice dictation errors. Maintain the original meaning and tone. Return only the refined text without explanations.

Text to refine: [USER_TEXT]

```

## User Interface Design

### Menu Bar Application

**Menu Bar Icon:** Subtle LLM/text icon in menu bar

**Dropdown Menu Options:**

- Process Selected Text (manual trigger)
- Run Batch Processing Now
- Settings...
- Quit

### Settings Window

**LLM Configuration Tab:**

- Ollama endpoint URL (text field)
- Model selection (dropdown with recommended models)
- Test connection (button)
- Model installation guide (link to documentation)

**Batch Processing Tab:**

- Enable/disable batch processing (toggle)
- Parent folder path (folder selector)
- Processing schedule (time picker)
- Last run status and next scheduled run

**Manual Mode Tab:**

- Keyboard shortcut configuration
- Enable/disable manual mode (toggle)

**Advanced Tab:**

- Retry attempt count (1-5, default: 3)
- Retry interval (30min-4hr, default: 1hr)
- Logging level (Error/Info/Debug)
- View logs (button)

## Error Handling & Recovery

### Retry Mechanism

**Failure Scenarios:**

- LLM service unavailable
- Network timeout
- Invalid API response
- Clipboard access failure

**Retry Logic:**

- Immediate failure notification to user
- Background retry: 1 hour intervals
- Maximum 3 total attempts
- Exponential backoff for server errors

### Data Protection

**Zero-Loss Guarantees:**

- Original text never modified or deleted
- All refinements appended with clear headers
- Failed operations logged but don't block workflow
- Automatic backup of processing queue

**Undo Functionality:**

- Simple undo: remove last "--Refined Version--" section
- Keyboard shortcut: Cmd+Z after refinement
- Available for 5 minutes after operation

## Installation & Setup

### System Requirements

**Hardware:**

- macOS 12.0+ (Monterey or later)
- Apple Silicon (M1/M2/M3) or Intel with 8GB+ RAM
- 2GB free disk space for application and models

**Dependencies:**

- Ollama installed and running
- Accessibility permissions for text capture
- File system access for batch processing

### Installation Process

**Step 1: Application Installation**

- Download .dmg installer
- Drag application to Applications folder
- Launch and grant necessary permissions

**Step 2: Ollama Setup**

- Install Ollama from official website
- Download recommended model: `ollama pull llama3.1:8b`
- Verify installation: `ollama list`

**Step 3: Configuration**

- Configure folder paths for batch processing
- Set keyboard shortcut preferences
- Test manual refinement functionality

## Development Guidelines

### Technology Stack

**Primary Language:** Swift 5.8+
**UI Framework:** SwiftUI
**Additional Frameworks:**

- Combine (reactive programming)
- Foundation (HTTP networking)
- AppKit (system integration)

### Code Architecture

**Design Patterns:**

- MVVM for UI components
- Repository pattern for LLM integration
- Observer pattern for file system monitoring
- Strategy pattern for different text sources

**Key Classes:**

```
├── TextRefinerApp.swift          // Main application entry point
├── Services/
│   ├── LLMService.swift          // Ollama API integration
│   ├── ClipboardService.swift    // Text capture/paste operations
│   ├── FileProcessingService.swift // Batch processing logic
│   └── SchedulerService.swift    // Background job management
├── ViewModels/
│   ├── SettingsViewModel.swift   // Configuration management
│   └── ProcessingViewModel.swift // Operation status tracking
└── Views/
    ├── MenuBarView.swift         // Menu bar interface
    ├── SettingsView.swift        // Settings window
    └── StatusView.swift          // Processing status display

```

### Testing Requirements

**Unit Tests:**

- LLM API integration
- Text processing logic
- File operations
- Error handling scenarios

**Integration Tests:**

- End-to-end manual refinement workflow
- Batch processing with real files
- Clipboard operations across different apps

**Performance Tests:**

- Large file processing (>1MB markdown files)
- Concurrent processing limits
- Memory usage during batch operations

## Security & Privacy

### Data Handling

**Privacy Principles:**

- All processing occurs locally (no cloud APIs)
- Text never leaves user's machine
- No telemetry or usage tracking
- User controls all data retention

**Security Measures:**

- Secure clipboard handling (clear sensitive data)
- File access limited to user-specified directories
- API communications over localhost only
- No storage of API keys or sensitive configuration

## Performance Specifications

### Response Time Requirements

**Manual Mode:**

- Text capture to LLM request: <500ms
- LLM processing (8B model): 2-10 seconds
- Paste operation: <200ms
- Total user-perceived latency: <15 seconds

**Batch Processing:**

- File scanning: <5 seconds for 1000 files
- Processing rate: 1-2 files per minute (depends on content length)
- Memory usage: <200MB during batch operations
- CPU usage: <25% sustained during processing

### Scalability Limits

**File Processing:**

- Maximum file size: 10MB per markdown file
- Maximum batch size: 500 files per run
- Maximum folder depth: 5 levels for scanning

**Concurrent Operations:**

- Single LLM request at a time (prevent model overload)
- Queue-based processing for batch operations
- Background processing doesn't block manual operations

## Monitoring & Logging

### Log Categories

**Application Logs:**

- Startup/shutdown events
- Configuration changes
- Performance metrics

**Processing Logs:**

- Manual refinement operations
- Batch processing results
- File operation success/failure

**Error Logs:**

- LLM communication failures
- File access errors
- System permission issues

### Log Storage

**Location:** `~/Library/Logs/LLMTextRefiner/`**Retention:** 30 days, 100MB maximum
**Format:** Structured JSON for programmatic analysis
**Privacy:** No actual text content logged, only metadata

## Future Enhancement Considerations

### Phase 2 Features

**Extended App Support:**

- Browser extension for web-based Notion
- Apple Notes integration via AppleScript
- More sophisticated text source detection

**Advanced Processing:**

- Multiple refinement templates
- Context-aware processing based on document type
- User feedback integration for model improvement

**Collaboration Features:**

- Shared refinement templates
- Team folder processing
- Processing statistics and insights

### Technical Debt Prevention

**Code Quality:**

- Comprehensive unit test coverage (>80%)
- Static analysis integration
- Regular dependency updates
- Performance regression testing

**Documentation:**

- API documentation for extensibility
- User manual with troubleshooting guide
- Developer documentation for future enhancements

---

## Acceptance Criteria

### Manual Mode Success Criteria

- [ ]  User can highlight text in Obsidian, Apple Notes, and other macOS apps
- [ ]  Keyboard shortcut reliably triggers refinement
- [ ]  Refined text appears below original with proper formatting
- [ ]  Original text remains unchanged
- [ ]  Clipboard contents are properly restored
- [ ]  Operation completes within 15 seconds for typical note length

### Batch Processing Success Criteria

- [ ]  System automatically creates Draft/Processed folder structure
- [ ]  Daily processing runs at configured time
- [ ]  Only processes files modified >2 hours ago
- [ ]  Processed files are moved to Processed folder
- [ ]  Failed operations are logged and retried appropriately
- [ ]  No data loss occurs during any operation

### Integration Success Criteria

- [ ]  Ollama integration works with recommended models
- [ ]  Application provides clear setup instructions
- [ ]  Error messages are user-friendly and actionable
- [ ]  Performance meets specified benchmarks
- [ ]  Application runs reliably as background service

### Quality Assurance Criteria

- [ ]  Zero data loss in all tested scenarios
- [ ]  Graceful handling of LLM service interruptions
- [ ]  Proper permission handling and user guidance
- [ ]  Memory and CPU usage within specified limits
- [ ]  Comprehensive error logging for troubleshooting