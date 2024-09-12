import SwiftUI
import WMFComponents

struct ProfileView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    // Testing
    let profileListItems: [[ProfileListItem]] = [
        [
            ProfileListItem(text: "Settings", image: .starLeadingHalfFilled, imageColor: UIColor(Color.blue), notificationNumber: nil, action: {}),
            ProfileListItem(text: "Favorites", image: .personFilled, imageColor: UIColor(Color.orange), notificationNumber: nil, action: {}),
            ProfileListItem(text: "Messages", image: .conversation, imageColor: nil, notificationNumber: 3, action: {})
        ],
        [
            ProfileListItem(text: "Notifications", image: nil, imageColor: UIColor(Color.purple), notificationNumber: 5, action: {}),
            ProfileListItem(text: "Help", image: .quoteOpening, imageColor: nil, notificationNumber: nil, action: {})
        ],
        [
            ProfileListItem(text: "Profile", image: .person, imageColor: UIColor(Color.red), notificationNumber: nil, action: {}),
            ProfileListItem(text: "Privacy", image: nil, imageColor: nil, notificationNumber: nil, action: {}),
            ProfileListItem(text: "Support", image: nil, imageColor: nil, notificationNumber: 1, action: {}),
            ProfileListItem(text: "About", image: nil, imageColor: nil, notificationNumber: nil, action: {})
        ]
    ]

    var body: some View {
        List {
            ForEach(0..<profileListItems.count, id: \.self) { sectionIndex in
                sectionView(sectionIndex: sectionIndex)
            }
        }
    }

    private func sectionView(sectionIndex: Int) -> some View {
        Section {
            ForEach(profileListItems[sectionIndex], id: \.id) { item in
                profileBarItem(item: item)
            }
        }
        .listRowSeparator(.hidden)
    }

    private func profileBarItem(item: ProfileListItem) -> some View {
        HStack {
            if let image = item.image {
                if let uiImage = WMFSFSymbolIcon.for(symbol: image, paletteColors: [UIColor(Color.green) ]) {
                        Image(uiImage: uiImage)
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(uiColor: theme.paperBackground))
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(uiColor: item.imageColor ?? theme.border))
                                    .frame(width: 32, height: 32)
                                    .padding(0)
                            )
                            .padding(.trailing, 16)
                }
            }
            
            Text(item.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let notificationNumber = item.notificationNumber, notificationNumber > 0 {
                
            }
        }
    }
}

struct ProfileListItem: Identifiable {
    var id = UUID()
    let text: String
    let image: WMFSFSymbolIcon?
    let imageColor: UIColor?
    let notificationNumber: Int? // if int > 0 or nil, show badge
    let action: () -> ()?
}

#Preview {
    ProfileView()
}
