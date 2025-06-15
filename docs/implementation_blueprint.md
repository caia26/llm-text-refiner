## Overview

This blueprint breaks down the LLM Text Refiner into 15 sequential, testable units of work. Each unit builds on previous ones and can be independently validated.

---

## Unit 1: Project Foundation & Basic App Structure

**Dependencies:** None

**Testing:** App launches and shows menu bar icon

### Prompt for LLM:

```
Create a basic macOS SwiftUI application with the following requirements:

1. Create an Xcode project named "LLMTextRefiner"
2. Set up a menu bar application (no dock icon) using NSStatusBar
3. Create the main app entry point that:
   - Runs as a background service
   - Shows a simple menu bar icon (use SF Symbol "text.bubble")
   - Has a dropdown menu with placeholder items: "Settings", "Quit"
4. Set up the basic project structure with folders:
   - Services/ (empty for now)
   - ViewModels/ (empty for now)
   - Views/ (empty for now)
   - Models/ (empty for now)
5. Configure Info.plist for:
   - LSUIElement = true (no dock icon)
   - Minimum macOS version 12.0
   - App name and bundle identifier

Provide the complete Xcode project structure with all necessary files to build and run a basic menu bar app.

```

---

## Unit 2: Configuration Data Models

**Dependencies:** Unit 1

**Testing:** Configuration objects can be created and serialized

### Prompt for LLM:

```
Create configuration data models for the LLM Text Refiner app with the following requirements:

1. Create a `AppConfiguration` struct that conforms to Codable with properties:
   - `ollamaEndpoint: String` (default: "http://localhost:11434/v1/chat/completions")
   - `selectedModel: String` (default: "llama3.1:8b")
   - `keyboardShortcut: String` (default: "cmd+shift+r")
   - `isManualModeEnabled: Bool` (default: true)
   - `isBatchProcessingEnabled: Bool` (default: true)
   - `batchProcessingTime: Date` (default: 9 PM today)
   - `parentFolderPath: String?` (user-selected folder)
   - `retryAttempts: Int` (default: 3)
   - `retryInterval: TimeInterval` (default: 3600 seconds)

2. Create a `RecommendedModel` struct with:
   - `name: String`
   - `displayName: String`
   - `description: String`
   - `tier: ModelTier` (enum: recommended, alternative, advanced)
   - `estimatedRAM: String`
   - `installCommand: String`

3. Create a `ProcessingResult` enum with associated values:
   - `success(originalText: String, refinedText: String)`
   - `failure(error: ProcessingError)`
   - `queued(retryAttempt: Int)`

4. Create a `ProcessingError` enum with cases:
   - `llmUnavailable`
   - `networkTimeout`
   - `invalidResponse`
   - `clipboardError`
   - `fileError(String)`

5. Create a configuration manager class `ConfigurationManager` that:
   - Loads/saves configuration to UserDefaults
   - Provides default configuration
   - Has methods: `load()`, `save(_:)`, `reset()`

Include unit tests for all models and the configuration manager.

```

---

## Unit 3: Ollama API Integration Service

**Dependencies:** Unit 2

**Testing:** Can communicate with local Ollama instance

### Prompt for LLM:

```
Create an Ollama API integration service with the following requirements:

1. Create a `LLMService` class that handles communication with Ollama:
   - Uses URLSession for HTTP requests
   - Implements OpenAI-compatible chat completions endpoint
   - Has configurable endpoint URL and model name
   - Includes request timeout (30 seconds)
   - Implements retry logic with exponential backoff

2. Create request/response models:
   - `ChatCompletionRequest` with messages array
   - `ChatCompletionResponse` with choices array
   - `ChatMessage` with role and content
   - Error response handling

3. Main LLMService methods:
   - `refineText(_ text: String) async throws -> String`
   - `testConnection() async throws -> Bool`
   - `isServiceAvailable() async -> Bool`

4. The refinement prompt should be:
   "You are a text refinement assistant. Clean up the following text by correcting grammar, improving clarity, and fixing any voice dictation errors. Maintain the original meaning and tone. Return only the refined text without explanations."

5. Include comprehensive error handling for:
   - Network connectivity issues
   - Invalid API responses
   - Service unavailable
   - Timeout scenarios

6. Add retry mechanism:
   - Maximum 3 attempts
   - Exponential backoff (1s, 2s, 4s)
   - Different strategies for different error types

Create unit tests that mock the network layer and test all success/failure scenarios.

```

