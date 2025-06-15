import Foundation

struct AppConfiguration: Codable {
    let ollamaEndpoint: String
    let selectedModel: String
    let keyboardShortcut: String
    let isManualModeEnabled: Bool
    let isBatchProcessingEnabled: Bool
    let batchProcessingTime: Date
    let parentFolderPath: String?
    let retryAttempts: Int
    let retryInterval: TimeInterval
    
    init(
        ollamaEndpoint: String = "http://localhost:11434/v1/chat/completions",
        selectedModel: String = "llama3.1:8b",
        keyboardShortcut: String = "cmd+shift+r",
        isManualModeEnabled: Bool = true,
        isBatchProcessingEnabled: Bool = true,
        batchProcessingTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
        parentFolderPath: String? = nil,
        retryAttempts: Int = 3,
        retryInterval: TimeInterval = 3600
    ) {
        self.ollamaEndpoint = ollamaEndpoint
        self.selectedModel = selectedModel
        self.keyboardShortcut = keyboardShortcut
        self.isManualModeEnabled = isManualModeEnabled
        self.isBatchProcessingEnabled = isBatchProcessingEnabled
        self.batchProcessingTime = batchProcessingTime
        self.parentFolderPath = parentFolderPath
        self.retryAttempts = retryAttempts
        self.retryInterval = retryInterval
    }
} 