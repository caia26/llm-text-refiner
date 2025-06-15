import Foundation

protocol LLMServiceProtocol {
    func refineText(_ text: String) async throws -> String
    func testConnection() async throws -> Bool
    func isServiceAvailable() async -> Bool
}

class LLMService: LLMServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let configurationManager: ConfigurationManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // Constants
    private static let requestTimeout: TimeInterval = 30.0
    private static let maxRetryAttempts = 3
    private static let baseRetryInterval: TimeInterval = 1.0
    
    // Refinement prompt template
    private static let refinementPrompt = """
    You are a text refinement assistant. Clean up the following text by correcting grammar, improving clarity, and fixing any voice dictation errors. Maintain the original meaning and tone. Return only the refined text without explanations.
    """
    
    // MARK: - Initialization
    
    init(configurationManager: ConfigurationManager, session: URLSession = .shared) {
        self.configurationManager = configurationManager
        
        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.requestTimeout
        config.timeoutIntervalForResource = Self.requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Refines the given text using the configured LLM
    func refineText(_ text: String) async throws -> String {
        let messages = [
            ChatMessage.system(Self.refinementPrompt),
            ChatMessage.user(text)
        ]
        
        let request = ChatCompletionRequest(
            model: configurationManager.configuration.selectedModel,
            messages: messages,
            temperature: 0.7,
            stream: false
        )
        
        let response = try await performRequestWithRetry { [weak self] in
            try await self?.performChatCompletion(request: request)
        }
        
        guard let refinedText = response?.assistantMessage, !refinedText.isEmpty else {
            throw LLMServiceError.invalidResponse
        }
        
        return refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Tests connection to the LLM service
    func testConnection() async throws -> Bool {
        let testMessages = [
            ChatMessage.system("You are a helpful assistant."),
            ChatMessage.user("Hello, are you working?")
        ]
        
        let request = ChatCompletionRequest(
            model: configurationManager.configuration.selectedModel,
            messages: testMessages,
            temperature: 0.1,
            stream: false
        )
        
        do {
            let response = try await performChatCompletion(request: request)
            return response.choices.first?.message?.content != nil
        } catch {
            throw error
        }
    }
    
    /// Checks if the service is available (without throwing)
    func isServiceAvailable() async -> Bool {
        do {
            return try await testConnection()
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Performs a chat completion request
    private func performChatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        guard let url = URL(string: configurationManager.configuration.ollamaEndpoint) else {
            throw LLMServiceError.invalidURL
        }
        
        // Create HTTP request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Encode request body
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw LLMServiceError.decodingError(error)
        }
        
        // Perform request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401, 403:
                throw LLMServiceError.authenticationFailed
            case 429:
                throw LLMServiceError.rateLimitExceeded
            case 500...599:
                throw LLMServiceError.serviceUnavailable
            default:
                // Try to parse error response
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw LLMServiceError.apiError(errorResponse.error.message)
                } else {
                    throw LLMServiceError.invalidResponse
                }
            }
        }
        
        // Decode response
        do {
            let chatResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
            return chatResponse
        } catch {
            throw LLMServiceError.decodingError(error)
        }
    }
    
    /// Performs a request with retry logic
    private func performRequestWithRetry<T>(
        operation: @escaping () async throws -> T?
    ) async throws -> T? {
        var lastError: Error?
        
        for attempt in 1...Self.maxRetryAttempts {
            do {
                return try await operation()
            } catch let error as LLMServiceError {
                lastError = error
                
                // Don't retry if error is not retryable
                guard error.isRetryable else {
                    throw error
                }
                
                // Don't retry on last attempt
                guard attempt < Self.maxRetryAttempts else {
                    throw error
                }
                
                // Calculate exponential backoff delay
                let delay = Self.baseRetryInterval * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = error
                
                // Wrap unknown errors
                let wrappedError = LLMServiceError.networkError(error)
                
                // Don't retry on last attempt
                guard attempt < Self.maxRetryAttempts else {
                    throw wrappedError
                }
                
                // Retry network errors
                let delay = Self.baseRetryInterval * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // This should never be reached, but just in case
        throw lastError ?? LLMServiceError.noResponse
    }
}

// MARK: - Extensions

extension LLMService {
    /// Convenience method to create a service with shared configuration
    static func shared(with configManager: ConfigurationManager) -> LLMService {
        return LLMService(configurationManager: configManager)
    }
} 