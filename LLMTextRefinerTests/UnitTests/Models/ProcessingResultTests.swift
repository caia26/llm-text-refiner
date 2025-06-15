import XCTest
@testable import LLMTextRefiner

class ProcessingResultTests: XCTestCase {
    
    func testProcessingErrorLocalizedDescription() {
        // Test all error cases have proper descriptions
        XCTAssertEqual(ProcessingError.llmUnavailable.localizedDescription, "LLM service is currently unavailable")
        XCTAssertEqual(ProcessingError.networkTimeout.localizedDescription, "Network request timed out")
        XCTAssertEqual(ProcessingError.invalidResponse.localizedDescription, "Received invalid response from LLM service")
        XCTAssertEqual(ProcessingError.clipboardError.localizedDescription, "Failed to access clipboard")
        
        let fileErrorMessage = "File not found"
        XCTAssertEqual(ProcessingError.fileError(fileErrorMessage).localizedDescription, "File error: \(fileErrorMessage)")
    }
    
    func testProcessingErrorCodable() throws {
        let errors: [ProcessingError] = [
            .llmUnavailable,
            .networkTimeout,
            .invalidResponse,
            .clipboardError,
            .fileError("Test error message")
        ]
        
        for error in errors {
            // When
            let encodedData = try JSONEncoder().encode(error)
            let decodedError = try JSONDecoder().decode(ProcessingError.self, from: encodedData)
            
            // Then
            XCTAssertEqual(decodedError.localizedDescription, error.localizedDescription)
        }
    }
    
    func testProcessingResultSuccess() {
        // Given
        let originalText = "Hello world"
        let refinedText = "Hello, world!"
        
        // When
        let result = ProcessingResult.success(originalText: originalText, refinedText: refinedText)
        
        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.refinedText, refinedText)
        
        // Test pattern matching
        switch result {
        case .success(let original, let refined):
            XCTAssertEqual(original, originalText)
            XCTAssertEqual(refined, refinedText)
        default:
            XCTFail("Expected success case")
        }
    }
    
    func testProcessingResultFailure() {
        // Given
        let error = ProcessingError.networkTimeout
        
        // When
        let result = ProcessingResult.failure(error: error)
        
        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.refinedText)
        
        // Test pattern matching
        switch result {
        case .failure(let resultError):
            XCTAssertEqual(resultError.localizedDescription, error.localizedDescription)
        default:
            XCTFail("Expected failure case")
        }
    }
    
    func testProcessingResultQueued() {
        // Given
        let retryAttempt = 2
        
        // When
        let result = ProcessingResult.queued(retryAttempt: retryAttempt)
        
        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.refinedText)
        
        // Test pattern matching
        switch result {
        case .queued(let attempt):
            XCTAssertEqual(attempt, retryAttempt)
        default:
            XCTFail("Expected queued case")
        }
    }
    
    func testProcessingResultCodable() throws {
        let results: [ProcessingResult] = [
            .success(originalText: "Original", refinedText: "Refined"),
            .failure(error: .llmUnavailable),
            .queued(retryAttempt: 3)
        ]
        
        for result in results {
            // When
            let encodedData = try JSONEncoder().encode(result)
            let decodedResult = try JSONDecoder().decode(ProcessingResult.self, from: encodedData)
            
            // Then
            XCTAssertEqual(decodedResult.isSuccess, result.isSuccess)
            XCTAssertEqual(decodedResult.refinedText, result.refinedText)
        }
    }
    
    func testProcessingResultHelperProperties() {
        // Test success case
        let successResult = ProcessingResult.success(originalText: "test", refinedText: "refined test")
        XCTAssertTrue(successResult.isSuccess)
        XCTAssertEqual(successResult.refinedText, "refined test")
        
        // Test failure case
        let failureResult = ProcessingResult.failure(error: .invalidResponse)
        XCTAssertFalse(failureResult.isSuccess)
        XCTAssertNil(failureResult.refinedText)
        
        // Test queued case
        let queuedResult = ProcessingResult.queued(retryAttempt: 1)
        XCTAssertFalse(queuedResult.isSuccess)
        XCTAssertNil(queuedResult.refinedText)
    }
    
    func testProcessingErrorFileErrorWithDifferentMessages() {
        let messages = ["File not found", "Permission denied", "Disk full"]
        
        for message in messages {
            let error = ProcessingError.fileError(message)
            XCTAssertEqual(error.localizedDescription, "File error: \(message)")
        }
    }
} 