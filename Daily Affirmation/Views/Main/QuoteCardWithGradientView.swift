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
                    Text(displayQuote)
                        .font(.system(size: 32, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .lineSpacing(8)
                        .scaleEffect(quoteManager.fontSize.multiplier)
                        .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
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