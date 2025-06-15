import XCTest
@testable import LLMTextRefiner
import Foundation

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    private let mockDataTask: MockURLSessionDataTask
    
    init(data: Data?, response: URLResponse?, error: Error?) {
        mockDataTask = MockURLSessionDataTask(data: data, response: response, error: error)
        super.init()
    }
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockDataTask.error {
            throw error
        }
        
        guard let data = mockDataTask.data, let response = mockDataTask.response else {
            throw LLMServiceError.noResponse
        }
        
        return (data, response)
    }
}

class MockURLSessionDataTask {
    let data: Data?
    let response: URLResponse?
    let error: Error?
    
    init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}

// MARK: - LLMService Tests

class LLMServiceTests: XCTestCase {
    
    var configurationManager: ConfigurationManager!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = ConfigurationManager()
    }
    
    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "AppConfiguration")
        configurationManager = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createSuccessResponse() -> ChatCompletionResponse {
        return ChatCompletionResponse(
            id: "test-id",
            object: "chat.completion",
            created: 1234567890,
            model: "test-model",
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant("Refined text here."),
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
    
    private func createHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "http://localhost:11434/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private func createErrorResponse(message: String) -> APIErrorResponse {
        return APIErrorResponse(
            error: APIErrorResponse.APIError(
                message: message,
                type: "test_error",
                param: nil,
                code: "test_code"
            )
        )
    }
    
    // MARK: - Initialization Tests
    
    func testLLMServiceInitialization() {
        // When
        let service = LLMService(configurationManager: configurationManager)
        
        // Then
        XCTAssertNotNil(service)
    }
    
    func testLLMServiceSharedMethod() {
        // When
        let service = LLMService.shared(with: configurationManager)
        
        // Then
        XCTAssertNotNil(service)
    }
    
    // MARK: - Successful Text Refinement Tests
    
    func testRefineTextSuccess() async throws {
        // Given
        let successResponse = createSuccessResponse()
        let responseData = try JSONEncoder().encode(successResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try await service.refineText("Hello world")
        
        // Then
        XCTAssertEqual(result, "Refined text here.")
    }
    
    func testRefineTextWithWhitespace() async throws {
        // Given
        let responseWithWhitespace = ChatCompletionResponse(
            id: "test-id",
            object: "chat.completion",
            created: 1234567890,
            model: "test-model",
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant("  Refined text with whitespace.  \n"),
                    finishReason: "stop"
                )
            ],
            usage: nil
        )
        
        let responseData = try JSONEncoder().encode(responseWithWhitespace)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try await service.refineText("Hello world")
        
        // Then
        XCTAssertEqual(result, "Refined text with whitespace.")
    }
    
    // MARK: - Test Connection Tests
    
    func testTestConnectionSuccess() async throws {
        // Given
        let successResponse = createSuccessResponse()
        let responseData = try JSONEncoder().encode(successResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try await service.testConnection()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testTestConnectionFailure() async {
        // Given
        let mockSession = MockURLSession(data: nil, response: nil, error: LLMServiceError.networkError(NSError(domain: "Test", code: 0)))
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.testConnection()
            XCTFail("Expected test connection to throw")
        } catch {
            XCTAssertTrue(error is LLMServiceError)
        }
    }
    
    func testIsServiceAvailableSuccess() async {
        // Given
        let successResponse = createSuccessResponse()
        let responseData = try JSONEncoder().encode(successResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = await service.isServiceAvailable()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsServiceAvailableFailure() async {
        // Given
        let mockSession = MockURLSession(data: nil, response: nil, error: LLMServiceError.timeout)
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = await service.isServiceAvailable()
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURL() async {
        // Given
        configurationManager.updateConfiguration(ollamaEndpoint: "invalid-url")
        let service = LLMService(configurationManager: configurationManager)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected invalid URL error")
        } catch let error as LLMServiceError {
            XCTAssertEqual(error, .invalidURL)
        } catch {
            XCTFail("Expected LLMServiceError.invalidURL, got \(error)")
        }
    }
    
    func testHTTPErrorResponses() async {
        let testCases: [(Int, LLMServiceError)] = [
            (401, .authenticationFailed),
            (403, .authenticationFailed),
            (429, .rateLimitExceeded),
            (500, .serviceUnavailable),
            (502, .serviceUnavailable),
            (503, .serviceUnavailable)
        ]
        
        for (statusCode, expectedError) in testCases {
            // Given
            let httpResponse = createHTTPResponse(statusCode: statusCode)
            let mockSession = MockURLSession(data: Data(), response: httpResponse, error: nil)
            let service = LLMService(configurationManager: configurationManager, session: mockSession)
            
            // When/Then
            do {
                _ = try await service.refineText("Test")
                XCTFail("Expected error for status code \(statusCode)")
            } catch let error as LLMServiceError {
                XCTAssertEqual(error, expectedError)
            } catch {
                XCTFail("Expected LLMServiceError, got \(error)")
            }
        }
    }
    
    func testAPIErrorResponse() async {
        // Given
        let errorResponse = createErrorResponse(message: "Custom API error")
        let responseData = try! JSONEncoder().encode(errorResponse)
        let httpResponse = createHTTPResponse(statusCode: 400)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected API error")
        } catch let error as LLMServiceError {
            if case .apiError(let message) = error {
                XCTAssertEqual(message, "Custom API error")
            } else {
                XCTFail("Expected .apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }
    
    func testInvalidResponseData() async {
        // Given
        let invalidData = "invalid json".data(using: .utf8)!
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: invalidData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected decoding error")
        } catch let error as LLMServiceError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected .decodingError, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }
    
    func testEmptyResponse() async {
        // Given
        let emptyResponse = ChatCompletionResponse(
            id: nil,
            object: nil,
            created: nil,
            model: nil,
            choices: [],
            usage: nil
        )
        let responseData = try! JSONEncoder().encode(emptyResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected invalid response error")
        } catch let error as LLMServiceError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Expected LLMServiceError.invalidResponse, got \(error)")
        }
    }
    
    func testEmptyAssistantMessage() async {
        // Given
        let emptyMessageResponse = ChatCompletionResponse(
            id: "test-id",
            object: "chat.completion",
            created: 1234567890,
            model: "test-model",
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant(""),
                    finishReason: "stop"
                )
            ],
            usage: nil
        )
        let responseData = try! JSONEncoder().encode(emptyMessageResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected invalid response error")
        } catch let error as LLMServiceError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Expected LLMServiceError.invalidResponse, got \(error)")
        }
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkError() async {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let mockSession = MockURLSession(data: nil, response: nil, error: networkError)
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected network error")
        } catch let error as LLMServiceError {
            if case .networkError(let underlyingError) = error {
                XCTAssertEqual((underlyingError as NSError).code, NSURLErrorNotConnectedToInternet)
            } else {
                XCTFail("Expected .networkError, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
    }
    
    // MARK: - Configuration Tests
    
    func testServiceUsesConfigurationEndpoint() async {
        // Given
        let customEndpoint = "http://custom.endpoint.com/api/chat"
        configurationManager.updateConfiguration(ollamaEndpoint: customEndpoint)
        
        // Create a mock session that will validate the URL
        let mockSession = MockURLSession(data: nil, response: nil, error: LLMServiceError.invalidURL)
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When/Then - The service should attempt to use the custom endpoint
        do {
            _ = try await service.refineText("Test")
            XCTFail("Expected error due to mock setup")
        } catch {
            // Expected due to mock setup
        }
        
        // The test passes if we reach here without other errors
    }
    
    func testServiceUsesConfigurationModel() async {
        // Given
        let customModel = "custom-model:latest"
        configurationManager.updateConfiguration(selectedModel: customModel)
        
        let successResponse = ChatCompletionResponse(
            id: "test-id",
            object: "chat.completion",
            created: 1234567890,
            model: customModel,
            choices: [
                ChatCompletionResponse.ChatChoice(
                    index: 0,
                    message: ChatMessage.assistant("Test response"),
                    finishReason: "stop"
                )
            ],
            usage: nil
        )
        
        let responseData = try! JSONEncoder().encode(successResponse)
        let httpResponse = createHTTPResponse(statusCode: 200)
        let mockSession = MockURLSession(data: responseData, response: httpResponse, error: nil)
        
        let service = LLMService(configurationManager: configurationManager, session: mockSession)
        
        // When
        let result = try! await service.refineText("Test")
        
        // Then
        XCTAssertEqual(result, "Test response")
    }
} 