import XCTest
@testable import LLMTextRefiner
import Foundation

/// Integration tests that require a running Ollama server
/// These tests will be skipped if the server is not available
class LLMServiceIntegrationTests: XCTestCase {
    
    var configurationManager: ConfigurationManager!
    var llmService: LLMService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Clear UserDefaults and set up fresh configuration
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = ConfigurationManager()
        llmService = LLMService(configurationManager: configurationManager)
        
        // Skip tests if Ollama server is not available
        let isAvailable = await llmService.isServiceAvailable()
        if !isAvailable {
            throw XCTSkip("Ollama server is not available. Start Ollama server to run integration tests.")
        }
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = nil
        llmService = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testRealServerConnection() async throws {
        // When
        let isConnected = try await llmService.testConnection()
        
        // Then
        XCTAssertTrue(isConnected, "Should be able to connect to Ollama server")
    }
    
    func testServiceAvailability() async {
        // When
        let isAvailable = await llmService.isServiceAvailable()
        
        // Then
        XCTAssertTrue(isAvailable, "Ollama service should be available")
    }
    
    // MARK: - Text Refinement Tests
    
    func testRealTextRefinement() async throws {
        // Given
        let originalText = "Hello wrold! This is a tets message with some erors."
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Refined text should not be empty")
        XCTAssertNotEqual(refinedText, originalText, "Refined text should be different from original")
        
        // The refined text should fix the obvious errors
        XCTAssertTrue(refinedText.contains("world") || refinedText.contains("World"), "Should fix 'wrold' to 'world'")
        XCTAssertTrue(refinedText.contains("test") || refinedText.contains("Test"), "Should fix 'tets' to 'test'")
        XCTAssertTrue(refinedText.contains("errors") || refinedText.contains("error"), "Should fix 'erors' to 'errors'")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    func testTextRefinementPreservesLength() async throws {
        // Given
        let originalText = "This is a well-written sentence that shouldn't need much refinement."
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Refined text should not be empty")
        
        // For well-written text, the refined version should be similar in length
        let lengthDifference = abs(refinedText.count - originalText.count)
        XCTAssertLessThan(lengthDifference, originalText.count / 2, "Refined text length should be reasonably similar")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    func testVoiceDictationErrorFixing() async throws {
        // Given - Common voice dictation errors
        let originalText = "I went to the store and bought sum apples. Their really good!"
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Refined text should not be empty")
        XCTAssertNotEqual(refinedText, originalText, "Refined text should be different from original")
        
        // Should fix common homophones
        let lowerRefined = refinedText.lowercased()
        XCTAssertTrue(lowerRefined.contains("some"), "Should fix 'sum' to 'some'")
        XCTAssertTrue(lowerRefined.contains("they're") || lowerRefined.contains("they are"), "Should fix 'their' to 'they're'")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    func testLongTextRefinement() async throws {
        // Given
        let originalText = """
        This is a longer text that contains several issues. First, they're are some gramatical errors. 
        Second, the punctuation is sometimes incorect, Third the capitalization might be rong in places.
        Overall, this text needs alot of improvements to make it more profesional and redable.
        """
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Refined text should not be empty")
        XCTAssertNotEqual(refinedText, originalText, "Refined text should be different from original")
        
        // Should be roughly similar length but improved
        let lengthRatio = Double(refinedText.count) / Double(originalText.count)
        XCTAssertTrue(lengthRatio > 0.7 && lengthRatio < 1.5, "Refined text should be reasonably similar in length")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    func testEmptyTextHandling() async throws {
        // Given
        let originalText = ""
        
        // When/Then
        do {
            let refinedText = try await llmService.refineText(originalText)
            // If it doesn't throw, the result should not be empty or should be meaningful
            if !refinedText.isEmpty {
                print("Service returned for empty input: '\(refinedText)'")
            }
        } catch let error as LLMServiceError {
            // It's acceptable for the service to reject empty input
            XCTAssertTrue([.invalidResponse, .apiError].contains { type in
                switch (error, type) {
                case (.invalidResponse, .invalidResponse), (.apiError, .apiError):
                    return true
                default:
                    return false
                }
            }, "Should handle empty input gracefully")
        }
    }
    
    func testVeryShortTextRefinement() async throws {
        // Given
        let originalText = "helo"
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Refined text should not be empty")
        
        // Should fix the obvious typo
        let lowerRefined = refinedText.lowercased()
        XCTAssertTrue(lowerRefined.contains("hello"), "Should fix 'helo' to 'hello'")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    // MARK: - Performance Tests
    
    func testRefinementPerformance() async throws {
        // Given
        let originalText = "This is a test message with some minor erors that need fixing."
        let startTime = Date()
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        let endTime = Date()
        
        // Then
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertFalse(refinedText.isEmpty, "Should return refined text")
        XCTAssertLessThan(duration, 30.0, "Should complete within 30 seconds")
        
        print("Refinement took \(String(format: "%.2f", duration)) seconds")
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    // MARK: - Configuration Tests
    
    func testWithCustomConfiguration() async throws {
        // Given - Update to use specific model
        configurationManager.updateConfiguration(
            selectedModel: "llama3.1:8b",
            ollamaEndpoint: "http://localhost:11434/v1/chat/completions"
        )
        
        let originalText = "This is a tets with the custom confguration."
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Should return refined text")
        XCTAssertNotEqual(refinedText, originalText, "Should improve the text")
        
        print("Original: \(originalText)")
        print("Refined: \(refinedText)")
    }
    
    func testWithInvalidEndpoint() async throws {
        // Given - Invalid endpoint
        configurationManager.updateConfiguration(ollamaEndpoint: "http://localhost:99999/invalid")
        let invalidService = LLMService(configurationManager: configurationManager)
        
        // When/Then
        do {
            _ = try await invalidService.refineText("Test")
            XCTFail("Should fail with invalid endpoint")
        } catch let error as LLMServiceError {
            // Should get a network error or service unavailable
            XCTAssertTrue([LLMServiceError.networkError, LLMServiceError.serviceUnavailable].contains { type in
                switch (error, type) {
                case (.networkError, .networkError), (.serviceUnavailable, .serviceUnavailable):
                    return true
                default:
                    return false
                }
            }, "Should fail with appropriate network error")
        }
    }
    
    // MARK: - Stress Tests
    
    func testMultipleConcurrentRequests() async throws {
        // Given
        let testTexts = [
            "This is the frist test message.",
            "Here is the secnd test message.",
            "And this is the thrid test message.",
            "Finally, the forth test message."
        ]
        
        // When - Send multiple concurrent requests
        let startTime = Date()
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for text in testTexts {
                group.addTask {
                    try await self.llmService.refineText(text)
                }
            }
            
            var refinedTexts: [String] = []
            for try await result in group {
                refinedTexts.append(result)
            }
            return refinedTexts
        }
        let endTime = Date()
        
        // Then
        XCTAssertEqual(results.count, testTexts.count, "Should get all results")
        
        for (index, result) in results.enumerated() {
            XCTAssertFalse(result.isEmpty, "Result \(index) should not be empty")
            print("Original \(index): \(testTexts[index])")
            print("Refined \(index): \(result)")
        }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        print("Concurrent requests completed in \(String(format: "%.2f", totalDuration)) seconds")
    }
    
    // MARK: - Real-world Scenarios
    
    func testEmailTextRefinement() async throws {
        // Given - Simulated email text with common issues
        let originalText = """
        hi john,
        
        i wanted to follow up on our meeting yesterday. their were a few points that i think we should discus further.
        
        1. the project timeline - its quite agressive
        2. budget constraints - we might need more resources
        3. team coordination - communication has been abit challenging
        
        let me know when your available to chat about these items.
        
        thanks,
        alex
        """
        
        // When
        let refinedText = try await llmService.refineText(originalText)
        
        // Then
        XCTAssertFalse(refinedText.isEmpty, "Should return refined text")
        XCTAssertNotEqual(refinedText, originalText, "Should improve the email")
        
        // Should improve capitalization and grammar
        let lowerRefined = refinedText.lowercased()
        XCTAssertTrue(lowerRefined.contains("there were") || lowerRefined.contains("there are"), "Should fix 'their were'")
        XCTAssertTrue(lowerRefined.contains("discuss"), "Should fix 'discus'")
        XCTAssertTrue(lowerRefined.contains("you're") || lowerRefined.contains("you are"), "Should fix 'your'")
        
        print("Original email:")
        print(originalText)
        print("\nRefined email:")
        print(refinedText)
    }
} 