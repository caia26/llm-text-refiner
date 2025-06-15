import Foundation
@testable import LLMTextRefiner

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

// MARK: - Mock URLSessionDataTask

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

// MARK: - Mock Response Helpers

extension MockURLSession {
    
    /// Create a successful HTTP response with data
    static func success(data: Data, statusCode: Int = 200) -> MockURLSession {
        let response = HTTPURLResponse(
            url: URL(string: "http://localhost:11434/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        return MockURLSession(data: data, response: response, error: nil)
    }
    
    /// Create a failed HTTP response with error
    static func failure(error: Error) -> MockURLSession {
        return MockURLSession(data: nil, response: nil, error: error)
    }
    
    /// Create a HTTP response with specific status code and optional error data
    static func httpError(statusCode: Int, errorData: Data? = nil) -> MockURLSession {
        let response = HTTPURLResponse(
            url: URL(string: "http://localhost:11434/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        return MockURLSession(data: errorData, response: response, error: nil)
    }
    
    /// Create a network timeout error
    static func timeout() -> MockURLSession {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        return MockURLSession(data: nil, response: nil, error: error)
    }
    
    /// Create a network connection error
    static func networkError() -> MockURLSession {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        return MockURLSession(data: nil, response: nil, error: error)
    }
} 