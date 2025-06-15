import XCTest
@testable import LLMTextRefiner
import Foundation

class LLMServiceRetryTests: XCTestCase {
    
    var configurationManager: ConfigurationManager!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = ConfigurationManager()
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "http://localhost:11434/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private func createSuccessResponse() -> ChatCompletionResponse {
        return ChatCompletionResponse(
            id: "test-id",
            object: "chat.completion",
            created: 1234567890,
            model: "test-model",
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant("Success after retry"),
                    finishReason: "stop"
                )
            ],
            usage: nil
        )
    }
    
    // MARK: - Retry Mechanism Tests
    
    func testRetryOnNetworkError() async {
        // Given - Mock that fails twice then succeeds
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)),
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        let startTime = Date()
        
        // When
        let result = try! await service.refineText("Test text")
        let endTime = Date()
        
        // Then
        XCTAssertEqual(result, "Success after retry")
        XCTAssertEqual(mockSession.callCount, 3)
        
        // Verify exponential backoff timing (should take at least 3 seconds: 1s + 2s)
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThan(duration, 2.8) // Allow some tolerance
    }
    
    func testRetryOnServiceUnavailable() async {
        // Given - Mock that returns 503 twice then succeeds
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .httpError(503),
            .httpError(503),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try! await service.refineText("Test text")
        
        // Then
        XCTAssertEqual(result, "Success after retry")
        XCTAssertEqual(mockSession.callCount, 3)
    }
    
    func testRetryOnRateLimitExceeded() async {
        // Given - Mock that returns 429 twice then succeeds
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .httpError(429),
            .httpError(429),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try! await service.refineText("Test text")
        
        // Then
        XCTAssertEqual(result, "Success after retry")
        XCTAssertEqual(mockSession.callCount, 3)
    }
    
    func testMaxRetryAttemptsExceeded() async {
        // Given - Mock that always fails with retryable error
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .httpError(503),
            .httpError(503),
            .httpError(503),
            .httpError(503) // This should never be reached
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test text")
            XCTFail("Expected service to fail after max retries")
        } catch let error as LLMServiceError {
            XCTAssertEqual(error, .serviceUnavailable)
            XCTAssertEqual(mockSession.callCount, 3) // Should only try 3 times
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }
    
    func testNoRetryOnNonRetryableError() async {
        // Given - Mock that returns authentication error
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .httpError(401),
            .success(createSuccessResponse()) // This should never be reached
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test text")
            XCTFail("Expected service to fail immediately")
        } catch let error as LLMServiceError {
            XCTAssertEqual(error, .authenticationFailed)
            XCTAssertEqual(mockSession.callCount, 1) // Should only try once
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }
    
    func testRetryTimingExponentialBackoff() async {
        // Given - Mock that fails twice then succeeds
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)),
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        let startTime = Date()
        
        // When
        _ = try! await service.refineText("Test text")
        let endTime = Date()
        
        // Then - Should take approximately 1s + 2s = 3s total
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThan(duration, 2.8) // At least 2.8 seconds
        XCTAssertLessThan(duration, 4.0) // But not more than 4 seconds
    }
    
    func testRetryOnTimeout() async {
        // Given - Mock that times out twice then succeeds
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)),
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try! await service.refineText("Test text")
        
        // Then
        XCTAssertEqual(result, "Success after retry")
        XCTAssertEqual(mockSession.callCount, 3)
    }
    
    func testFirstAttemptSuccess() async {
        // Given - Mock that succeeds immediately
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        let startTime = Date()
        
        // When
        let result = try! await service.refineText("Test text")
        let endTime = Date()
        
        // Then
        XCTAssertEqual(result, "Success after retry")
        XCTAssertEqual(mockSession.callCount, 1)
        
        // Should complete quickly (no retry delays)
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 0.5)
    }
    
    func testTestConnectionRetry() async {
        // Given - Mock that fails once then succeeds for test connection
        let mockSession = RetryMockURLSession()
        mockSession.responses = [
            .httpError(503),
            .success(createSuccessResponse())
        ]
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try! await service.testConnection()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockSession.callCount, 2)
    }
}

// MARK: - Mock URLSession for Retry Testing

class RetryMockURLSession: URLSession {
    
    enum MockResponse {
        case success(ChatCompletionResponse)
        case failure(Error)
        case httpError(Int)
    }
    
    var responses: [MockResponse] = []
    var callCount = 0
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        defer { callCount += 1 }
        
        guard callCount < responses.count else {
            throw NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "No more mock responses"])
        }
        
        let response = responses[callCount]
        
        switch response {
        case .success(let chatResponse):
            let data = try JSONEncoder().encode(chatResponse)
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, httpResponse)
            
        case .failure(let error):
            throw error
            
        case .httpError(let statusCode):
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(), httpResponse)
        }
    }
} 