import SwiftUI
import Combine

enum AccessoryType {
    case none
    case toggle(Binding<Bool>)
    case icon(name: String)
    case label(String?)
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let image: UIImage?
    let color: UIColor
    let title: String
    let subtitle: String?
    let accessory: AccessoryType
    let action: (() -> Void)?
    let subSections: [SettingsSection]?
    // todo: add localized strings struct
}

struct SettingsSection: Identifiable {
    let id = UUID()
    let header: String?
    let footer: String?
    let items: [SettingsItem]
    // todo: add localized strings struct
}

final class WMFSettingsViewModel: ObservableObject {
    @Published var notificationsOn = true
    @Published var exploreFeedOn = false
    @Published var isWhateverSelected = false

    var sections: [SettingsSection]

    init(sections: [SettingsSection]) {
        self.sections = sections
    }

}