---

## Unit 4: Global Keyboard Shortcut Registration

**Dependencies:** Unit 1, Unit 2

**Testing:** Keyboard shortcut triggers callback function

### Prompt for LLM:

```
Create a global keyboard shortcut registration system with the following requirements:

1. Create a `KeyboardShortcutManager` class that:
   - Registers global keyboard shortcuts using Carbon framework
   - Converts string representations (like "cmd+shift+r") to key codes
   - Handles callback execution when shortcuts are triggered
   - Can enable/disable shortcuts dynamically
   - Properly cleans up resources on deallocation

2. Key features needed:
   - `registerShortcut(_ shortcut: String, callback: @escaping () -> Void) -> Bool`
   - `unregisterShortcut(_ shortcut: String)`
   - `updateShortcut(from old: String, to new: String, callback: @escaping () -> Void)`
   - `isShortcutAvailable(_ shortcut: String) -> Bool`

3. Support parsing shortcut strings with modifiers:
   - "cmd", "shift", "alt", "ctrl" modifiers
   - Letter keys (a-z)
   - Function keys (f1-f12)
   - Example: "cmd+shift+r", "alt+f5"

4. Handle conflicts and validation:
   - Check if shortcut is already taken by system/other apps
   - Validate shortcut string format
   - Provide meaningful error messages

5. Include proper Carbon framework imports and memory management

6. Create a simple test harness that:
   - Registers a test shortcut
   - Prints when the shortcut is triggered
   - Demonstrates cleanup on app termination

Note: Focus on the Carbon-based global hotkey registration, not the clipboard operations (that's next unit).

```

---

## Unit 5: Clipboard Operations Service

**Dependencies:** Unit 1, Unit 2

**Testing:** Can capture, process, and restore clipboard contents

### Prompt for LLM:

```
Create a clipboard operations service with the following requirements:

1. Create a `ClipboardService` class that handles:
   - Reading current clipboard contents
   - Temporarily storing original clipboard data
   - Writing new content to clipboard
   - Restoring original clipboard contents
   - Getting currently selected text via copy operation

2. Core methods needed:
   - `captureSelectedText() async throws -> String`
   - `pasteRefinedText(_ originalText: String, _ refinedText: String) async throws`
   - `restoreClipboard() async throws`
   - `backupCurrentClipboard()`

3. The clipboard workflow should:
   - Backup current clipboard contents
   - Simulate Cmd+C to copy selected text
   - Read the copied text
   - Process text and format output as: "[original text]\n\n--Refined Version--\n[refined text]"
   - Simulate Cmd+V to paste the formatted result
   - Restore original clipboard contents

4. Handle edge cases:
   - Empty clipboard
   - Non-text clipboard contents
   - Clipboard access denied
   - Application focus issues

5. Use NSPasteboard for clipboard operations and proper type handling:
   - NSPasteboard.PasteboardType.string
   - Handle multiple pasteboard types gracefully
   - Proper error handling for pasteboard operations

6. Include timing controls:
   - Brief delays between copy/paste operations (100-200ms)
   - Timeout handling for clipboard operations

7. Create unit tests that:
   - Mock clipboard operations
   - Test the complete capture-process-paste workflow
   - Verify clipboard restoration
   - Test error scenarios

Note: Use CGEvent for simulating Cmd+C and Cmd+V key presses.

```

---

## Unit 6: Manual Text Refinement Workflow

**Dependencies:** Units 3, 4, 5

**Testing:** End-to-end manual refinement works

### Prompt for LLM:

