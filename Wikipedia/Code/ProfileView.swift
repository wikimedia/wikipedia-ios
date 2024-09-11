import SwiftUI

struct ProfileView: View {
    // Testing
    let profileListItems: [[ProfileListItem]] = [
        [
            ProfileListItem(text: "Settings", imageName: "gearshape", notificationNumber: nil, action: {}),
            ProfileListItem(text: "Favorites", imageName: "star", notificationNumber: nil, action: {}),
            ProfileListItem(text: "Messages", imageName: "envelope", notificationNumber: 3, action: {})
        ],
        [
            ProfileListItem(text: "Notifications", imageName: "bell", notificationNumber: 5, action: {}),
            ProfileListItem(text: "Help", imageName: "questionmark.circle", notificationNumber: nil, action: {})
        ],
        [
            ProfileListItem(text: "Profile", imageName: "person.crop.circle", notificationNumber: nil, action: {}),
            ProfileListItem(text: "Privacy", imageName: "lock.shield", notificationNumber: nil, action: {}),
            ProfileListItem(text: "Support", imageName: "lifepreserver", notificationNumber: 1, action: {}),
            ProfileListItem(text: "About", imageName: "info.circle", notificationNumber: nil, action: {})
        ]
    ]

    var body: some View {
        List {
            ForEach(0..<profileListItems.count, id: \.self) { sectionIndex in
                let section = profileListItems[sectionIndex]
                Section {
                    ForEach(0..<section.count, id: \.self) { itemIndex in
                        let item = section[itemIndex]
                        Text(item.text)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}

struct ProfileListItem {
    let text: String
    let imageName: String?
    let notificationNumber: Int? // if int > 0 or nil, show badge
    let action: () -> ()?
}

#Preview {
    ProfileView()
}
