import Foundation
import XCTest

// MARK: - Test Configuration

enum TestConfiguration {
    
    // MARK: - Environment Configuration
    
    static let ollamaEndpoint = "http://localhost:11434/v1/chat/completions"
    static let testModel = "phi3:mini" // Faster model for testing when available
    static let defaultModel = "llama3.1:8b" // Fallback to default model
    
    // MARK: - Test Flags
    
    static let enableIntegrationTests = ProcessInfo.processInfo.environment["ENABLE_INTEGRATION_TESTS"] == "true"
    static let enableE2ETests = ProcessInfo.processInfo.environment["ENABLE_E2E_TESTS"] == "true"
    static let enablePerformanceTests = ProcessInfo.processInfo.environment["ENABLE_PERFORMANCE_TESTS"] == "true"
    static let verboseLogging = ProcessInfo.processInfo.environment["VERBOSE_TEST_LOGGING"] == "true"
    
    // MARK: - Test Timeouts
    
    static let defaultTimeout: TimeInterval = 10.0
    static let networkTimeout: TimeInterval = 30.0
    static let integrationTimeout: TimeInterval = 60.0
    static let performanceTimeout: TimeInterval = 5.0
    
    // MARK: - Test Requirements
    
    static func requiresOllama() throws {
        guard enableIntegrationTests else {
            throw XCTSkip("Integration tests require ENABLE_INTEGRATION_TESTS=true")
        }
    }
    
    static func requiresE2E() throws {
        guard enableE2ETests else {
            throw XCTSkip("End-to-end tests require ENABLE_E2E_TESTS=true")
        }
    }
    
    static func requiresPerformance() throws {
        guard enablePerformanceTests else {
            throw XCTSkip("Performance tests require ENABLE_PERFORMANCE_TESTS=true")
        }
    }
    
    // MARK: - Service Availability
    
    static func checkOllamaAvailability() async -> Bool {
        let url = URL(string: ollamaEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        
        // Simple test request
        let testRequest = [
            "model": testModel,
            "messages": [["role": "user", "content": "test"]],
            "max_tokens": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testRequest)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500 // Accept client errors but not server errors
            }
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - Test Environment Info
    
    static func printEnvironmentInfo() {
        print("🔧 Test Environment Configuration:")
        print("   📡 Ollama Endpoint: \(ollamaEndpoint)")
        print("   🤖 Test Model: \(testModel)")
        print("   🚀 Integration Tests: \(enableIntegrationTests ? "✅" : "❌")")
        print("   🔄 E2E Tests: \(enableE2ETests ? "✅" : "❌")")
        print("   ⚡ Performance Tests: \(enablePerformanceTests ? "✅" : "❌")")
        print("   📝 Verbose Logging: \(verboseLogging ? "✅" : "❌")")
        print()
    }
    
    // MARK: - Test Data Configuration
    
    static let testTexts = [
        "Hello wrold! This is a quck test.",
        "The quck brown fox jumps over the lazy dog.",
        "I need to proces this text quickly."
    ]
    
    static let expectedRefinedTexts = [
        "Hello world! This is a quick test.",
        "The quick brown fox jumps over the lazy dog.",
        "I need to process this text quickly."
    ]
    
    // MARK: - Mock Configuration
    
    static func createTestConfiguration() -> AppConfiguration {
        return AppConfiguration(
            ollamaEndpoint: ollamaEndpoint,
            selectedModel: testModel,
            keyboardShortcut: "cmd+shift+t", // Different from default for testing
            isManualModeEnabled: true,
            isBatchProcessingEnabled: false, // Simplified for testing
            batchProcessingTime: Date(),
            parentFolderPath: nil,
            retryAttempts: 2, // Fewer retries for faster tests
            retryInterval: 1.0 // Shorter interval for faster tests
        )
    }
}

// MARK: - Test Skip Helpers

extension XCTestCase {
    
    func skipUnlessIntegrationEnabled() throws {
        try TestConfiguration.requiresOllama()
    }
    
    func skipUnlessE2EEnabled() throws {
        try TestConfiguration.requiresE2E()
    }
    
    func skipUnlessPerformanceEnabled() throws {
        try TestConfiguration.requiresPerformance()
    }
    
    func skipUnlessOllamaAvailable() async throws {
        try TestConfiguration.requiresOllama()
        
        let available = await TestConfiguration.checkOllamaAvailability()
        guard available else {
            throw XCTSkip("Ollama service is not available at \(TestConfiguration.ollamaEndpoint)")
        }
    }
}

// MARK: - Logging Helpers

enum TestLogger {
    
    static func log(_ message: String, category: String = "TEST") {
        if TestConfiguration.verboseLogging {
            print("[\(category)] \(message)")
        }
    }
    
    static func logIntegration(_ message: String) {
        log(message, category: "INTEGRATION")
    }
    
    static func logPerformance(_ message: String) {
        log(message, category: "PERFORMANCE")
    }
    
    static func logE2E(_ message: String) {
        log(message, category: "E2E")
    }
    
    static func logMock(_ message: String) {
        log(message, category: "MOCK")
    }
}

// MARK: - Test Environment Variables Guide

/*
 Set these environment variables to control test execution:
 
 Integration Tests (requires Ollama running):
 ENABLE_INTEGRATION_TESTS=true
 
 End-to-End Tests (full user workflows):
 ENABLE_E2E_TESTS=true
 
 Performance Tests (timing-sensitive):
 ENABLE_PERFORMANCE_TESTS=true
 
 Verbose Logging:
 VERBOSE_TEST_LOGGING=true
 
 Example Xcode scheme environment variables:
 ENABLE_INTEGRATION_TESTS = true
 ENABLE_PERFORMANCE_TESTS = true
 VERBOSE_TEST_LOGGING = true
 
 Example command line:
 ENABLE_INTEGRATION_TESTS=true VERBOSE_TEST_LOGGING=true xcodebuild test -scheme LLMTextRefiner
 */ 