import Foundation

// MARK: - Data Persistence
extension QuoteManager {
    
    // MARK: - Settings Persistence
    func saveSettings() {
        userDefaults.set(dailyNotifications, forKey: "dailyNotifications")
        userDefaults.set(startTime, forKey: "startTime")
        userDefaults.set(endTime, forKey: "endTime")
        userDefaults.set(singleNotificationTime, forKey: "singleNotificationTime")
        userDefaults.set(notificationCount, forKey: "notificationCount")
        userDefaults.set(notificationMode.rawValue, forKey: "notificationMode")
        userDefaults.set(fontSize.rawValue, forKey: "fontSize")
        userDefaults.set(selectedBackgroundImage, forKey: "selectedBackgroundImage")
        userDefaults.set(includePersonalQuotes, forKey: "includePersonalQuotes")
        userDefaults.set(personalQuoteFrequencyMultiplier, forKey: "personalQuoteFrequencyMultiplier")
        userDefaults.set(selectedCategory.rawValue, forKey: "selectedCategory")
    }
    
    func loadSettings() {
        dailyNotifications = userDefaults.bool(forKey: "dailyNotifications")
        
        if let savedFontSize = FontSize(rawValue: userDefaults.string(forKey: "fontSize") ?? "") {
            fontSize = savedFontSize
        }
        
        let savedBackgroundImage = userDefaults.string(forKey: "selectedBackgroundImage") ?? "background"
        selectedBackgroundImage = savedBackgroundImage
        
        // Load notification times if available
        if let savedStartTime = userDefaults.object(forKey: "startTime") as? Date {
            startTime = savedStartTime
        }
        
        if let savedEndTime = userDefaults.object(forKey: "endTime") as? Date {
            endTime = savedEndTime
        }
        
        // Load single notification time if available
        if let savedSingleTime = userDefaults.object(forKey: "singleNotificationTime") as? Date {
            singleNotificationTime = savedSingleTime
        }
        
        // Load notification count if available
        if userDefaults.object(forKey: "notificationCount") != nil {
            notificationCount = userDefaults.integer(forKey: "notificationCount")
            // Ensure count is at least 1
            if notificationCount < 1 {
                notificationCount = 1
            }
        }
        
        // Load notification mode if available
        if let savedMode = NotificationMode(rawValue: userDefaults.string(forKey: "notificationMode") ?? "") {
            notificationMode = savedMode
        }
        
        // Load include personal quotes setting (defaults to true if not set)
        if userDefaults.object(forKey: "includePersonalQuotes") != nil {
            includePersonalQuotes = userDefaults.bool(forKey: "includePersonalQuotes")
        } else {
            includePersonalQuotes = true
        }
        
        // Load personal quote frequency multiplier (defaults to 2.0 if not set)
        if userDefaults.object(forKey: "personalQuoteFrequencyMultiplier") != nil {
            personalQuoteFrequencyMultiplier = userDefaults.double(forKey: "personalQuoteFrequencyMultiplier")
            // Ensure the value is within valid range (1.0 - 5.0)
            personalQuoteFrequencyMultiplier = max(1.0, min(5.0, personalQuoteFrequencyMultiplier))
        } else {
            personalQuoteFrequencyMultiplier = 2.0
        }
        
        // Load selected category (defaults to general if not set)
        if let savedCategoryString = userDefaults.string(forKey: "selectedCategory"),
           let savedCategory = QuoteCategory(rawValue: savedCategoryString) {
            selectedCategory = savedCategory
        } else {
            selectedCategory = .general
        }
        
        // If notifications were enabled, check permission and schedule
        if dailyNotifications {
            checkNotificationPermissionAndSchedule()
        }
    }
    
