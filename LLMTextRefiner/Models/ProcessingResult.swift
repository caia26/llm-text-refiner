import Foundation

enum ProcessingError: Error, Codable {
    case llmUnavailable
    case networkTimeout
    case invalidResponse
    case clipboardError
    case fileError(String)
    
    var localizedDescription: String {
        switch self {
        case .llmUnavailable:
            return "LLM service is currently unavailable"
        case .networkTimeout:
            return "Network request timed out"
        case .invalidResponse:
            return "Received invalid response from LLM service"
        case .clipboardError:
            return "Failed to access clipboard"
        case .fileError(let message):
            return "File error: \(message)"
        }
    }
}

enum ProcessingResult: Codable {
    case success(originalText: String, refinedText: String)
    case failure(error: ProcessingError)
    case queued(retryAttempt: Int)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure, .queued:
            return false
        }
    }
    
    var refinedText: String? {
        switch self {
        case .success(_, let refinedText):
            return refinedText
        case .failure, .queued:
            return nil
        }
    }
} 