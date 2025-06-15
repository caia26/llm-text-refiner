import XCTest
@testable import LLMTextRefiner

class ConfigurationManagerTests: XCTestCase {
    
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
    
    func testInitializationWithDefaultConfiguration() {
        // Given - fresh ConfigurationManager
        let manager = ConfigurationManager()
        
        // Then - Should load default configuration
        XCTAssertEqual(manager.configuration.ollamaEndpoint, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(manager.configuration.selectedModel, "llama3.1:8b")
        XCTAssertEqual(manager.configuration.keyboardShortcut, "cmd+shift+r")
        XCTAssertTrue(manager.configuration.isManualModeEnabled)
        XCTAssertTrue(manager.configuration.isBatchProcessingEnabled)
        XCTAssertNil(manager.configuration.parentFolderPath)
        XCTAssertEqual(manager.configuration.retryAttempts, 3)
        XCTAssertEqual(manager.configuration.retryInterval, 3600)
    }
    
    func testSaveAndLoadConfiguration() {
        // Given
        let customConfig = AppConfiguration(
            ollamaEndpoint: "http://custom.endpoint.com",
            selectedModel: "custom-model",
            keyboardShortcut: "cmd+alt+r",
            isManualModeEnabled: false,
            isBatchProcessingEnabled: false,
            batchProcessingTime: Date(),
            parentFolderPath: "/custom/path",
            retryAttempts: 5,
            retryInterval: 7200
        )
        
        // When
        configurationManager.save(customConfig)
        
        // Then - Current configuration should be updated
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, customConfig.ollamaEndpoint)
        XCTAssertEqual(configurationManager.configuration.selectedModel, customConfig.selectedModel)
        XCTAssertEqual(configurationManager.configuration.keyboardShortcut, customConfig.keyboardShortcut)
        XCTAssertEqual(configurationManager.configuration.isManualModeEnabled, customConfig.isManualModeEnabled)
        XCTAssertEqual(configurationManager.configuration.isBatchProcessingEnabled, customConfig.isBatchProcessingEnabled)
        XCTAssertEqual(configurationManager.configuration.parentFolderPath, customConfig.parentFolderPath)
        XCTAssertEqual(configurationManager.configuration.retryAttempts, customConfig.retryAttempts)
        XCTAssertEqual(configurationManager.configuration.retryInterval, customConfig.retryInterval)
        
        // When - Create new manager to test persistence
        let newManager = ConfigurationManager()
        
        // Then - Should load saved configuration
        XCTAssertEqual(newManager.configuration.ollamaEndpoint, customConfig.ollamaEndpoint)
        XCTAssertEqual(newManager.configuration.selectedModel, customConfig.selectedModel)
        XCTAssertEqual(newManager.configuration.keyboardShortcut, customConfig.keyboardShortcut)
        XCTAssertEqual(newManager.configuration.isManualModeEnabled, customConfig.isManualModeEnabled)
        XCTAssertEqual(newManager.configuration.isBatchProcessingEnabled, customConfig.isBatchProcessingEnabled)
        XCTAssertEqual(newManager.configuration.parentFolderPath, customConfig.parentFolderPath)
        XCTAssertEqual(newManager.configuration.retryAttempts, customConfig.retryAttempts)
        XCTAssertEqual(newManager.configuration.retryInterval, customConfig.retryInterval)
    }
    
    func testResetConfiguration() {
        // Given - Save custom configuration first
        let customConfig = AppConfiguration(
            ollamaEndpoint: "http://custom.endpoint.com",
            selectedModel: "custom-model"
        )
        configurationManager.save(customConfig)
        
        // Verify custom config is saved
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, "http://custom.endpoint.com")
        
        // When
        configurationManager.reset()
        
        // Then - Should revert to default configuration
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(configurationManager.configuration.selectedModel, "llama3.1:8b")
        XCTAssertEqual(configurationManager.configuration.keyboardShortcut, "cmd+shift+r")
        XCTAssertTrue(configurationManager.configuration.isManualModeEnabled)
        XCTAssertTrue(configurationManager.configuration.isBatchProcessingEnabled)
        XCTAssertNil(configurationManager.configuration.parentFolderPath)
        XCTAssertEqual(configurationManager.configuration.retryAttempts, 3)
        XCTAssertEqual(configurationManager.configuration.retryInterval, 3600)
    }
    
    func testUpdateConfigurationPartially() {
        // Given - Initial default configuration
        let initialEndpoint = configurationManager.configuration.ollamaEndpoint
        let initialModel = configurationManager.configuration.selectedModel
        
        // When - Update only endpoint
        configurationManager.updateConfiguration(ollamaEndpoint: "http://updated.endpoint.com")
        
        // Then - Only endpoint should change
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, "http://updated.endpoint.com")
        XCTAssertEqual(configurationManager.configuration.selectedModel, initialModel) // Should remain unchanged
        
        // When - Update only model
        configurationManager.updateConfiguration(selectedModel: "updated-model")
        
        // Then - Endpoint should remain updated, model should change
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, "http://updated.endpoint.com")
        XCTAssertEqual(configurationManager.configuration.selectedModel, "updated-model")
    }
    
    func testUpdateConfigurationMultipleProperties() {
        // Given
        let newEndpoint = "http://multi.update.com"
        let newModel = "multi-model"
        let newShortcut = "cmd+m"
        let newRetryAttempts = 10
        
        // When
        configurationManager.updateConfiguration(
            ollamaEndpoint: newEndpoint,
            selectedModel: newModel,
            keyboardShortcut: newShortcut,
            retryAttempts: newRetryAttempts
        )
        
        // Then
        XCTAssertEqual(configurationManager.configuration.ollamaEndpoint, newEndpoint)
        XCTAssertEqual(configurationManager.configuration.selectedModel, newModel)
        XCTAssertEqual(configurationManager.configuration.keyboardShortcut, newShortcut)
        XCTAssertEqual(configurationManager.configuration.retryAttempts, newRetryAttempts)
        
        // Other properties should remain at default values
        XCTAssertTrue(configurationManager.configuration.isManualModeEnabled)
        XCTAssertTrue(configurationManager.configuration.isBatchProcessingEnabled)
        XCTAssertEqual(configurationManager.configuration.retryInterval, 3600)
    }
    
    func testStaticLoadMethod() {
        // Given - No saved configuration
        XCTAssertNil(UserDefaults.standard.data(forKey: "AppConfiguration"))
        
        // When
        let loadedConfig = ConfigurationManager.load()
        
        // Then - Should return default configuration
        XCTAssertEqual(loadedConfig.ollamaEndpoint, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(loadedConfig.selectedModel, "llama3.1:8b")
        
        // Given - Save custom configuration
        let customConfig = AppConfiguration(ollamaEndpoint: "http://static.test.com")
        let data = try! JSONEncoder().encode(customConfig)
        UserDefaults.standard.set(data, forKey: "AppConfiguration")
        
        // When
        let loadedCustomConfig = ConfigurationManager.load()
        
        // Then - Should return saved configuration
        XCTAssertEqual(loadedCustomConfig.ollamaEndpoint, "http://static.test.com")
    }
    
    func testCorruptedDataHandling() {
        // Given - Corrupted data in UserDefaults
        let corruptedData = "not json data".data(using: .utf8)!
        UserDefaults.standard.set(corruptedData, forKey: "AppConfiguration")
        
        // When
        let manager = ConfigurationManager()
        
        // Then - Should fallback to default configuration
        XCTAssertEqual(manager.configuration.ollamaEndpoint, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(manager.configuration.selectedModel, "llama3.1:8b")
    }
} 