    // MARK: - Loved Quotes Management
    func toggleLoveQuote(_ quote: String) {
        if Thread.isMainThread {
            var newLovedQuotes = self.lovedQuotes
            if newLovedQuotes.contains(quote) {
                newLovedQuotes.remove(quote)
            } else {
                newLovedQuotes.insert(quote)
            }
            self.lovedQuotes = newLovedQuotes
        } else {
            DispatchQueue.main.sync {
                var newLovedQuotes = self.lovedQuotes
                if newLovedQuotes.contains(quote) {
                    newLovedQuotes.remove(quote)
                } else {
                    newLovedQuotes.insert(quote)
                }
                self.lovedQuotes = newLovedQuotes
            }
        }
    }
    
    func isQuoteLoved(_ quote: String) -> Bool {
        return lovedQuotes.contains(quote)
    }
    
    var lovedQuotesArray: [String] {
        return Array(lovedQuotes).sorted()
    }
    
    func saveLovedQuotes() {
        let lovedQuotesArray = Array(lovedQuotes)
        
        // Encode each quote using Base64 to preserve special characters
        let encodedQuotes = lovedQuotesArray.map { encodeQuoteForStorage($0) }
        
        // Save the encoded array to UserDefaults (this replaces existing data)
        userDefaults.set(encodedQuotes, forKey: "lovedQuotes")
        userDefaults.synchronize() // Force immediate synchronization
    }
    
    func loadLovedQuotes() {
        guard let savedArray = userDefaults.array(forKey: "lovedQuotes") as? [String] else {
            // No saved data, start with empty set
            let wasInitializing = isInitializing
            isInitializing = true
            lovedQuotes = Set<String>()
            isInitializing = wasInitializing
            return
        }
        
        var decodedQuotes: [String] = []
        var needsMigration = false
        var failedDecodingCount = 0
        
        for savedQuote in savedArray {
            if isBase64Encoded(savedQuote) {
                // This is an encoded quote, decode it
                let decodedQuote = decodeQuoteFromStorage(savedQuote)
                if decodedQuote != savedQuote { // Successfully decoded (different from input)
                    decodedQuotes.append(decodedQuote)
                } else {
                    // Decoding failed, treat as raw quote
                    decodedQuotes.append(savedQuote)
                    needsMigration = true
                    failedDecodingCount += 1
                }
            } else {
                // This is a raw quote (old format), keep as-is but mark for migration
                decodedQuotes.append(savedQuote)
                needsMigration = true
            }
        }
        
        // Set the loaded quotes
        let wasInitializing = isInitializing
        isInitializing = true
        lovedQuotes = Set(decodedQuotes)
        isInitializing = wasInitializing
        
        // If we found old format data, migrate it to new format
        if needsMigration {
            saveLovedQuotes()
        }
    }
    
    // MARK: - Encoding Utilities for Special Characters
    private func encodeQuoteForStorage(_ quote: String) -> String {
        guard let data = quote.data(using: .utf8) else { return quote }
        return data.base64EncodedString()
    }
    
    private func decodeQuoteFromStorage(_ encodedQuote: String) -> String {
        guard let data = Data(base64Encoded: encodedQuote),
              let decodedString = String(data: data, encoding: .utf8) else {
            // If Base64 decoding fails, return the original string (backward compatibility)
            return encodedQuote
        }
        return decodedString
    }
    
    private func isBase64Encoded(_ string: String) -> Bool {
        // More strict Base64 detection to avoid false positives
        guard string.count > 8, // Minimum reasonable length for Base64 encoded text
              string.count % 4 == 0 else { // Base64 must be multiple of 4
            return false
        }
        
        // Check for Base64 character set
        let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        guard string.rangeOfCharacter(from: base64CharacterSet.inverted) == nil else {
            return false
        }
        
        // Verify it's actually valid Base64 by trying to decode it
        guard let data = Data(base64Encoded: string),
              let decodedString = String(data: data, encoding: .utf8),
              !decodedString.isEmpty else {
            return false
        }
        
        // Additional check: the decoded string should look like a quote (reasonable length and characters)
        return decodedString.count > 3 && decodedString.count < 10000
    }
    
