//
//  ContentView.swift
//  testClaudeCLIxCode
//
//  Created by Ashraf Atshy on 07/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var quoteManager = QuoteManager()
    @State private var showSettings = false
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: quoteManager.isDarkMode ? [
                        Color(red: 0.278, green: 0.573, blue: 0.573),
                        Color(red: 0.278, green: 0.573, blue: 0.573)
                    ] : [
                        Color(red: 0.4, green: 0.8, blue: 0.8),
                        Color(red: 0.3, green: 0.7, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Settings button
                    HStack {
                        Spacer()
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                    
                    Spacer()
                    
                    // Quote card
                    VStack(spacing: 30) {
                        Text(quoteManager.currentQuote)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 40)
                            .scaleEffect(quoteManager.fontSize.multiplier)
                        
                        Text(quoteManager.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(quoteManager.isDarkMode ? .white.opacity(0.7) : .secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(quoteManager.isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 30)
                    .offset(cardOffset)
                    .rotationEffect(.degrees(cardRotation))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                cardOffset = value.translation
                                cardRotation = Double(value.translation.width / 10)
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if abs(value.translation.width) > 100 {
                                        if value.translation.width > 0 {
                                            quoteManager.previousQuote()
                                        } else {
                                            quoteManager.nextQuote()
                                        }
                                    }
                                    cardOffset = .zero
                                    cardRotation = 0
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                quoteManager.previousQuote()
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("PREV")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                quoteManager.nextQuote()
                            }
                        }) {
                            HStack {
                                Text("NEXT")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            shareQuote()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: quoteManager.isDarkMode)
        .sheet(isPresented: $showSettings) {
            SettingsView(quoteManager: quoteManager)
        }
    }
    
    private func shareQuote() {
        let text = "\(quoteManager.currentQuote)\n\n- Daily Inspiration"
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}

#Preview {
    ContentView()
}