```
Create the manual text refinement workflow by integrating the keyboard shortcut, clipboard, and LLM services:

1. Create a `ManualRefinementService` class that orchestrates:
   - Keyboard shortcut triggering
   - Text capture via clipboard
   - LLM processing
   - Result pasting
   - Error handling and user feedback

2. Core workflow method:
   - `performManualRefinement() async`

3. The complete workflow should:
   - Be triggered by the registered keyboard shortcut
   - Show a brief status indicator (menu bar icon change or notification)
   - Capture selected text using ClipboardService
   - Send text to LLM via LLMService
   - Format and paste the result
   - Handle all error scenarios gracefully
   - Restore clipboard contents

4. Error handling and user feedback:
   - Show notifications for different states: "Processing...", "Complete", "Error: [message]"
   - Use NSUserNotification or modern UserNotifications framework
   - Implement retry logic for transient failures
   - Log errors for debugging

5. Status indication:
   - Change menu bar icon during processing (e.g., add spinner or change color)
   - Restore original icon when complete
   - Show meaningful error states in the menu bar

6. Integration points:
   - Wire up the keyboard shortcut to trigger this workflow
   - Ensure proper async/await handling
   - Add configuration checks (is manual mode enabled?)

7. Create integration tests that:
   - Mock all service dependencies
   - Test the complete workflow end-to-end
   - Verify error handling and recovery
   - Test with various text inputs

Include proper error logging and user-friendly notifications for all failure scenarios.

```

---

## Unit 7: File System Operations Service

**Dependencies:** Unit 2

**Testing:** Can scan, read, modify, and move markdown files

### Prompt for LLM:

```
Create a file system operations service for markdown file processing:

1. Create a `FileSystemService` class that handles:
   - Scanning directories for markdown files
   - Reading markdown file contents
   - Writing modified content back to files
   - Moving files between directories
   - Creating directory structures
   - File modification time checking

2. Core methods needed:
   - `scanForMarkdownFiles(in directory: URL) throws -> [URL]`
   - `readFileContent(at url: URL) throws -> String`
   - `writeFileContent(_ content: String, to url: URL) throws`
   - `moveFile(from source: URL, to destination: URL) throws`
   - `createDirectoryStructure(at parentPath: URL) throws`
   - `getFileModificationDate(at url: URL) throws -> Date`
   - `isFileRecentlyModified(at url: URL, within timeInterval: TimeInterval) throws -> Bool`

3. Directory structure management:
   - Create "Draft" and "Processed" folders if they don't exist
   - Validate parent folder path exists and is accessible
   - Handle permissions and access errors gracefully

4. Markdown file detection and filtering:
   - Only process files with .md extension
   - Skip hidden files (starting with .)
   - Skip files recently modified (within 2 hours by default)
   - Skip files already containing "--Refined Version--" headers

5. File content manipulation:
   - Detect if file already contains refined content
   - Append refined content with proper formatting
   - Preserve original file encoding (UTF-8)
   - Handle large files efficiently

6. Error handling for:
   - File not found
   - Permission denied
   - Disk space issues
   - File in use/locked
   - Invalid file paths

7. Create unit tests with:
   - Temporary test directories
   - Mock file scenarios
   - Permission testing
   - Large file handling
   - Concurrent access scenarios

Include proper file URL handling and security-scoped bookmarks for sandboxed apps.

```

---

## Unit 8: Markdown Content Processing

**Dependencies:** Unit 7

**Testing:** Can detect and append refined content to markdown files

### Prompt for LLM:

```
Create a markdown content processing service for handling refined text insertion:

1. Create a `MarkdownProcessor` class that handles:
   - Parsing markdown content to detect existing refined sections
   - Extracting original content for refinement
   - Appending refined content with proper formatting
   - Maintaining markdown structure and formatting

2. Core methods needed:
   - `hasRefinedContent(_ content: String) -> Bool`
   - `extractOriginalContent(_ content: String) -> String`
   - `appendRefinedContent(original: String, refined: String, to content: String) -> String`
   - `formatRefinedSection(_ text: String) -> String`

3. Content detection logic:
   - Check if file already contains "--Refined Version--" headers
   - Handle multiple refined sections in one file
   - Preserve existing markdown formatting (headers, lists, links, etc.)

4. Content formatting rules:
   - Add refined content at the end of the file
   - Use consistent header format: "\n\n--Refined Version--\n"
   - Maintain proper spacing and line breaks
   - Preserve original content exactly as-is

5. Handle edge cases:
   - Empty files
   - Files with only whitespace
   - Files with complex markdown structures
   - Very large files (>1MB)
   - Files with special characters or encoding issues

6. Content extraction for refinement:
   - Extract main content excluding refined sections
   - Handle multiple paragraphs intelligently
   - Skip markdown metadata (front matter)
   - Remove excessive whitespace while preserving structure

7. Create unit tests with:
   - Various markdown file examples
   - Files with existing refined content
   - Complex markdown structures
   - Edge case content (empty, whitespace-only, etc.)
   - Large content processing

Include proper handling of markdown front matter and special markdown syntax.

```

