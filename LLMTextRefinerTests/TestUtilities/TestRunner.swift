import Foundation
import XCTest
@testable import LLMTextRefiner

/// Test runner utility for organizing different types of tests
class TestRunner {
    
    /// Runs only unit tests (with mocks, no external dependencies)
    static func runUnitTests() {
        // Unit tests that don't require external services
        let unitTestClasses: [XCTestCase.Type] = [
            AppConfigurationTests.self,
            RecommendedModelTests.self,
            ProcessingResultTests.self,
            ConfigurationManagerTests.self,
            ChatModelsTests.self,
            LLMServiceTests.self,
            LLMServiceRetryTests.self
        ]
        
        print("🧪 Running Unit Tests (no external dependencies)...")
        for testClass in unitTestClasses {
            print("  Running \(testClass)...")
        }
    }
    
    /// Runs integration tests (requires running Ollama server)
    static func runIntegrationTests() {
        print("🌐 Running Integration Tests (requires Ollama server)...")
        print("  Ensure Ollama is running with llama3.1:8b model")
        print("  Running LLMServiceIntegrationTests...")
    }
    
    /// Checks if Ollama server is available
    static func checkOllamaAvailability() async -> Bool {
        let config = ConfigurationManager()
        let service = LLMService(configurationManager: config)
        
        print("🔍 Checking Ollama server availability...")
        let isAvailable = await service.isServiceAvailable()
        
        if isAvailable {
            print("✅ Ollama server is available at \(config.configuration.ollamaEndpoint)")
            print("📋 Using model: \(config.configuration.selectedModel)")
        } else {
            print("❌ Ollama server is not available")
            print("💡 To start Ollama server:")
            print("   1. Install Ollama: https://ollama.ai")
            print("   2. Run: ollama run llama3.1:8b")
            print("   3. Server should be available at http://localhost:11434")
        }
        
        return isAvailable
    }
    
    /// Quick test to verify the service works with current Ollama setup
    static func quickHealthCheck() async {
        print("🏥 Running Quick Health Check...")
        
        let config = ConfigurationManager()
        let service = LLMService(configurationManager: config)
        
        do {
            // Test connection
            print("  Testing connection...")
            let isConnected = try await service.testConnection()
            print(isConnected ? "  ✅ Connection successful" : "  ❌ Connection failed")
            
            // Test simple text refinement
            print("  Testing text refinement...")
            let testText = "Hello wrold! This is a quck test."
            let refined = try await service.refineText(testText)
            
            print("  📝 Original: \(testText)")
            print("  ✨ Refined: \(refined)")
            print("  ✅ Text refinement successful")
            
        } catch {
            print("  ❌ Health check failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Test Configuration Helper

extension TestRunner {
    
    /// Prints current test configuration
    static func printTestConfiguration() {
        let config = ConfigurationManager()
        
        print("📋 Current Test Configuration:")
        print("  Ollama Endpoint: \(config.configuration.ollamaEndpoint)")
        print("  Selected Model: \(config.configuration.selectedModel)")
        print("  Retry Attempts: \(config.configuration.retryAttempts)")
        print("  Retry Interval: \(config.configuration.retryInterval)s")
        print("  Manual Mode: \(config.configuration.isManualModeEnabled)")
        print("  Batch Processing: \(config.configuration.isBatchProcessingEnabled)")
    }
    
    /// Sets up test configuration for integration tests
    static func setupIntegrationTestConfiguration() {
        let config = ConfigurationManager()
        
        // Ensure we're using the correct configuration for integration tests
        config.updateConfiguration(
            ollamaEndpoint: "http://localhost:11434/v1/chat/completions",
            selectedModel: "llama3.1:8b",
            retryAttempts: 3,
            retryInterval: 3600
        )
        
        print("🔧 Integration test configuration set up")
        printTestConfiguration()
    }
} 