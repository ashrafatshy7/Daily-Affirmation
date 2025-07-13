import SwiftUI

struct AddPersonalQuoteView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
    let editingQuote: PersonalQuote?
    
    @State private var quoteText: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxCharacters = 50
    private let minCharacters = 4
    
    init(quoteManager: QuoteManager, editingQuote: PersonalQuote? = nil) {
        self.quoteManager = quoteManager
        self.editingQuote = editingQuote
        self._quoteText = State(initialValue: editingQuote?.text ?? "")
    }
    
    private var isValidQuote: Bool {
        let trimmedText = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.count >= minCharacters && trimmedText.count <= maxCharacters
    }
    
    private var characterCount: Int {
        quoteText.count
    }
    
    private var characterCountColor: Color {
        if characterCount > maxCharacters {
            return .red
        } else if characterCount > maxCharacters - 50 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    
                    Spacer()
                    
                    Text(editingQuote != nil ? "Edit Quote" : "Add Quote")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveQuote()
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    .disabled(!isValidQuote || isSaving)
                    .opacity(!isValidQuote || isSaving ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // Content
                VStack(spacing: 24) {
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Share Your Inspiration")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("Add a quote that motivates and inspires you. It will be included in your daily rotation alongside our curated collection.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Text input area
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Quote")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextEditor(text: $quoteText)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .padding(16)
                            .frame(minHeight: 120)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isTextFieldFocused ? 
                                        Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                        Color.secondary.opacity(0.3), 
                                        lineWidth: isTextFieldFocused ? 2 : 1
                                    )
                            )
                            .overlay(
                                // Placeholder text
                                Group {
                                    if quoteText.isEmpty {
                                        Text("\"The only way to do great work is to love what you do.\"")
                                            .font(.body)
                                            .foregroundColor(.secondary.opacity(0.6))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 24)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(characterCount)/\(maxCharacters)")
                                .font(.caption)
                                .foregroundColor(characterCountColor)
                        }
                        
                        // Validation feedback
                        if !quoteText.isEmpty && !isValidQuote {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                
                                if characterCount < minCharacters {
                                    Text("Quote must be at least \(minCharacters) characters")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else if characterCount > maxCharacters {
                                    Text("Quote is too long. Maximum \(maxCharacters) characters.")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Preview section
                    if isValidQuote {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            VStack(spacing: 16) {
                                Text(quoteText.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 24)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3),
                                                Color(red: 1.0, green: 0.827, blue: 0.647).opacity(0.3),
                                                Color(red: 1.0, green: 0.659, blue: 0.659).opacity(0.3)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(16)
                                
                                Text("This is how your quote will appear in the app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .preferredColorScheme(.light)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveQuote() {
        guard isValidQuote else { return }
        
        isSaving = true
        
        let trimmedText = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let editingQuote = editingQuote {
            // Update existing quote
            let success = quoteManager.updatePersonalQuote(withId: editingQuote.id, newText: trimmedText)
            
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to update quote. Please try again."
                showingError = true
            }
        } else {
            // Add new quote
            let success = quoteManager.addPersonalQuote(trimmedText)
            
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to add quote. Please make sure it's between \(minCharacters) and \(maxCharacters) characters."
                showingError = true
            }
        }
        
        isSaving = false
    }
}

#Preview {
    AddPersonalQuoteView(quoteManager: QuoteManager())
}
