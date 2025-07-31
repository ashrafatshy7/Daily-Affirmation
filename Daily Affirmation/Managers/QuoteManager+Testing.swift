import Foundation

// MARK: - Testing Support
extension QuoteManager {
    
    // Check if we're running in a test environment
    private var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               NSClassFromString("XCTestCase") != nil
    }
    
    // MARK: - Test Support
    private static var currentTestUserDefaults: UserDefaults?
    private static var currentTestIdentifier: String?
    
    static func getTestUserDefaults() -> UserDefaults {
        // Use call stack to identify the current test method
        let stackTrace = Thread.callStackSymbols
        var testMethodName = "unknown"
        
        // Look for test method in call stack
        for frame in stackTrace {
            if frame.contains("test") && frame.contains("[") && frame.contains("]") {
                // Extract test method name from stack frame
                if let range = frame.range(of: "test"),
                   let endRange = frame.range(of: "]", range: range.upperBound..<frame.endIndex) {
                    testMethodName = String(frame[range.lowerBound..<endRange.lowerBound])
                    break
                }
            }
        }
        
        // Always create fresh UserDefaults for each test method
        if currentTestIdentifier != testMethodName {
            currentTestIdentifier = testMethodName
            // Add timestamp to ensure unique storage even if test methods have same name
            let testSuiteName = "QuoteManagerTest_\(testMethodName)_\(Date().timeIntervalSince1970)"
            currentTestUserDefaults = UserDefaults(suiteName: testSuiteName)
            
            // Clear any existing data to ensure clean slate
            currentTestUserDefaults?.removePersistentDomain(forName: testSuiteName)
            currentTestUserDefaults = UserDefaults(suiteName: testSuiteName)
        }
        
        return currentTestUserDefaults!
    }
    
    static func createTestInstance() -> QuoteManager {
        // Create a unique UserDefaults suite for this test instance
        let testSuiteName = "QuoteManagerTest_\(UUID().uuidString)"
        let testUserDefaults = UserDefaults(suiteName: testSuiteName)!
        return QuoteManager(loadFromDefaults: false, userDefaults: testUserDefaults)
    }
}