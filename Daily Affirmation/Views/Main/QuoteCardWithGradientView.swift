import SwiftUI

struct QuoteCardWithGradientView: View {
    @ObservedObject var quoteManager: QuoteManager
    let screenIndex: Int
    let dragOffset: CGFloat

    private var displayQuote: String {
        switch screenIndex {
        case -1: return quoteManager.getPreviewQuote(offset: -1)
        case 1:  return quoteManager.getPreviewQuote(offset: 1)
        default: return quoteManager.currentQuote
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(quoteManager.selectedBackgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea(.all)

                VStack {
                    Spacer()
                    ZStack {
                        if quoteManager.textColor == .white {
                            // White text with dark outline
                            // Layer 1: Dark outline/stroke effect
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 1)
                                .offset(x: -1, y: -1)
                            
                            // Layer 2: Another dark outline for thickness
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 1)
                                .offset(x: 1, y: 1)
                            
                            // Layer 3: Main white text with gradient
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.95, green: 0.95, blue: 1.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
                                .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)
                        } else {
                            // Enhanced Black text with improved white outline and contrast
                            // Layer 1: Thick white outline base
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 2)
                                .offset(x: -2, y: -2)
                            
                            // Layer 2: Additional white outline for thickness
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 2)
                                .offset(x: 2, y: 2)
                            
                            // Layer 3: Side outlines for better coverage
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 1.5)
                                .offset(x: -2, y: 0)
                            
                            // Layer 4: More side outlines
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 1.5)
                                .offset(x: 2, y: 0)
                            
                            // Layer 5: Clean sharp white outline
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .blur(radius: 0.5)
                            
                            // Layer 6: Main enhanced black text with rich gradient
                            Text(displayQuote)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.black,
                                            Color(red: 0.15, green: 0.15, blue: 0.2),
                                            Color(red: 0.1, green: 0.1, blue: 0.15),
                                            Color.black
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .lineSpacing(8)
                                .scaleEffect(quoteManager.fontSize.multiplier)
                                .shadow(color: .white.opacity(0.9), radius: 2, x: 1, y: 1)
                                .shadow(color: .white.opacity(0.7), radius: 4, x: 0, y: 0)
                                .shadow(color: .white.opacity(0.5), radius: 8, x: 0, y: 0)
                                .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.4), radius: 1, x: -0.5, y: -0.5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier(
                        screenIndex == 0 ? "quote_text" : "quote_text_preview_\(screenIndex)"
                    )
                    .accessibilityLabel("Daily quote")
                    .accessibilityValue(displayQuote)
                    .accessibility(addTraits: .isStaticText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    QuoteCardWithGradientView(
        quoteManager: QuoteManager(),
        screenIndex: 0,
        dragOffset: 0
    )
}