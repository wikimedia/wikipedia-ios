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
            .padding(.horizontal, 16)
            .padding(.top, 8)

            WMFLargeButton(style: .primary, title: viewModel.continueTitle) {
                viewModel.tappedContinue()
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 16)

            Spacer(minLength: 0)
        }
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            optionRow(mode: .visual, title: viewModel.visualEditingTitle, subtitle: viewModel.visualEditingSubtitle, showsExternalLinkIcon: true)
            Divider()
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
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(Font(WMFFont.for(.headline)))
                            .foregroundColor(Color(uiColor: theme.text))
                        if showsExternalLinkIcon, let uiImage = WMFSFSymbolIcon.for(symbol: .arrowUpForward, font: .subheadline) {
                            Image(uiImage: uiImage)
                                .foregroundColor(Color(uiColor: theme.secondaryText))
                        }
                    }


                    HStack(alignment: .top, spacing: 6) {
                        Text(subtitle)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        if let uiImage = WMFSFSymbolIcon.for(symbol: .checkmark, font: .headline) {
                            Image(uiImage: uiImage)
                                .foregroundColor(Color(uiColor: theme.link))
                                .opacity(viewModel.selectedMode == mode ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.selectedMode == mode ? [.isSelected] : [])
    }

    private var dontShowAgainRow: some View {
        Button {
            viewModel.dontShowAgain.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                if let uiImage = WMFSFSymbolIcon.for(symbol: viewModel.dontShowAgain ? .checkmarkSquareFill : .square, font: .headline) {
                    Image(uiImage: uiImage)
                        .foregroundColor(Color(uiColor: viewModel.dontShowAgain ? theme.link : theme.secondaryText))
                }
                Text(viewModel.dontShowAgainTitle)
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.dontShowAgain ? [.isSelected] : [])
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
