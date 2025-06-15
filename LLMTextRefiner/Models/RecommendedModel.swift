import Foundation

enum ModelTier: String, CaseIterable, Codable {
    case recommended
    case alternative
    case advanced
}

struct RecommendedModel: Codable {
    let name: String
    let displayName: String
    let description: String
    let tier: ModelTier
    let estimatedRAM: String
    let installCommand: String
    
    init(
        name: String,
        displayName: String,
        description: String,
        tier: ModelTier,
        estimatedRAM: String,
        installCommand: String
    ) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.tier = tier
        self.estimatedRAM = estimatedRAM
        self.installCommand = installCommand
    }
} 