---

## Unit 9: Batch Processing Engine

**Dependencies:** Units 3, 7, 8

**Testing:** Can process multiple files in Draft folder

### Prompt for LLM:

```
Create a batch processing engine that processes markdown files from Draft to Processed folder:

1. Create a `BatchProcessingService` class that:
   - Scans the Draft folder for eligible files
   - Processes each file through the LLM
   - Moves processed files to Processed folder
   - Handles errors and logging for batch operations

2. Core methods needed:
   - `processBatch(in parentFolder: URL) async throws -> BatchResult`
   - `processFile(_ fileURL: URL, using llmService: LLMService) async throws`
   - `isFileEligibleForProcessing(_ fileURL: URL) throws -> Bool`

3. Create a `BatchResult` struct with:
   - `processedFiles: [URL]`
   - `skippedFiles: [URL]`
   - `failedFiles: [(URL, Error)]`
   - `totalProcessingTime: TimeInterval`

4. File eligibility criteria:
   - Must be .md file
   - Not modified within last 2 hours
   - Doesn't already contain "--Refined Version--" header
   - File is readable and not locked

5. Processing workflow for each file:
   - Read file content using FileSystemService
   - Check if already refined using MarkdownProcessor
   - Extract original content for refinement
   - Send to LLM for processing
   - Append refined content using MarkdownProcessor
   - Write updated content back to file
   - Move file from Draft to Processed folder

6. Error handling and resilience:
   - Continue processing other files if one fails
   - Log detailed error information for each failure
   - Implement per-file timeout (5 minutes max)
   - Handle LLM service unavailability gracefully

7. Progress tracking and logging:
   - Log start/end of batch processing
   - Log each file processed, skipped, or failed
   - Track total processing time and file counts
   - Provide progress callbacks for UI updates

8. Create integration tests that:
   - Set up test folder structures with various file scenarios
   - Test complete batch processing workflows
   - Verify file movements and content changes
   - Test error scenarios and recovery

Include proper async/await handling and cancellation support for long-running operations.

```

---

## Unit 10: Scheduling Service

**Dependencies:** Unit 9

**Testing:** Can schedule and execute batch processing at specified times

### Prompt for LLM:

```
Create a scheduling service for automated batch processing:

1. Create a `SchedulingService` class that handles:
   - Scheduling daily batch processing at user-specified times
   - Managing scheduled tasks and timers
   - Executing batch processing automatically
   - Handling schedule changes and cancellations

2. Core methods needed:
   - `scheduleDaily(at time: Date, parentFolder: URL)`
   - `updateSchedule(to newTime: Date)`
   - `cancelSchedule()`
   - `executeScheduledBatch() async`
   - `isScheduleActive() -> Bool`
   - `nextScheduledRun() -> Date?`

3. Scheduling implementation:
   - Use Timer or DispatchSourceTimer for reliable scheduling
   - Calculate next execution time based on user-configured time
   - Handle schedule persistence across app restarts
   - Account for daylight saving time changes

4. Schedule persistence:
   - Save schedule configuration to UserDefaults
   - Restore active schedules on app launch
   - Handle cases where scheduled time has passed during app downtime

5. Background execution:
   - Ensure batch processing can run when app is in background
   - Handle system sleep/wake cycles
   - Respect system performance and power management

6. Error handling and recovery:
   - Log scheduling errors and failures
   - Retry failed batch operations using existing retry logic
   - Handle cases where parent folder is unavailable
   - Graceful degradation if LLM service is down

7. Schedule management:
   - Only one active schedule at a time
   - Automatic rescheduling for next day after execution
   - Handle manual batch processing while schedule is active

8. Integration with batch processing:
   - Use BatchProcessingService for actual file processing
   - Pass configuration from AppConfiguration
   - Log batch results and errors

9. Create unit tests that:
   - Test schedule calculation and timing
   - Mock time-based operations
   - Test persistence and restoration
   - Verify proper cleanup and resource management

Include proper handling of edge cases like schedule conflicts and system time changes.

```

---

