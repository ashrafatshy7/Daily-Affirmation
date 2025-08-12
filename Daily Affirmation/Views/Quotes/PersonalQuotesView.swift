import SwiftUI

struct PersonalQuotesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddQuote = false
    @State private var editingQuote: PersonalQuote? = nil
    @State private var showSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
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
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Back")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Personal Quotes")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Your inspiration")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if subscriptionManager.hasTimeRangeAccess {
                                    showAddQuote.toggle()
                                } else {
                                    showSubscription.toggle()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(subscriptionManager.hasTimeRangeAccess ? Color.accentColor : Color.gray.opacity(0.4))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: subscriptionManager.hasTimeRangeAccess ? "plus" : "lock.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .accessibilityIdentifier("add_quote_button")
                            .accessibilityLabel("Add new personal quote")
                            .accessibility(addTraits: .isButton)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Settings toggle for including personal quotes
                        VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include in Daily Rotation")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                            Text("Show personal quotes alongside built-in quotes")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: subscriptionManager.hasTimeRangeAccess ? $quoteManager.includePersonalQuotes : .constant(false))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.659, green: 0.902, blue: 0.812)))
                            .disabled(!subscriptionManager.hasTimeRangeAccess)
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
                    // Enhanced empty state
                    VStack {
                        Spacer()
                        
                        EmptyStateView(
                            icon: subscriptionManager.hasTimeRangeAccess ? "heart.text.square" : "lock.square",
                            title: subscriptionManager.hasTimeRangeAccess ? "Start Your Collection" : "Unlock Personal Quotes",
                            subtitle: subscriptionManager.hasTimeRangeAccess ? 
                                "Create your personal motivation library with quotes that speak to your heart. Your words, your inspiration." : 
                                "Add your own inspiring quotes and see them in your daily rotation alongside our curated collection.",
                            actionTitle: subscriptionManager.hasTimeRangeAccess ? "Add Your First Quote" : "Get Premium Access"
                        ) {
                            if subscriptionManager.hasTimeRangeAccess {
                                showAddQuote.toggle()
                            } else {
                                showSubscription.toggle()
                            }
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
                                        if subscriptionManager.hasTimeRangeAccess {
                                            editingQuote = quote
                                        } else {
                                            showSubscription.toggle()
                                        }
                                    },
                                    onDelete: {
                                        if subscriptionManager.hasTimeRangeAccess {
                                            quoteManager.deletePersonalQuote(withId: quote.id)
                                        } else {
                                            showSubscription.toggle()
                                        }
                                    },
                                    onToggleActive: {
                                        if subscriptionManager.hasTimeRangeAccess {
                                            quoteManager.togglePersonalQuoteActive(withId: quote.id)
                                        } else {
                                            showSubscription.toggle()
                                        }
                                    },
                                    isPremiumUser: subscriptionManager.hasTimeRangeAccess
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        // Use system appearance like onboarding
        .sheet(isPresented: $showAddQuote) {
            AddPersonalQuoteView(quoteManager: quoteManager)
        }
        .sheet(item: $editingQuote) { quote in
            AddPersonalQuoteView(quoteManager: quoteManager, editingQuote: quote)
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
}

struct PersonalQuoteCard: View {
    let quote: PersonalQuote
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleActive: () -> Void
    let isPremiumUser: Bool
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote text
            Text(quote.displayText)
                .font(.body)
                .foregroundColor(quote.isActive ? .primary : .secondary)
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
                        HStack(spacing: 4) {
                            Image(systemName: quote.isActive ? "eye.fill" : "eye.slash")
                                .font(.system(size: 16))
                                .foregroundColor(isPremiumUser ? (quote.isActive ? Color(red: 0.659, green: 0.902, blue: 0.812) : .secondary) : .gray)
                        }
                    }
                    .accessibilityLabel(quote.isActive ? "Hide quote" : "Show quote")
                    
                    // Edit button
                    Button(action: onEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                                .foregroundColor(isPremiumUser ? .secondary : .gray)
                        }
                    }
                    .accessibilityLabel("Edit quote")
                    
                    // Delete button
                    Button(action: {
                        if isPremiumUser {
                            showDeleteAlert = true
                        } else {
                            onDelete()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(isPremiumUser ? .red : .gray)
                        }
                    }
                    .accessibilityLabel("Delete quote")
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
        
        guard totalWeight > 0 else { return 50 } // Fallback to 50% if no quotes
        let percentage = (personalWeight / totalWeight) * 100
        
        // Safely convert percentage to Int with validation
        let safePercentage = percentage.safeInt(fallback: 50)
        return min(95, max(5, safePercentage))
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
                    Text("Personalized mix")
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
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.3), radius: 15, x: 0, y: 8)
        )
    }
}

#Preview {
    PersonalQuotesView(quoteManager: QuoteManager())
}
