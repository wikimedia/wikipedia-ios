import SwiftUI
import WMFComponents

struct ProfileView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    // Testing
    let profileSections: [ProfileSection] = [
        ProfileSection(
            listItems: [
                ProfileListItem(text: "Settings", image: .starLeadingHalfFilled, imageColor: UIColor(Color.blue), notificationNumber: nil, action: {}),
                ProfileListItem(text: "Favorites", image: .personFilled, imageColor: UIColor(Color.orange), notificationNumber: nil, action: {}),
                ProfileListItem(text: "Messages", image: .conversation, imageColor: nil, notificationNumber: 3, action: {})
            ],
            subtext: "Sign up for a Wikipedia account to track your contributions, save articles offline, and sync across devices."
        ),
        ProfileSection(
            listItems: [
                ProfileListItem(text: "Notifications", image: nil, imageColor: UIColor(Color.purple), notificationNumber: 5, action: {}),
                ProfileListItem(text: "Help", image: .quoteOpening, imageColor: nil, notificationNumber: nil, action: {})
            ],
            subtext: nil
        ),
        ProfileSection(
            listItems: [
                ProfileListItem(text: "Profile", image: .person, imageColor: UIColor(Color.red), notificationNumber: nil, action: {}),
                ProfileListItem(text: "Privacy", image: nil, imageColor: nil, notificationNumber: 12, action: {}),
                ProfileListItem(text: "Support", image: nil, imageColor: nil, notificationNumber: 1, action: {}),
                ProfileListItem(text: "About", image: nil, imageColor: nil, notificationNumber: nil, action: {})
            ],
            subtext: "Or support Wikipedia with a donation to keep it free and accessible for everyone around the world."
        )
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<profileSections.count, id: \.self) { sectionIndex in
                    sectionView(items: profileSections[sectionIndex])
                }
            }
            .toolbarBackground( Color(uiColor: theme.midBackground), for: .navigationBar)
            .background(Color(uiColor: theme.midBackground))
            .navigationTitle("Account")
            .padding(.top, 16)
        }
    }

    private func sectionView(items: ProfileSection) -> some View {
        Section {
            ForEach(items.listItems, id: \.id) { item in
                profileBarItem(item: item)
            }
        } footer: {
            if let subtext = items.subtext {
                Text(subtext)
            }
        }
        .listRowSeparator(.hidden)
    }

    private func profileBarItem(item: ProfileListItem) -> some View {
        HStack {
            if let image = item.image {
                if let uiImage = WMFSFSymbolIcon.for(symbol: image) {
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
                .font(Font(WMFFont.for(.headline)))
            
            if let notificationNumber = item.notificationNumber, notificationNumber > 0 {
                HStack(spacing: 10) {
                    Text("\(notificationNumber)")
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                    if let image = WMFSFSymbolIcon.for(symbol: .circleFill) {
                        Image(uiImage: image)
                            .foregroundStyle(Color(uiColor: theme.destructive))
                            .frame(width: 10, height: 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
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

struct ProfileSection: Identifiable {
    let id = UUID()
    let listItems: [ProfileListItem]
    let subtext: String?
}

#Preview {
    ProfileView()
}