## Unit 11: File Location Detection Service

**Dependencies:** Units 5, 7

**Testing:** Can detect when manual refinement occurs in Draft folder

### Prompt for LLM:

```
Create a file location detection service that determines if manual refinement occurred in a Draft folder file:

1. Create a `FileLocationService` class that:
   - Detects the current file being edited when manual refinement is triggered
   - Determines if the file is located in a Draft folder
   - Handles file movement from Draft to Processed after manual refinement

2. Core methods needed:
   - `getCurrentActiveFile() -> URL?`
   - `isFileInDraftFolder(_ fileURL: URL, parentFolder: URL) -> Bool`
   - `moveFileToProcessed(_ fileURL: URL, parentFolder: URL) throws`
   - `shouldMoveAfterManualRefinement(_ fileURL: URL) -> Bool`

3. Active file detection strategies:
   - Use NSWorkspace to get frontmost application and document
   - Handle application-specific file detection (Obsidian, Apple Notes)
   - Fall back to asking user to save file first if detection fails
   - Use Accessibility APIs as secondary method

4. Draft folder detection:
   - Check if file path contains the configured Draft folder
   - Handle symbolic links and aliases properly
   - Support nested folder structures
   - Validate folder relationships

5. File movement logic:
   - Only move files that are actually in Draft folder
   - Preserve file metadata and timestamps
   - Handle naming conflicts in Processed folder
   - Create Processed folder if it doesn't exist

6. Integration with manual refinement:
   - Hook into the manual refinement workflow
   - Execute file movement after successful refinement
   - Handle errors without breaking the main workflow
   - Log file movements for user awareness

7. Error handling:
   - File detection failures (graceful degradation)
   - Permission issues with file movement
   - Folder structure problems
   - File conflicts and naming issues

8. Platform-specific considerations:
   - Handle sandboxing restrictions
   - Work with security-scoped bookmarks
   - Support different file system types
   - Handle network drives and cloud storage

9. Create unit tests that:
   - Mock file system operations
   - Test various folder structure scenarios
   - Verify proper file movement behavior
   - Test error conditions and recovery

Include fallback mechanisms when automatic file detection isn't possible.

```

---

## Unit 12: Settings View and Configuration UI

**Dependencies:** Units 2, 4

**Testing:** Settings window allows configuration of all options

### Prompt for LLM:

```
Create a settings view and configuration UI for the LLM Text Refiner:

1. Create a `SettingsView` SwiftUI view with tabbed interface:
   - LLM Configuration tab
   - Batch Processing tab
   - Manual Mode tab
   - Advanced tab

2. LLM Configuration tab (`LLMConfigurationView`):
   - Ollama endpoint URL text field with validation
   - Model selection dropdown with recommended models
   - Test connection button with status indicator
   - Model installation instructions link
   - Connection status display (connected/disconnected/error)

3. Batch Processing tab (`BatchProcessingView`):
   - Enable/disable batch processing toggle
   - Parent folder path selector with browse button
   - Processing schedule time picker
   - Last run status and next scheduled run display
   - Manual "Run Batch Now" button

4. Manual Mode tab (`ManualModeView`):
   - Enable/disable manual mode toggle
   - Keyboard shortcut configuration field
   - Shortcut conflict detection and validation
   - Test shortcut button

5. Advanced tab (`AdvancedView`):
   - Retry attempt count stepper (1-5)
   - Retry interval slider (30min-4hr)
   - Logging level picker (Error/Info/Debug)
   - View logs button
   - Reset to defaults button

6. Create a `SettingsViewModel` class that:
   - Manages configuration state using @Published properties
   - Handles validation and error states
   - Interfaces with ConfigurationManager
   - Provides real-time validation feedback

7. UI components and validation:
   - Real-time URL validation for Ollama endpoint
   - Folder path validation and accessibility checking
   - Keyboard shortcut conflict detection
   - Form validation with clear error messages

8. Integration features:
   - Test connection functionality with loading states
   - Folder browser using NSOpenPanel
   - Keyboard shortcut recorder control
   - Live validation and error display

9. Settings window management:
   - Modal window presentation from menu bar
   - Proper window lifecycle management
   - Save/cancel button functionality
   - Unsaved changes warning

10. Create UI tests that:
    - Test all form controls and validation
    - Verify settings persistence
    - Test error states and recovery
    - Verify proper data binding

Include proper SwiftUI state management and form validation patterns.

```

