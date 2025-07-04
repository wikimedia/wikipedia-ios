import SwiftUI
import Combine
import WMFData

public enum AccessoryType {
    case none
    case toggle(Binding<Bool>)
    case icon(name: String)
    case chevron(label: String?)
}

public struct SettingsItem: Identifiable {
    public let id = UUID()
    let image: UIImage?
    let color: UIColor
    let title: String
    let subtitle: String?
    let accessory: AccessoryType
    let action: (() -> Void)?
    let subSections: [SettingsSection]?
    // todo: add localized strings struct
    public init(image: UIImage?, color: UIColor, title: String, subtitle: String?, accessory: AccessoryType, action: (() -> Void)?, subSections: [SettingsSection]?) {
        self.image = image
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.action = action
        self.subSections = subSections
    }
}

public struct SettingsSection: Identifiable {
    public let id = UUID()
    let header: String?
    let footer: String?
    let items: [SettingsItem]
    // todo: add localized strings struct

    public init(header: String?, footer: String?, items: [SettingsItem]) {
        self.header = header
        self.footer = footer
        self.items = items
    }
}

final public class WMFSettingsViewModel: ObservableObject {
    @ObservedObject private var dataController: WMFSettingsDataController

    @Published private(set) var sections: [SettingsSection] = []

    private var cancellables = Set<AnyCancellable>()


    public init() {
        self.dataController = WMFSettingsDataController()
    }

    private func rebuildSections() {
        // Create Bindings directly from dataController
//        let notifBinding = $dataController.notificationsOn
//        let exploreBinding = $dataController.exploreFeedOn

        let generalItems = [
            SettingsItem(
                image: UIImage(systemName: "bell"),
                color: WMFColor.yellow600,
                title: "Notifications",
                subtitle: "Receive updates",
                accessory: .none,
                action: nil,
                subSections: nil
            ),
            SettingsItem(
                image: UIImage(systemName: "globe"),
                color: WMFColor.red700,
                title: "Explore feed",
                subtitle: "Show recommended articles",
                accessory: .none,
                action: nil,
                subSections: nil
            )
        ]

        let generalSection = SettingsSection(
            header: "General",
            footer: "Your core preferences",
            items: generalItems
        )

        sections = [generalSection]
    }

}
