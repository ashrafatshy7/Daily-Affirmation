import SwiftUI

struct PersonalQuotesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddQuote = false
    @State private var editingQuote: PersonalQuote? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Fixed at top
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    }
                    
                    Text("Personal Quotes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddQuote.toggle()
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    }
                    .accessibilityIdentifier("add_quote_button")
                    .accessibilityLabel("Add new personal quote")
                    .accessibility(addTraits: .isButton)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // Settings toggle for including personal quotes
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include in Daily Rotation")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Show personal quotes alongside built-in quotes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $quoteManager.includePersonalQuotes)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.659, green: 0.902, blue: 0.812)))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Frequency control section (only show if personal quotes are enabled)
                if quoteManager.includePersonalQuotes {
                    VStack(spacing: 16) {
                        FrequencyControlSection(quoteManager: quoteManager)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                
                // Content
                if quoteManager.personalQuotes.isEmpty {
                    // Empty state
                    VStack(spacing: 32) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                Text("No Personal Quotes Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                Text("Add your own inspiring quotes to see them alongside our curated collection")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            Button(action: {
                                showAddQuote.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add Your First Quote")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.659, green: 0.902, blue: 0.812))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 60)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Quotes list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(quoteManager.sortedPersonalQuotes, id: \.id) { quote in
                                PersonalQuoteCard(
                                    quote: quote,
                                    onEdit: {
                                        editingQuote = quote
                                    },
                                    onDelete: {
                                        quoteManager.deletePersonalQuote(withId: quote.id)
                                    },
                                    onToggleActive: {
                                        quoteManager.togglePersonalQuoteActive(withId: quote.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showAddQuote) {
            AddPersonalQuoteView(quoteManager: quoteManager)
        }
        .sheet(item: $editingQuote) { quote in
            AddPersonalQuoteView(quoteManager: quoteManager, editingQuote: quote)
        }
    }
}

struct PersonalQuoteCard: View {
    let quote: PersonalQuote
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleActive: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote text
            Text(quote.displayText)
                .font(.body)
                .foregroundColor(quote.isActive ? .black : .secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Footer with date and actions
            HStack {
                // Date
                Text(quote.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    // Active/Inactive toggle
                    Button(action: onToggleActive) {
                        Image(systemName: quote.isActive ? "eye.fill" : "eye.slash")
                            .font(.system(size: 16))
                            .foregroundColor(quote.isActive ? Color(red: 0.659, green: 0.902, blue: 0.812) : .secondary)
                    }
                    .accessibilityLabel(quote.isActive ? "Hide quote" : "Show quote")
                    
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Edit quote")
                    
                    // Delete button
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete quote")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            quote.isActive ? 
                            Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3) : 
                            Color.secondary.opacity(0.2), 
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(quote.isActive ? 1.0 : 0.7)
        .alert("Delete Quote", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this quote? This action cannot be undone.")
        }
    }
}

struct FrequencyControlSection: View {
    @ObservedObject var quoteManager: QuoteManager
    
    private var frequencyDisplayText: String {
        let multiplier = quoteManager.personalQuoteFrequencyMultiplier
        
        if multiplier <= 1.1 {
            return "Equal frequency"
        } else if multiplier <= 1.6 {
            return "Slightly more often"
        } else if multiplier <= 2.5 {
            return "More often"
        } else if multiplier <= 3.5 {
            return "Much more often"
        } else {
            return "Very frequently"
        }
    }
    
    private var expectedPercentage: Int {
        let multiplier = quoteManager.personalQuoteFrequencyMultiplier
        let personalCount = max(1, quoteManager.personalQuotes.count)
        let builtinCount = max(1, quoteManager.quotes.count)
        
        // Calculate weighted percentage
        let personalWeight = Double(personalCount) * multiplier
        let builtinWeight = Double(builtinCount)
        let totalWeight = personalWeight + builtinWeight
        
        let percentage = (personalWeight / totalWeight) * 100
        return min(95, max(5, Int(percentage.rounded())))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Quote Frequency")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("How often personal quotes appear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(frequencyDisplayText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                    Text("~\(expectedPercentage)% of quotes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("1×")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: $quoteManager.personalQuoteFrequencyMultiplier,
                    in: 1.0...5.0,
                    step: 0.1
                ) {
                    Text("Frequency")
                } minimumValueLabel: {
                    Image(systemName: "equal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                }
                .accentColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                
                Text("5×")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick preset buttons
            HStack(spacing: 8) {
                ForEach([
                    (value: 1.0, label: "Equal"),
                    (value: 2.0, label: "2× More"),
                    (value: 3.0, label: "3× More"),
                    (value: 5.0, label: "Max")
                ], id: \.value) { preset in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            quoteManager.personalQuoteFrequencyMultiplier = preset.value
                        }
                    }) {
                        Text(preset.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(
                                abs(quoteManager.personalQuoteFrequencyMultiplier - preset.value) < 0.1 ? 
                                .white : Color(red: 0.659, green: 0.902, blue: 0.812)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        abs(quoteManager.personalQuoteFrequencyMultiplier - preset.value) < 0.1 ? 
                                        Color(red: 0.659, green: 0.902, blue: 0.812) : Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(red: 0.659, green: 0.902, blue: 0.812), lineWidth: 1)
                                    )
                            )
                    }
                    .animation(.easeInOut(duration: 0.2), value: quoteManager.personalQuoteFrequencyMultiplier)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    PersonalQuotesView(quoteManager: QuoteManager())
}