---

## Unit 13: Menu Bar Interface and Status Management

**Dependencies:** Units 1, 12

**Testing:** Menu bar provides access to all features and shows status

### Prompt for LLM:

```
Create a comprehensive menu bar interface and status management system:

1. Create a `MenuBarView` SwiftUI view that provides:
   - Dynamic menu items based on app state
   - Status indicators for processing operations
   - Quick access to main features
   - Settings access

2. Menu structure and items:
   - "Process Selected Text" (manual refinement trigger)
   - "Run Batch Processing Now" (manual batch trigger)
   - Separator
   - Status display (last batch run, processing status)
   - Separator
   - "Settings..." (opens settings window)
   - "About" (shows app info)
   - "Quit"

3. Create a `StatusManager` class that tracks:
   - Current processing state (idle/processing/error)
   - Last batch processing results
   - LLM service connection status
   - Recent operation history

4. Status indication system:
   - Change menu bar icon based on status (idle/processing/error/success)
   - Show processing spinner during operations
   - Display brief status messages in menu
   - Use different colors or badges for various states

5. Dynamic menu updates:
   - Enable/disable menu items based on current state
   - Show processing progress for batch operations
   - Display error states with actionable messages
   - Update menu in real-time during operations

6. Menu item actions:
   - Wire up manual refinement trigger
   - Implement manual batch processing trigger
   - Open settings window
   - Show about dialog with version info
   - Graceful app termination

7. Status persistence:
   - Remember last batch processing results
   - Store operation history (last 10 operations)
   - Persist across app restarts
   - Clear old status data automatically

8. User feedback and notifications:
   - Brief success notifications for completed operations
   - Error notifications with actionable messages
   - Progress indicators for long-running operations
   - Subtle status changes that don't interrupt workflow

9. Create a `MenuBarViewModel` that:
   - Manages menu state and updates
   - Coordinates with all service layers
   - Handles user interactions and commands
   - Provides real-time status updates

10. Integration testing:
    - Test all menu item actions
    - Verify status updates during operations
    - Test error state handling and recovery
    - Verify proper cleanup on app termination

Include proper SwiftUI menu bar integration and state management patterns.

```

---

## Unit 14: Logging and Error Handling System

**Dependencies:** All previous units

**Testing:** Comprehensive logging and error reporting works

### Prompt for LLM:

```
Create a comprehensive logging and error handling system:

1. Create a `LoggingService` class that provides:
   - Structured logging with different levels (Debug, Info, Warning, Error)
   - File-based log persistence with rotation
   - Real-time log viewing capability
   - Privacy-aware logging (no sensitive content)

2. Log levels and categories:
   - Application lifecycle (startup, shutdown, configuration changes)
   - Processing operations (manual/batch refinement results)
   - LLM communication (connection status, response times, errors)
   - File operations (reads, writes, moves, errors)
   - User interactions (settings changes, manual triggers)

3. Log storage and management:
   - Store logs in `~/Library/Logs/LLMTextRefiner/`
   - Implement log rotation (100MB max per file, keep 5 files)
   - Use structured format (JSON) for programmatic analysis
   - Include timestamps, log levels, categories, and messages

4. Create a `LogEntry` struct with:
   - `timestamp: Date`
   - `level: LogLevel` (enum: debug, info, warning, error)
   - `category: LogCategory` (enum: app, processing, llm, filesystem, user)
   - `message: String`
   - `metadata: [String: Any]?` (additional context)

5. Privacy and security considerations:
   - Never log actual text content being processed
   - Hash or truncate sensitive file paths
   - Log only metadata (file sizes, processing times, error types)
   - Include opt-out mechanism for detailed logging

6. Error handling framework:
   - Centralized error reporting through LoggingService
   - Error categorization and severity classification
   - Automatic error recovery suggestions
   - Error aggregation to prevent log spam

7. Integration with existing services:
   - Add logging calls throughout all service layers
   - Log operation start/end times for performance tracking
   - Include correlation IDs for tracking operations across services
   - Log configuration changes and validation errors

8. Log viewing interface:
   - Create a `LogViewerView` SwiftUI view for real-time log viewing
   - Filter logs by level, category, and time range
   - Search functionality for log entries
   - Export logs for debugging purposes

9. Performance considerations:
   - Asynchronous logging to avoid blocking main operations
   - Efficient file I/O with proper buffering
   - Configurable log levels to reduce overhead
   - Automatic cleanup of old log files

10. Create monitoring and diagnostics:
    - Health check functionality for all services
    - Performance metrics collection (operation times, success rates)
    - System resource usage monitoring
    - Automatic error pattern detection

Include comprehensive error recovery mechanisms and user-friendly error messages throughout the system.

```

