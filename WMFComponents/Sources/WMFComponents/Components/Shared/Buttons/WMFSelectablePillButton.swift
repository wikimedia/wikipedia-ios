import SwiftUI

/// A capsule-shaped button for single-choice option groups: filled with the link color when
/// selected, outlined on the neutral background otherwise.
public struct WMFSelectablePillButton: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let label: String
    let isSelected: Bool
    let tapAction: () -> Void

    public init(label: String, isSelected: Bool, tapAction: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.tapAction = tapAction
    }

    public var body: some View {
        Button {
            tapAction()
        } label: {
            Text(label)
                .font(Font(WMFFont.for(.mediumSubheadline)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundColor(isSelected ? Color(WMFColor.white) : Color(appEnvironment.theme.text))
                .background(
                    Capsule()
                        .stroke(isSelected ? Color(appEnvironment.theme.link) : Color(appEnvironment.theme.baseBackground), lineWidth: 1)
                )
        }
        .background(Capsule().fill(isSelected ? Color(appEnvironment.theme.link) : Color(appEnvironment.theme.midBackground)))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
