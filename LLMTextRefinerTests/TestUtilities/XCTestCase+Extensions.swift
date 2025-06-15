import XCTest
import Foundation
@testable import LLMTextRefiner

// MARK: - Async Testing Extensions

extension XCTestCase {
    
    /// Wait for async operation with timeout
    func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { 
                try await operation() 
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
    
    /// Assert that an async operation completes within the specified timeout
    func assertAsyncCompletes<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        do {
            return try await waitForAsync(timeout: timeout, operation: operation)
        } catch is TimeoutError {
            XCTFail("Operation timed out after \(timeout) seconds", file: file, line: line)
            throw TimeoutError()
        }
    }
    
    /// Assert that an async operation throws a specific error
    func assertAsyncThrows<T, E: Error & Equatable>(
        _ expectedError: E,
        operation: @escaping () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected operation to throw \(expectedError)", file: file, line: line)
        } catch let error as E where error == expectedError {
            // Success - expected error was thrown
        } catch {
            XCTFail("Expected \(expectedError), but got \(error)", file: file, line: line)
        }
    }
}

// MARK: - File System Testing Extensions

extension XCTestCase {
    
    /// Create a temporary directory for testing file operations
    func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LLMTextRefinerTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        return tempDir
    }
    
    /// Create a temporary file with content
    func createTemporaryFile(
        content: String,
        fileName: String = "test.txt",
        in directory: URL? = nil
    ) throws -> URL {
        let dir = directory ?? (try createTemporaryDirectory())
        let fileURL = dir.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        if directory == nil {
            addTeardownBlock {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        return fileURL
    }
    
    /// Read content from a file URL
    func readFile(at url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }
}

// MARK: - UserDefaults Testing Extensions

extension XCTestCase {
    
    /// Clean UserDefaults for testing configuration
    func cleanUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        UserDefaults.standard.synchronize()
    }
    
    /// Setup clean UserDefaults and return a ConfigurationManager
    func setupCleanConfiguration() -> ConfigurationManager {
        cleanUserDefaults()
        return ConfigurationManager()
    }
    
    /// Create a test configuration with custom values
    func createTestConfiguration(
        ollamaEndpoint: String = "http://localhost:11434/v1/chat/completions",
        selectedModel: String = "llama3.1:8b",
        keyboardShortcut: String = "cmd+shift+r",
        isManualModeEnabled: Bool = true,
        isBatchProcessingEnabled: Bool = true,
        batchProcessingTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
        parentFolderPath: String? = nil,
        retryAttempts: Int = 3,
        retryInterval: TimeInterval = 3600
    ) -> AppConfiguration {
        return AppConfiguration(
            ollamaEndpoint: ollamaEndpoint,
            selectedModel: selectedModel,
            keyboardShortcut: keyboardShortcut,
            isManualModeEnabled: isManualModeEnabled,
            isBatchProcessingEnabled: isBatchProcessingEnabled,
            batchProcessingTime: batchProcessingTime,
            parentFolderPath: parentFolderPath,
            retryAttempts: retryAttempts,
            retryInterval: retryInterval
        )
    }
}

// MARK: - JSON Testing Extensions

extension XCTestCase {
    
    /// Create mock JSON data from an encodable object
    func createJSONData<T: Encodable>(_ object: T) throws -> Data {
        return try JSONEncoder().encode(object)
    }
    
    /// Create a mock ChatCompletionResponse for testing
    func createMockChatResponse(
        content: String = "Mock response",
        model: String = "test-model"
    ) -> ChatCompletionResponse {
        return ChatCompletionResponse(
            id: "test-\(UUID().uuidString)",
            object: "chat.completion",
            created: Int(Date().timeIntervalSince1970),
            model: model,
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant(content),
                    finishReason: "stop"
                )
            ],
            usage: ChatCompletionResponse.ChatUsage(
                promptTokens: 10,
                completionTokens: 5,
                totalTokens: 15
            )
        )
    }
    
    /// Create a mock HTTP response
    func createMockHTTPResponse(
        statusCode: Int = 200,
        url: String = "http://localhost:11434/v1/chat/completions"
    ) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    /// Create a mock API error response
    func createMockErrorResponse(
        message: String = "Test error",
        type: String = "test_error",
        code: String = "test_code"
    ) -> APIErrorResponse {
        return APIErrorResponse(
            error: APIErrorResponse.APIError(
                message: message,
                type: type,
                param: nil,
                code: code
            )
        )
    }
}

// MARK: - Performance Testing Extensions

extension XCTestCase {
    
    /// Measure async operation performance
    func measureAsync(
        operation: @escaping () async throws -> Void
    ) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try await operation()
        } catch {
            XCTFail("Operation failed during performance measurement: \(error)")
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱️ Operation completed in \(String(format: "%.3f", timeElapsed))s")
    }
    
    /// Assert that an operation completes within a time limit
    func assertCompletesWithin<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(
            elapsed, 
            seconds, 
            "Operation took \(String(format: "%.3f", elapsed))s, expected < \(seconds)s",
            file: file,
            line: line
        )
        
        return result
    }
}

// MARK: - Custom Errors

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

// MARK: - Test Data Factories

enum TestDataFactory {
    
    static func sampleTexts() -> [String] {
        return [
            "Hello wrold! This is a quck test.",
            "The quck brown fox jumps over the lazy dog.",
            "I need to proces this text quickly.",
            "This text has som grammar issues that need fixing.",
            "Can you please fix the speling mistakes in this sentance?"
        ]
    }
    
    static func expectedRefinedTexts() -> [String] {
        return [
            "Hello world! This is a quick test.",
            "The quick brown fox jumps over the lazy dog.",
            "I need to process this text quickly.",
            "This text has some grammar issues that need fixing.",
            "Can you please fix the spelling mistakes in this sentence?"
        ]
    }
    
    static func longText() -> String {
        return String(repeating: "This is a long text that needs refinement. ", count: 100)
    }
    
    static func specialCharacterText() -> String {
        return "Text with émojis 🚀 and spécial characters: @#$%^&*()"
    }
} 