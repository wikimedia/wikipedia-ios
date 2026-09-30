import SwiftUI
import WMFData

public struct WMFChooseEditorView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFChooseEditorViewModel

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFChooseEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            mainContent
        }
        .multilineTextAlignment(.leading)
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    public var mainContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                optionsCard
                dontShowAgainRow
            }

            WMFLargeButton(style: .primary, title: viewModel.continueTitle) {
                viewModel.tappedContinue()
            }
            .padding(.top, 28)

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var optionsCard: some View {
        WMFEditModeOptionsCard(selectedMode: viewModel.selectedMode) { mode in
            viewModel.selectedMode = mode
        }
    }

    private var dontShowAgainRow: some View {
        HStack(spacing: 10) {
            WMFCheckmarkView(isSelected: viewModel.dontShowAgain, configuration: .init(style: .checkbox))
                .accessibilityHidden(true)

            Text(viewModel.dontShowAgainTitle)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHint(viewModel.dontShowAgainAccessibilityHint)
                .accessibilityAddTraits(viewModel.dontShowAgain ? [.isSelected] : [])
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.dontShowAgain.toggle()
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    WMFChooseEditorView(viewModel: WMFChooseEditorViewModel(
        didTapContinue: { mode, dontShowAgain in
            print("continue: \(mode), dontShowAgain: \(dontShowAgain)")
        },
        didTapClose: {
            print("close")
        }
    ))
}
