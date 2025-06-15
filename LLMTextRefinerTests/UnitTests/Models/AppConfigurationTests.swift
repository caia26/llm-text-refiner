import XCTest
@testable import LLMTextRefiner

class AppConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        // Given
        let config = AppConfiguration()
        
        // Then
        XCTAssertEqual(config.ollamaEndpoint, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(config.selectedModel, "llama3.1:8b")
        XCTAssertEqual(config.keyboardShortcut, "cmd+shift+r")
        XCTAssertTrue(config.isManualModeEnabled)
        XCTAssertTrue(config.isBatchProcessingEnabled)
        XCTAssertNil(config.parentFolderPath)
        XCTAssertEqual(config.retryAttempts, 3)
        XCTAssertEqual(config.retryInterval, 3600)
        
        // Check that batchProcessingTime is set to 9 PM
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: config.batchProcessingTime)
        XCTAssertEqual(components.hour, 21)
        XCTAssertEqual(components.minute, 0)
    }
    
    func testCustomConfiguration() {
        // Given
        let customEndpoint = "http://custom.endpoint.com"
        let customModel = "custom-model"
        let customShortcut = "cmd+alt+r"
        let customPath = "/custom/path"
        let customDate = Date()
        
        // When
        let config = AppConfiguration(
            ollamaEndpoint: customEndpoint,
            selectedModel: customModel,
            keyboardShortcut: customShortcut,
            isManualModeEnabled: false,
            isBatchProcessingEnabled: false,
            batchProcessingTime: customDate,
            parentFolderPath: customPath,
            retryAttempts: 5,
            retryInterval: 7200
        )
        
        // Then
        XCTAssertEqual(config.ollamaEndpoint, customEndpoint)
        XCTAssertEqual(config.selectedModel, customModel)
        XCTAssertEqual(config.keyboardShortcut, customShortcut)
        XCTAssertFalse(config.isManualModeEnabled)
        XCTAssertFalse(config.isBatchProcessingEnabled)
        XCTAssertEqual(config.batchProcessingTime, customDate)
        XCTAssertEqual(config.parentFolderPath, customPath)
        XCTAssertEqual(config.retryAttempts, 5)
        XCTAssertEqual(config.retryInterval, 7200)
    }
    
    func testCodableConformance() throws {
        // Given
        let originalConfig = AppConfiguration(
            ollamaEndpoint: "http://test.com",
            selectedModel: "test-model",
            keyboardShortcut: "cmd+t",
            isManualModeEnabled: false,
            isBatchProcessingEnabled: true,
            batchProcessingTime: Date(),
            parentFolderPath: "/test/path",
            retryAttempts: 2,
            retryInterval: 1800
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalConfig)
        let decodedConfig = try JSONDecoder().decode(AppConfiguration.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedConfig.ollamaEndpoint, originalConfig.ollamaEndpoint)
        XCTAssertEqual(decodedConfig.selectedModel, originalConfig.selectedModel)
        XCTAssertEqual(decodedConfig.keyboardShortcut, originalConfig.keyboardShortcut)
        XCTAssertEqual(decodedConfig.isManualModeEnabled, originalConfig.isManualModeEnabled)
        XCTAssertEqual(decodedConfig.isBatchProcessingEnabled, originalConfig.isBatchProcessingEnabled)
        XCTAssertEqual(decodedConfig.batchProcessingTime.timeIntervalSince1970, 
                      originalConfig.batchProcessingTime.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(decodedConfig.parentFolderPath, originalConfig.parentFolderPath)
        XCTAssertEqual(decodedConfig.retryAttempts, originalConfig.retryAttempts)
        XCTAssertEqual(decodedConfig.retryInterval, originalConfig.retryInterval)
    }
} 