    // MARK: - Personal Quotes Management    
    func addPersonalQuote(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && trimmedText.count >= 4 && trimmedText.count <= 50 else {
            return false
        }
        
        let newQuote = PersonalQuote(text: trimmedText)
        
        if Thread.isMainThread {
            personalQuotes.append(newQuote)
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes.append(newQuote)
            }
        }
        return true
    }
    
    func deletePersonalQuote(withId id: UUID) {
        if Thread.isMainThread {
            personalQuotes.removeAll { $0.id == id }
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes.removeAll { $0.id == id }
            }
        }
    }
    
    func updatePersonalQuote(withId id: UUID, newText: String) -> Bool {
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && trimmedText.count >= 4 && trimmedText.count <= 50 else {
            return false
        }
        
        if Thread.isMainThread {
            if let index = personalQuotes.firstIndex(where: { $0.id == id }) {
                personalQuotes[index].text = trimmedText
                // Update quote bag directly for immediate consistency
                quoteBag.updateQuote(withId: id, newText: trimmedText)
                return true
            }
        } else {
            return DispatchQueue.main.sync {
                if let index = self.personalQuotes.firstIndex(where: { $0.id == id }) {
                    self.personalQuotes[index].text = trimmedText
                    // Update quote bag directly for immediate consistency
                    self.quoteBag.updateQuote(withId: id, newText: trimmedText)
                    return true
                }
                return false
            }
        }
        return false
    }
    
    func togglePersonalQuoteActive(withId id: UUID) {
        if Thread.isMainThread {
            if let index = personalQuotes.firstIndex(where: { $0.id == id }) {
                personalQuotes[index].isActive.toggle()
            }
        } else {
            DispatchQueue.main.sync {
                if let index = self.personalQuotes.firstIndex(where: { $0.id == id }) {
                    self.personalQuotes[index].isActive.toggle()
                }
            }
        }
    }
    
    var activePersonalQuotes: [PersonalQuote] {
        return personalQuotes.filter { $0.isActive }
    }
    
    var sortedPersonalQuotes: [PersonalQuote] {
        return personalQuotes.sorted { $0.createdDate > $1.createdDate }
    }
    
    func savePersonalQuotes() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(personalQuotes)
            
            // Encode the data using Base64 to preserve special characters
            let encodedData = data.base64EncodedString()
            
            userDefaults.set(encodedData, forKey: "personalQuotes")
            userDefaults.synchronize()
        } catch {
            print("Failed to save personal quotes: \(error)")
        }
    }
    
    func loadPersonalQuotes() {
        guard let encodedData = userDefaults.string(forKey: "personalQuotes") else {
            // No saved data, start with empty array
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = []
            isInitializing = wasInitializing
            return
        }
        
        do {
            // Decode the Base64 data
            guard let data = Data(base64Encoded: encodedData) else {
                print("Failed to decode personal quotes data")
                personalQuotes = []
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedQuotes = try decoder.decode([PersonalQuote].self, from: data)
            
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = loadedQuotes
            isInitializing = wasInitializing
        } catch {
            print("Failed to load personal quotes: \(error)")
            // If loading fails, start with empty array
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = []
            isInitializing = wasInitializing
        }
    }
    
    func clearPersonalQuotes() {
        if Thread.isMainThread {
            personalQuotes = []
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes = []
            }
        }
        
        userDefaults.removeObject(forKey: "personalQuotes")
        userDefaults.synchronize()
    }
    
    // MARK: - Testing Support
    func clearLovedQuotes() {
        // Clear in-memory data
        if Thread.isMainThread {
            lovedQuotes = Set<String>()
        } else {
            DispatchQueue.main.sync {
                self.lovedQuotes = Set<String>()
            }
        }
        
        // Completely clear UserDefaults data
        userDefaults.removeObject(forKey: "lovedQuotes")
        userDefaults.synchronize()
        
        // Double-check that the data is really gone
        if userDefaults.array(forKey: "lovedQuotes") != nil {
            // Data persists, which could be expected in some testing scenarios
        }
    }
}