import SwiftUI

struct HomeFooter: View {
    let links = [
        "Privacy Policy",
        "Terms of Service",
        "Contact Us",
        "Twitter",
        "Instagram"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Links
            HStack(spacing: 24) {
                ForEach(links, id: \.self) { link in
                    Button(action: {
                        // Handle link tap - could open URLs or show sheets
                        print("Tapped: \(link)")
                    }) {
                        Text(link)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            // Copyright
            Text("© 2024 Book Shelfie. All rights reserved.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.3))
    }
}

struct HomeFooter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            HomeFooter()
        }
        .previewLayout(.sizeThatFits)
    }
}