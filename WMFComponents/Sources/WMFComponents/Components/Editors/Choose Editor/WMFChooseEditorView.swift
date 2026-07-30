import SwiftUI

public struct WMFChooseEditorView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFChooseEditorViewModel

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFChooseEditorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
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
        .multilineTextAlignment(.leading)
        .padding(16)
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            optionRow(mode: .visual, title: viewModel.visualEditingTitle, subtitle: viewModel.visualEditingSubtitle, showsExternalLinkIcon: true)
            Divider()
                .padding(.horizontal, 16)
            optionRow(mode: .source, title: viewModel.sourceEditingTitle, subtitle: viewModel.sourceEditingSubtitle, showsExternalLinkIcon: false)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(uiColor: theme.chromeBackground))
        )
    }

    private func optionRow(mode: WMFChooseEditorViewModel.EditMode, title: String, subtitle: String, showsExternalLinkIcon: Bool) -> some View {
        Button {
            viewModel.selectedMode = mode
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Font(WMFFont.for(.headline)))
                            .accessibilityAddTraits(viewModel.selectedMode == mode ? [.isSelected] : [])

                        if showsExternalLinkIcon, let uiImage = WMFSFSymbolIcon.for(symbol: .arrowUpForward, font: .subheadline) {
                            Image(uiImage: uiImage)
                        }
                    }
                    .foregroundColor(Color(uiColor: theme.text))

                    HStack(alignment: .top, spacing: 8) {
                        Text(subtitle)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        WMFCheckmarkView(isSelected: true, configuration: .init(style: .default))
                            .opacity(viewModel.selectedMode == mode ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(ChooseEditorRowButtonStyle())
        .accessibilityElement(children: .combine)
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

private struct ChooseEditorRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
