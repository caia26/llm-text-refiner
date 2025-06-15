# LLM Text Refiner - Test Organization

This document describes the comprehensive test organization structure for the LLM Text Refiner project.

## 📁 Test Structure Overview

```
LLMTextRefinerTests/
├── UnitTests/                    # Fast, isolated tests (no external dependencies)
│   ├── Models/                   # Data model tests
│   │   ├── AppConfigurationTests.swift
│   │   ├── RecommendedModelTests.swift
│   │   ├── ProcessingResultTests.swift
│   │   └── ChatModelsTests.swift
│   ├── Services/                 # Service layer tests with mocks
│   │   ├── LLMServiceTests.swift
│   │   ├── LLMServiceRetryTests.swift
│   │   ├── ClipboardServiceTests.swift      # Unit 5
│   │   ├── KeyboardShortcutManagerTests.swift # Unit 4
│   │   ├── FileSystemServiceTests.swift     # Unit 7
│   │   ├── MarkdownProcessorTests.swift     # Unit 8
│   │   ├── BatchProcessingServiceTests.swift # Unit 9
│   │   └── SchedulingServiceTests.swift     # Unit 10
│   └── Utilities/                # Configuration and utility tests
│       └── ConfigurationManagerTests.swift
├── IntegrationTests/             # Tests requiring external services
│   ├── APIIntegration/
│   │   └── LLMServiceIntegrationTests.swift
│   ├── Workflows/                # Workflow integration tests
│   │   ├── ManualRefinementWorkflowTests.swift # Unit 6
│   │   └── BatchProcessingWorkflowTests.swift  # Unit 9
│   └── FileSystem/               # File system integration tests
│       └── FileOperationsIntegrationTests.swift # Unit 7
├── MocksAndTestDoubles/          # Shared mock objects
│   ├── MockURLSession.swift
│   ├── MockLLMService.swift
│   ├── MockClipboardService.swift           # Unit 5
│   ├── MockFileSystemService.swift         # Unit 7
│   └── MockSchedulingService.swift         # Unit 10
├── TestUtilities/                # Shared testing utilities
│   ├── TestRunner.swift
│   ├── XCTestCase+Extensions.swift
│   └── TestConfiguration.swift
├── UITests/                      # User interface tests
│   └── SettingsUITests.swift                # Unit 12
├── PerformanceTests/             # Performance measurement tests
│   └── BatchProcessingPerformanceTests.swift # Unit 9
├── EndToEndTests/                # Complete user workflow tests
│   ├── CompleteManualWorkflowTests.swift    # Unit 6
│   └── CompleteBatchWorkflowTests.swift     # Unit 9
└── README.md                     # This file
```

## 🧪 Test Categories

### 1. Unit Tests (`UnitTests/`)

- **Purpose**: Fast, isolated tests with no external dependencies
- **Duration**: < 5 seconds total
- **Dependencies**: Mocks only
- **Run Command**: `⌘U` in Xcode or `xcodebuild test -scheme LLMTextRefiner`

**Subcategories:**

- **Models**: Test data structures, validation, serialization
- **Services**: Test business logic with mocked dependencies
- **Utilities**: Test helper classes and configuration management

### 2. Integration Tests (`IntegrationTests/`)

- **Purpose**: Test integration with external services and file system
- **Duration**: 10-60 seconds
- **Dependencies**: Ollama server, file system access
- **Environment**: `ENABLE_INTEGRATION_TESTS=true`

**Subcategories:**

- **APIIntegration**: Test real Ollama API communication
- **Workflows**: Test complete business workflows
- **FileSystem**: Test file operations and folder monitoring

### 3. UI Tests (`UITests/`)

- **Purpose**: Test user interface interactions
- **Duration**: 30-120 seconds
- **Dependencies**: App UI, Xcode UI testing framework
- **Environment**: `ENABLE_UI_TESTS=true`

### 4. Performance Tests (`PerformanceTests/`)

- **Purpose**: Measure and validate performance characteristics
- **Duration**: Variable (performance dependent)
- **Dependencies**: Performance measurement tools
- **Environment**: `ENABLE_PERFORMANCE_TESTS=true`

### 5. End-to-End Tests (`EndToEndTests/`)

- **Purpose**: Test complete user workflows from start to finish
- **Duration**: 60-300 seconds
- **Dependencies**: All services, UI, file system
- **Environment**: `ENABLE_E2E_TESTS=true`

## 🛠️ Shared Components

### MocksAndTestDoubles/

Centralized mock objects that can be reused across test files:

- `MockURLSession.swift` - HTTP networking mocks
- `MockLLMService.swift` - LLM service protocol mock
- Future mocks for clipboard, file system, scheduling services

### TestUtilities/

Shared testing utilities and extensions:

- `XCTestCase+Extensions.swift` - Common test helpers
- `TestConfiguration.swift` - Environment configuration
- `TestRunner.swift` - Test organization and execution

