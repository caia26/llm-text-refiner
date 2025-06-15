import Foundation

// MARK: - Chat Message Models

struct ChatMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
    
    static func system(_ content: String) -> ChatMessage {
        return ChatMessage(role: "system", content: content)
    }
    
    static func user(_ content: String) -> ChatMessage {
        return ChatMessage(role: "user", content: content)
    }
    
    static func assistant(_ content: String) -> ChatMessage {
        return ChatMessage(role: "assistant", content: content)
    }
}

// MARK: - Chat Completion Request

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool
    
    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
    
    init(
        model: String,
        messages: [ChatMessage],
        temperature: Double? = 0.7,
        maxTokens: Int? = nil,
        stream: Bool = false
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stream = stream
    }
}

// MARK: - Chat Completion Response

struct ChatCompletionResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [ChatChoice]
    let usage: ChatUsage?
    
    struct ChatChoice: Codable {
        let index: Int?
        let message: ChatMessage?
        let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct ChatUsage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?
        
        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    /// Extracts the first assistant message content from the response
    var assistantMessage: String? {
        return choices.first?.message?.content
    }
}

// MARK: - API Error Response

struct APIErrorResponse: Codable {
    let error: APIError
    
    struct APIError: Codable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
}

// MARK: - LLM Service Errors

enum LLMServiceError: Error, LocalizedError {
    case invalidURL
    case noResponse
    case invalidResponse
    case networkError(Error)
    case serviceUnavailable
    case timeout
    case apiError(String)
    case decodingError(Error)
    case rateLimitExceeded
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .noResponse:
            return "No response received from the API"
        case .invalidResponse:
            return "Invalid response format from the API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serviceUnavailable:
            return "LLM service is currently unavailable"
        case .timeout:
            return "Request timed out"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
    
    /// Determines if the error is retryable
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serviceUnavailable, .rateLimitExceeded:
            return true
        case .invalidURL, .noResponse, .invalidResponse, .apiError, .decodingError, .authenticationFailed:
            return false
        }
    }
} 