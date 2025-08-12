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
        ZStack {
            // Background matches onboarding style
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.30),
                    Color.accentColor.opacity(0.15),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ZStack {
                    // Subtle header panel using accent tint
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.12),
                                    Color.accentColor.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Cancel")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text(editingQuote != nil ? "Edit Quote" : "Add Quote")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Your inspiration")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                saveQuote()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isValidQuote && !isSaving ? Color.accentColor : Color.gray.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(!isValidQuote || isSaving)
                            .accessibilityLabel("Save quote")
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Text input card
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Quote")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Add a quote that motivates and inspires you")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            TextEditor(text: $quoteText)
                                .focused($isTextFieldFocused)
                                .font(.body)
                                .padding(16)
                                .frame(minHeight: 120)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isTextFieldFocused ? 
                                            Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                            Color.secondary.opacity(0.25), 
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
                            
                            // Character count and validation
                            VStack(spacing: 8) {
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
                                            .font(.caption)
                                        
                                        if characterCount < minCharacters {
                                            Text("Quote must be at least \(minCharacters) characters")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        } else if characterCount > maxCharacters {
                                            Text("Quote is too long. Maximum \(maxCharacters) characters.")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                        
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        // Use system appearance like onboarding
        .onAppear {
            isTextFieldFocused = true
        }
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
