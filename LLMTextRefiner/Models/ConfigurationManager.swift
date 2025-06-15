import Foundation

class ConfigurationManager: ObservableObject {
    private static let configurationKey = "AppConfiguration"
    
    @Published var configuration: AppConfiguration
    
    init() {
        self.configuration = ConfigurationManager.load()
    }
    
    /// Load configuration from UserDefaults
    static func load() -> AppConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configurationKey),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return AppConfiguration() // Return default configuration
        }
        return config
    }
    
    /// Save configuration to UserDefaults
    func save(_ configuration: AppConfiguration) {
        self.configuration = configuration
        
        guard let data = try? JSONEncoder().encode(configuration) else {
            print("Failed to encode configuration")
            return
        }
        
        UserDefaults.standard.set(data, forKey: ConfigurationManager.configurationKey)
    }
    
    /// Reset configuration to default values
    func reset() {
        let defaultConfig = AppConfiguration()
        save(defaultConfig)
    }
    
    /// Update specific configuration properties
    func updateConfiguration(
        ollamaEndpoint: String? = nil,
        selectedModel: String? = nil,
        keyboardShortcut: String? = nil,
        isManualModeEnabled: Bool? = nil,
        isBatchProcessingEnabled: Bool? = nil,
        batchProcessingTime: Date? = nil,
        parentFolderPath: String? = nil,
        retryAttempts: Int? = nil,
        retryInterval: TimeInterval? = nil
    ) {
        let updatedConfig = AppConfiguration(
            ollamaEndpoint: ollamaEndpoint ?? configuration.ollamaEndpoint,
            selectedModel: selectedModel ?? configuration.selectedModel,
            keyboardShortcut: keyboardShortcut ?? configuration.keyboardShortcut,
            isManualModeEnabled: isManualModeEnabled ?? configuration.isManualModeEnabled,
            isBatchProcessingEnabled: isBatchProcessingEnabled ?? configuration.isBatchProcessingEnabled,
            batchProcessingTime: batchProcessingTime ?? configuration.batchProcessingTime,
            parentFolderPath: parentFolderPath ?? configuration.parentFolderPath,
            retryAttempts: retryAttempts ?? configuration.retryAttempts,
            retryInterval: retryInterval ?? configuration.retryInterval
        )
        
        save(updatedConfig)
    }
} 