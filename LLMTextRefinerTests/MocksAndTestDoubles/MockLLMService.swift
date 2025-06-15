import Foundation
@testable import LLMTextRefiner

// MARK: - LLM Service Protocol

protocol LLMServiceProtocol {
    func refineText(_ text: String) async throws -> String
    func testConnection() async throws -> Bool
    func isServiceAvailable() async -> Bool
}

// MARK: - LLMService Extension

extension LLMService: LLMServiceProtocol {}

// MARK: - Mock LLM Service

final class MockLLMService: LLMServiceProtocol {
    
    // MARK: - Call Tracking
    
    var refineTextCalled = false
    var testConnectionCalled = false
    var isServiceAvailableCalled = false
    
    var refineTextCallCount = 0
    var testConnectionCallCount = 0
    var isServiceAvailableCallCount = 0
    
    var lastRefinedText: String?
    
    // MARK: - Configuration
    
    var refinedText = "Mocked refined text"
    var shouldThrowError = false
    var connectionResult = true
    var serviceAvailable = true
    var errorToThrow: Error = LLMServiceError.serviceUnavailable
    
    // MARK: - Advanced Configuration
    
    var refinementResults: [String] = []
    var currentResultIndex = 0
    
    var shouldFailAfterAttempts: Int? = nil
    var currentAttempt = 0
    
    var processingDelay: TimeInterval = 0
    
    // MARK: - Method Implementations
    
    func refineText(_ text: String) async throws -> String {
        refineTextCalled = true
        refineTextCallCount += 1
        lastRefinedText = text
        currentAttempt += 1
        
        // Add delay if configured
        if processingDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        }
        
        // Check if should fail after attempts
        if let failAfter = shouldFailAfterAttempts, currentAttempt >= failAfter {
            throw errorToThrow
        }
        
        // Throw error if configured
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Return from results array if available
        if !refinementResults.isEmpty {
            let result = refinementResults[currentResultIndex % refinementResults.count]
            currentResultIndex += 1
            return result
        }
        
        return refinedText
    }
    
    func testConnection() async throws -> Bool {
        testConnectionCalled = true
        testConnectionCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return connectionResult
    }
    
    func isServiceAvailable() async -> Bool {
        isServiceAvailableCalled = true
        isServiceAvailableCallCount += 1
        return serviceAvailable
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        refineTextCalled = false
        testConnectionCalled = false
        isServiceAvailableCalled = false
        
        refineTextCallCount = 0
        testConnectionCallCount = 0
        isServiceAvailableCallCount = 0
        
        lastRefinedText = nil
        currentResultIndex = 0
        currentAttempt = 0
        
        // Reset to defaults
        refinedText = "Mocked refined text"
        shouldThrowError = false
        connectionResult = true
        serviceAvailable = true
        errorToThrow = LLMServiceError.serviceUnavailable
        shouldFailAfterAttempts = nil
        processingDelay = 0
        refinementResults = []
    }
    
    func setRefinementResults(_ results: [String]) {
        refinementResults = results
        currentResultIndex = 0
    }
    
    func setError(_ error: Error, throwAfterAttempts: Int? = 0) {
        errorToThrow = error
        shouldThrowError = throwAfterAttempts == 0
        shouldFailAfterAttempts = throwAfterAttempts
        currentAttempt = 0
    }
}

// MARK: - Mock Factory

extension MockLLMService {
    
    static func successful(withResult result: String = "Refined text") -> MockLLMService {
        let mock = MockLLMService()
        mock.refinedText = result
        mock.connectionResult = true
        mock.serviceAvailable = true
        return mock
    }
    
    static func failing(withError error: Error = LLMServiceError.serviceUnavailable) -> MockLLMService {
        let mock = MockLLMService()
        mock.shouldThrowError = true
        mock.errorToThrow = error
        mock.connectionResult = false
        mock.serviceAvailable = false
        return mock
    }
    
    static func unavailable() -> MockLLMService {
        let mock = MockLLMService()
        mock.serviceAvailable = false
        mock.connectionResult = false
        return mock
    }
    
    static func withDelay(_ delay: TimeInterval) -> MockLLMService {
        let mock = MockLLMService()
        mock.processingDelay = delay
        return mock
    }
} 