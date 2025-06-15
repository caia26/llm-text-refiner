import XCTest
@testable import LLMTextRefiner

class ChatModelsTests: XCTestCase {
    
    // MARK: - ChatMessage Tests
    
    func testChatMessageInitialization() {
        // Given
        let role = "user"
        let content = "Hello, world!"
        
        // When
        let message = ChatMessage(role: role, content: content)
        
        // Then
        XCTAssertEqual(message.role, role)
        XCTAssertEqual(message.content, content)
    }
    
    func testChatMessageStaticMethods() {
        // Test system message
        let systemMessage = ChatMessage.system("You are a helpful assistant.")
        XCTAssertEqual(systemMessage.role, "system")
        XCTAssertEqual(systemMessage.content, "You are a helpful assistant.")
        
        // Test user message
        let userMessage = ChatMessage.user("Hello!")
        XCTAssertEqual(userMessage.role, "user")
        XCTAssertEqual(userMessage.content, "Hello!")
        
        // Test assistant message
        let assistantMessage = ChatMessage.assistant("Hello! How can I help you?")
        XCTAssertEqual(assistantMessage.role, "assistant")
        XCTAssertEqual(assistantMessage.content, "Hello! How can I help you?")
    }
    
    func testChatMessageCodable() throws {
        // Given
        let originalMessage = ChatMessage(role: "user", content: "Test message")
        
        // When
        let encodedData = try JSONEncoder().encode(originalMessage)
        let decodedMessage = try JSONDecoder().decode(ChatMessage.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedMessage.role, originalMessage.role)
        XCTAssertEqual(decodedMessage.content, originalMessage.content)
    }
    
    // MARK: - ChatCompletionRequest Tests
    
    func testChatCompletionRequestInitialization() {
        // Given
        let model = "llama3.1:8b"
        let messages = [ChatMessage.user("Hello")]
        
        // When
        let request = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: 0.8,
            maxTokens: 100,
            stream: false
        )
        
        // Then
        XCTAssertEqual(request.model, model)
        XCTAssertEqual(request.messages.count, 1)
        XCTAssertEqual(request.messages.first?.content, "Hello")
        XCTAssertEqual(request.temperature, 0.8)
        XCTAssertEqual(request.maxTokens, 100)
        XCTAssertFalse(request.stream)
    }
    
    func testChatCompletionRequestDefaults() {
        // Given
        let model = "test-model"
        let messages = [ChatMessage.user("Test")]
        
        // When
        let request = ChatCompletionRequest(model: model, messages: messages)
        
        // Then
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertNil(request.maxTokens)
        XCTAssertFalse(request.stream)
    }
    
    func testChatCompletionRequestCodable() throws {
        // Given
        let originalRequest = ChatCompletionRequest(
            model: "test-model",
            messages: [ChatMessage.user("Test")],
            temperature: 0.5,
            maxTokens: 50,
            stream: true
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalRequest)
        let decodedRequest = try JSONDecoder().decode(ChatCompletionRequest.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedRequest.model, originalRequest.model)
        XCTAssertEqual(decodedRequest.messages.count, originalRequest.messages.count)
        XCTAssertEqual(decodedRequest.temperature, originalRequest.temperature)
        XCTAssertEqual(decodedRequest.maxTokens, originalRequest.maxTokens)
        XCTAssertEqual(decodedRequest.stream, originalRequest.stream)
    }
    
    func testChatCompletionRequestCodingKeys() throws {
        // Given
        let request = ChatCompletionRequest(
            model: "test-model",
            messages: [ChatMessage.user("Test")],
            maxTokens: 100
        )
        
        // When
        let encodedData = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encodedData) as! [String: Any]
        
        // Then - Verify snake_case conversion
        XCTAssertNotNil(json["max_tokens"])
        XCTAssertNil(json["maxTokens"])
    }
    
    // MARK: - ChatCompletionResponse Tests
    
    func testChatCompletionResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1677652288,
            "model": "llama3.1:8b",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Hello! How can I assist you today?"
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 9,
                "completion_tokens": 12,
                "total_tokens": 21
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.id, "chatcmpl-123")
        XCTAssertEqual(response.object, "chat.completion")
        XCTAssertEqual(response.created, 1677652288)
        XCTAssertEqual(response.model, "llama3.1:8b")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices.first?.index, 0)
        XCTAssertEqual(response.choices.first?.message?.role, "assistant")
        XCTAssertEqual(response.choices.first?.message?.content, "Hello! How can I assist you today?")
        XCTAssertEqual(response.choices.first?.finishReason, "stop")
        XCTAssertEqual(response.usage?.promptTokens, 9)
        XCTAssertEqual(response.usage?.completionTokens, 12)
        XCTAssertEqual(response.usage?.totalTokens, 21)
    }
    
    func testChatCompletionResponseAssistantMessage() throws {
        // Given
        let jsonString = """
        {
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "This is the response"
                    }
                }
            ]
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.assistantMessage, "This is the response")
    }
    
    func testChatCompletionResponseEmptyChoices() throws {
        // Given
        let jsonString = """
        {
            "choices": []
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
        
        // Then
        XCTAssertNil(response.assistantMessage)
    }
    
    // MARK: - APIErrorResponse Tests
    
    func testAPIErrorResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "error": {
                "message": "Invalid API key provided",
                "type": "invalid_request_error",
                "param": "api_key",
                "code": "invalid_api_key"
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(errorResponse.error.message, "Invalid API key provided")
        XCTAssertEqual(errorResponse.error.type, "invalid_request_error")
        XCTAssertEqual(errorResponse.error.param, "api_key")
        XCTAssertEqual(errorResponse.error.code, "invalid_api_key")
    }
    
    // MARK: - LLMServiceError Tests
    
    func testLLMServiceErrorDescriptions() {
        let errors: [(LLMServiceError, String)] = [
            (.invalidURL, "Invalid API endpoint URL"),
            (.noResponse, "No response received from the API"),
            (.invalidResponse, "Invalid response format from the API"),
            (.serviceUnavailable, "LLM service is currently unavailable"),
            (.timeout, "Request timed out"),
            (.apiError("Custom error"), "API error: Custom error"),
            (.rateLimitExceeded, "Rate limit exceeded"),
            (.authenticationFailed, "Authentication failed")
        ]
        
        for (error, expectedDescription) in errors {
            XCTAssertEqual(error.errorDescription, expectedDescription)
        }
    }
    
    func testLLMServiceErrorNetworkError() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let serviceError = LLMServiceError.networkError(underlyingError)
        
        // Then
        XCTAssertEqual(serviceError.errorDescription, "Network error: Test error")
    }
    
    func testLLMServiceErrorDecodingError() {
        // Given
        let underlyingError = NSError(domain: "DecodingDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Decoding failed"])
        let serviceError = LLMServiceError.decodingError(underlyingError)
        
        // Then
        XCTAssertEqual(serviceError.errorDescription, "Failed to decode response: Decoding failed")
    }
    
    func testLLMServiceErrorRetryability() {
        // Retryable errors
        let retryableErrors: [LLMServiceError] = [
            .networkError(NSError(domain: "Test", code: 0)),
            .timeout,
            .serviceUnavailable,
            .rateLimitExceeded
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "Expected \(error) to be retryable")
        }
        
        // Non-retryable errors
        let nonRetryableErrors: [LLMServiceError] = [
            .invalidURL,
            .noResponse,
            .invalidResponse,
            .apiError("Test"),
            .decodingError(NSError(domain: "Test", code: 0)),
            .authenticationFailed
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "Expected \(error) to not be retryable")
        }
    }
} 