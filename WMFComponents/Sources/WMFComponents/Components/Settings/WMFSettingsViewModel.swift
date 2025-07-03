import SwiftUI
import Combine

enum AccessoryType {
    case none
    case toggle(Binding<Bool>)
    case icon(name: String)
    case chevron(label: String?)
    case checkmark
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let iconName: String
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

    var sections: [SettingsSection]

    init(sections: [SettingsSection]) {
        self.sections = sections
    }

}