---

## Unit 15: Integration Testing and App Finalization

**Dependencies:** All previous units

**Testing:** Complete end-to-end application testing

### Prompt for LLM:

```
Create comprehensive integration tests and finalize the complete application:

1. Create integration test suites that verify:
   - Complete manual refinement workflow (keyboard shortcut → clipboard → LLM → paste)
   - Full batch processing pipeline (scan → process → move files)
   - Settings persistence and configuration management
   - Error handling and recovery across all services
   - Menu bar interface and user interactions

2. End-to-end test scenarios:
   - **Manual Workflow Test**: Set up test environment, trigger manual refinement, verify text processing and pasting
   - **Batch Processing Test**: Create test folder structure with sample markdown files, run batch processing, verify results
   - **Configuration Test**: Test all settings combinations, verify persistence, test validation
   - **Error Recovery Test**: Simulate various failure scenarios, verify graceful degradation and recovery
   - **Performance Test**: Test with large files and batch operations, verify memory/CPU usage

3. Create a comprehensive test harness:
   - Mock LLM service for predictable testing
   - Temporary file system setup for batch processing tests
   - Keyboard shortcut simulation for manual mode testing
   - Configuration reset utilities for clean test states

4. App finalization checklist:
   - Complete Info.plist configuration (permissions, descriptions, etc.)
   - Add proper app icons and menu bar icons
   - Implement accessibility features and VoiceOver support
   - Add proper error messages and user guidance
   - Implement crash reporting and diagnostics

5. Permission and security setup:
   - Accessibility permissions request flow with clear explanations
   - File system access permissions for batch processing
   - Security-scoped bookmarks for folder access
   - Proper sandboxing configuration if needed

6. User onboarding and help:
   - First-run setup wizard for Ollama and folder configuration
   - In-app help documentation and troubleshooting guides
   - Clear error messages with actionable solutions
   - Link to GitHub repository and documentation

7. Performance optimization:
   - Memory usage optimization for large file processing
   - CPU usage optimization during batch operations
   - Startup time optimization
   - Background processing efficiency

8. Distribution preparation:
   - Code signing setup for macOS distribution
   - Build configuration for release vs debug
   - Automated build scripts and CI/CD setup
   - GitHub Actions workflow for building and releasing

9. Create final validation tests:
   - Fresh installation testing on clean macOS system
   - Test with different Ollama models and configurations
   - Verify proper cleanup and uninstallation
   - Cross-version compatibility testing

10. Documentation and deployment:
    - Complete README with installation and usage instructions
    - API documentation for future extensibility
    - Troubleshooting guide for common issues
    - Release notes and version management

Include comprehensive test coverage reports and performance benchmarks for all critical operations.

```

---

## Implementation Guidelines

### Development Sequence

1. **Foundation (Units 1-2)**: Basic app structure and data models
2. **Core Services (Units 3-5)**: LLM integration, keyboard shortcuts, clipboard operations
3. **Manual Workflow (Unit 6)**: Complete manual refinement feature
4. **File Processing (Units 7-8)**: File operations and markdown processing
5. **Batch Processing (Units 9-11)**: Automated processing and scheduling
6. **User Interface (Units 12-13)**: Settings and menu bar interface
7. **Polish (Units 14-15)**: Logging, testing, and finalization

### Testing Strategy

- Each unit includes specific testing requirements
- Unit tests for individual components
- Integration tests for service interactions
- End-to-end tests for complete workflows
- Performance tests for critical operations

### Key Success Criteria

- Zero data loss in all scenarios
- Sub-15 second manual refinement operations
- Reliable batch processing of 500+ files
- Intuitive user interface with minimal learning curve
- Comprehensive error handling and recovery