## 🚀 Running Tests

### Quick Unit Tests (Recommended for development)

```bash
# Fastest feedback loop - no external dependencies
xcodebuild test -scheme LLMTextRefiner
```

### Integration Tests

```bash
# Requires Ollama server running
ENABLE_INTEGRATION_TESTS=true xcodebuild test -scheme LLMTextRefiner
```

### All Tests

```bash
# Complete test suite
ENABLE_INTEGRATION_TESTS=true ENABLE_PERFORMANCE_TESTS=true ENABLE_E2E_TESTS=true xcodebuild test -scheme LLMTextRefiner
```

### Test Runner Utility

```swift
// In your test setup
await TestRunner.runTestSuite()
await TestRunner.runByCategory()
```

## 🔧 Environment Configuration

Set these environment variables in Xcode scheme or command line:

```bash
# Integration tests (requires Ollama)
ENABLE_INTEGRATION_TESTS=true

# Performance tests
ENABLE_PERFORMANCE_TESTS=true

# End-to-end tests
ENABLE_E2E_TESTS=true

# UI tests
ENABLE_UI_TESTS=true

# Verbose logging
VERBOSE_TEST_LOGGING=true
```

## 📋 Test Writing Guidelines

### Unit Tests

- Use mocks from `MocksAndTestDoubles/`
- Extend `XCTestCase+Extensions` for common functionality
- Test one component in isolation
- Fast execution (< 100ms per test)

```swift
import XCTest
@testable import LLMTextRefiner

class NewServiceTests: XCTestCase {

    var mockDependency: MockDependency!
    var service: NewService!

    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        service = NewService(dependency: mockDependency)
    }

    func testServiceBehavior() {
        // Test with mocked dependencies
    }
}
```

### Integration Tests

- Use `skipUnlessIntegrationEnabled()` to conditionally run
- Test real external service integration
- Use `TestConfiguration` for consistent setup

```swift
import XCTest
@testable import LLMTextRefiner

class NewIntegrationTests: XCTestCase {

    func testRealServiceIntegration() async throws {
        try skipUnlessIntegrationEnabled()
        try await skipUnlessOllamaAvailable()

        // Test with real services
    }
}
```

### Mock Objects

- Place in `MocksAndTestDoubles/`
- Follow protocol-based design
- Provide factory methods for common scenarios

```swift
// MocksAndTestDoubles/MockNewService.swift
import Foundation
@testable import LLMTextRefiner

protocol NewServiceProtocol {
    func performAction() async throws -> Result
}

extension NewService: NewServiceProtocol {}

final class MockNewService: NewServiceProtocol {
    var performActionCalled = false
    var resultToReturn: Result = .success

    func performAction() async throws -> Result {
        performActionCalled = true
        return resultToReturn
    }

    // Factory methods
    static func successful() -> MockNewService {
        let mock = MockNewService()
        mock.resultToReturn = .success
        return mock
    }

    static func failing() -> MockNewService {
        let mock = MockNewService()
        mock.resultToReturn = .failure
        return mock
    }
}
```

## 🗺️ Future Unit Roadmap

The test structure is prepared for all 15 implementation units:

- **✅ Unit 2**: App Configuration (Models + Utilities)
- **✅ Unit 3**: Ollama API Integration (Services + Integration)
- **🔄 Unit 4**: Keyboard Shortcut Manager (Services)
- **🔄 Unit 5**: Clipboard Integration Service (Services + Integration)
- **🔄 Unit 6**: Manual Text Refinement Workflow (Workflows + E2E)
- **🔄 Unit 7**: File System Service (Services + Integration + FileSystem)
- **🔄 Unit 8**: Markdown Processor (Services)
- **🔄 Unit 9**: Batch Processing Service (Services + Performance + E2E)
- **🔄 Unit 10**: Scheduling Service (Services)
- **🔄 Unit 11**: Menu Bar Implementation (UI)
- **🔄 Unit 12**: Settings UI (UI + UITests)
- **🔄 Unit 13**: Error Handling (Services)
- **🔄 Unit 14**: Testing & Quality Assurance (All Categories)
- **🔄 Unit 15**: Performance Optimization (Performance)

## 🎯 Benefits of This Organization

1. **Fast Feedback Loop**: Unit tests run in < 5 seconds
2. **Clear Separation**: Different test types for different purposes
3. **Reusable Components**: Shared mocks and utilities
4. **Scalable Structure**: Ready for all 15 units
5. **CI/CD Ready**: Environment-based test selection
6. **Professional Quality**: Industry-standard test organization

## 🔍 Test Discovery

The test structure supports easy test discovery:

- Unit tests for daily development
- Integration tests for CI/CD
- Performance tests for optimization
- E2E tests for release validation

This organization ensures comprehensive testing while maintaining fast development cycles.
