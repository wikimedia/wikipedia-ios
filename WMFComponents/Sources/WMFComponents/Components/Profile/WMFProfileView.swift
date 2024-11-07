import SwiftUI

public class WMFProfileViewTargetRects: ObservableObject {
    public init(donateButtonFrame: CGRect = .zero) {
        self.donateButtonFrame = donateButtonFrame
    }
    
    @Published public var donateButtonFrame: CGRect = .zero
}

public struct WMFProfileView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @EnvironmentObject var targetRects: WMFProfileViewTargetRects

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFProfileViewModel
    public var donePressed: (() -> Void)?

    public init(viewModel: WMFProfileViewModel) {
        self.viewModel = viewModel
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: theme.text]
        UINavigationBar.appearance().backgroundColor = theme.midBackground
    }

    public var body: some View {
        NavigationView {
            List {
                ForEach(0..<viewModel.profileSections.count, id: \.self) { sectionIndex in
                    sectionView(items: viewModel.profileSections[sectionIndex])
                }
            }
            .background(Color(uiColor: theme.midBackground))
            .scrollContentBackground(.hidden)
            .navigationTitle(viewModel.localizedStrings.pageTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        donePressed?()
                    }) {
                        Text(viewModel.localizedStrings.doneButtonTitle)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    private func sectionView(items: ProfileSection) -> some View {
        Section {
            ForEach(items.listItems, id: \.id) { item in
                profileBarItem(item: item)
                    .listRowBackground(Color(uiColor: theme.chromeBackground))
            }
        } footer: {
            if let subtext = items.subtext {
                Text(subtext)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
        }
        .listRowSeparator(.hidden)
    }

    private func profileBarItem(item: ProfileListItem) -> some View {
        Button(action: {
            item.action()
        }) {
            HStack {
                if let image = item.image {
                    if let uiImage = WMFSFSymbolIcon.for(symbol: image, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                        Image(uiImage: uiImage)
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(uiColor: theme.chromeBackground))
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(uiColor: item.imageColor ?? theme.border))
                                    .frame(width: 32, height: 32)
                                    .padding(0)
                            )
                            .padding(.trailing, 16)
                            .padding(.leading, 8)
                    }
                }
                
                Text(item.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(Font(WMFFont.for(.headline)))
                    .foregroundStyle(Color(uiColor: theme.text))

                if let hasNotifications = item.hasNotifications, hasNotifications {
                    HStack(spacing: 10) {
                        if item.needsNotificationCount {
                            Text("\(viewModel.inboxCount)")
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                                .font(Font(WMFFont.for(.headline)))
                        }
                        if let image = WMFSFSymbolIcon.for(symbol: .circleFill, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                            Image(uiImage: image)
                                .foregroundStyle(Color(uiColor: theme.destructive))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                if item.isDonate && item.isLoadingDonateConfigs {
                    ProgressView()
                }
            }
        }
        .background(content: {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        if item.isDonate {
                            let insideFrame = geometry.frame(in: .global)
                            targetRects.donateButtonFrame = insideFrame
                        }
                    }
            }
        })
    }
}
