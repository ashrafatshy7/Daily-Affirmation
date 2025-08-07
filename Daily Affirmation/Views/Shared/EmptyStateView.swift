import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Illustration/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.1),
                                Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
            }
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineLimit(3)
            }
            
            // Action Button
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.8),
                                    Color(red: 0.3, green: 0.7, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

// Preview
#Preview {
    EmptyStateView(
        icon: "heart.text.square",
        title: "No Personal Quotes Yet",
        subtitle: "Start building your personal motivation library with quotes that inspire you most",
        actionTitle: "Add Your First Quote"
    ) {
        print("Add quote tapped")
    }
}