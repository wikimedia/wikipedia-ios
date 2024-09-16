import SwiftUI

public struct WMFProfileView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFProfileViewModel
    public var donePressed: (() -> Void)?

    public init(isLoggedIn: Bool = true) {
        self.viewModel = WMFProfileViewModel(isLoggedIn: isLoggedIn)
    }

    public var body: some View {
        NavigationView {
            List {
                ForEach(0..<viewModel.profileSections.count, id: \.self) { sectionIndex in
                    sectionView(items: viewModel.profileSections[sectionIndex])
                }
            }
            .navigationTitle("Account")
            .toolbarBackground(Color(uiColor: theme.midBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        donePressed?()
                    }
                }
            }
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

