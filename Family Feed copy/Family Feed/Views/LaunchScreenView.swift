import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Family Feed")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Created by:")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("Thrinay Kumar Devi Ramakrishna")
                        .font(.title2)
                        .fontWeight(.medium)

                }
                
                Spacer()
            }
            .padding()
        }
    }
} 