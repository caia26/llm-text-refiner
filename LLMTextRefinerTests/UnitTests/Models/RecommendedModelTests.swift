import XCTest
@testable import LLMTextRefiner

class RecommendedModelTests: XCTestCase {
    
    func testModelTierEnum() {
        // Test all cases exist
        XCTAssertEqual(ModelTier.allCases.count, 3)
        XCTAssertTrue(ModelTier.allCases.contains(.recommended))
        XCTAssertTrue(ModelTier.allCases.contains(.alternative))
        XCTAssertTrue(ModelTier.allCases.contains(.advanced))
        
        // Test raw values
        XCTAssertEqual(ModelTier.recommended.rawValue, "recommended")
        XCTAssertEqual(ModelTier.alternative.rawValue, "alternative")
        XCTAssertEqual(ModelTier.advanced.rawValue, "advanced")
    }
    
    func testRecommendedModelInitialization() {
        // Given
        let name = "llama3.1:8b"
        let displayName = "Llama 3.1 8B"
        let description = "A powerful 8 billion parameter model"
        let tier = ModelTier.recommended
        let estimatedRAM = "8GB"
        let installCommand = "ollama pull llama3.1:8b"
        
        // When
        let model = RecommendedModel(
            name: name,
            displayName: displayName,
            description: description,
            tier: tier,
            estimatedRAM: estimatedRAM,
            installCommand: installCommand
        )
        
        // Then
        XCTAssertEqual(model.name, name)
        XCTAssertEqual(model.displayName, displayName)
        XCTAssertEqual(model.description, description)
        XCTAssertEqual(model.tier, tier)
        XCTAssertEqual(model.estimatedRAM, estimatedRAM)
        XCTAssertEqual(model.installCommand, installCommand)
    }
    
    func testRecommendedModelCodable() throws {
        // Given
        let originalModel = RecommendedModel(
            name: "mistral:7b",
            displayName: "Mistral 7B",
            description: "Efficient 7B parameter model",
            tier: .alternative,
            estimatedRAM: "7GB",
            installCommand: "ollama pull mistral:7b"
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalModel)
        let decodedModel = try JSONDecoder().decode(RecommendedModel.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedModel.name, originalModel.name)
        XCTAssertEqual(decodedModel.displayName, originalModel.displayName)
        XCTAssertEqual(decodedModel.description, originalModel.description)
        XCTAssertEqual(decodedModel.tier, originalModel.tier)
        XCTAssertEqual(decodedModel.estimatedRAM, originalModel.estimatedRAM)
        XCTAssertEqual(decodedModel.installCommand, originalModel.installCommand)
    }
    
    func testModelTierCodable() throws {
        // Test encoding/decoding each tier
        for tier in ModelTier.allCases {
            // When
            let encodedData = try JSONEncoder().encode(tier)
            let decodedTier = try JSONDecoder().decode(ModelTier.self, from: encodedData)
            
            // Then
            XCTAssertEqual(decodedTier, tier)
        }
    }
    
    func testMultipleModelsWithDifferentTiers() {
        // Given
        let recommendedModel = RecommendedModel(
            name: "llama3.1:8b",
            displayName: "Llama 3.1 8B",
            description: "Recommended model",
            tier: .recommended,
            estimatedRAM: "8GB",
            installCommand: "ollama pull llama3.1:8b"
        )
        
        let alternativeModel = RecommendedModel(
            name: "mistral:7b",
            displayName: "Mistral 7B",
            description: "Alternative model",
            tier: .alternative,
            estimatedRAM: "7GB",
            installCommand: "ollama pull mistral:7b"
        )
        
        let advancedModel = RecommendedModel(
            name: "llama3.1:70b",
            displayName: "Llama 3.1 70B",
            description: "Advanced model",
            tier: .advanced,
            estimatedRAM: "64GB",
            installCommand: "ollama pull llama3.1:70b"
        )
        
        // Then
        XCTAssertEqual(recommendedModel.tier, .recommended)
        XCTAssertEqual(alternativeModel.tier, .alternative)
        XCTAssertEqual(advancedModel.tier, .advanced)
        
        XCTAssertNotEqual(recommendedModel.name, alternativeModel.name)
        XCTAssertNotEqual(alternativeModel.name, advancedModel.name)
    }
} 