import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(NSLocalizedString("privacy_policy_title", comment: ""))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 25) {
                        // Introduction
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_introduction_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_introduction_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Information We Collect
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_info_collect_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_info_collect_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("privacy_info_collect_preferences", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("privacy_info_collect_notification", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("privacy_info_collect_no_personal", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("privacy_info_collect_no_tracking", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // How We Use Your Information
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_how_use_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_how_use_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("privacy_how_use_personalized", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("privacy_how_use_remember", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text(NSLocalizedString("privacy_how_use_notifications", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Data Security
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_data_security_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_data_security_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Third-Party Services
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_third_party_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_third_party_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_contact_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_contact_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Last Updated
                        VStack(alignment: .leading, spacing: 10) {
                            Text(NSLocalizedString("privacy_last_updated_title", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("privacy_last_updated_text", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .preferredColorScheme(nil)
    }
}

#Preview {
    PrivacyPolicyView()
}
