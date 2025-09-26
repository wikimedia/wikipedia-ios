import SwiftUI

struct WMFYearInReviewContributionSlideView: View {
    @ObservedObject var viewModel: WMFYearInReviewContributorSlideViewModel
    @ObservedObject var parentViewModel: WMFYearInReviewViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private func subtitleAttributedString(subtitle: String) -> AttributedString {
        return (try? AttributedString(markdown: subtitle)) ?? AttributedString(subtitle)
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.body), boldFont: WMFFont.for(.boldBody), italicsFont: WMFFont.for(.body), boldItalicsFont: WMFFont.for(.body), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WMFYearInReviewScrollView(scrollViewContents:
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        ZStack {
                            Image(viewModel.gifName, bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                            WMFGIFImageView(viewModel.gifName)
                                .aspectRatio(1.5, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(viewModel.altText)
                    }
                
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            Spacer()
                            if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                                Button {
                                    viewModel.onInfoButtonTap()
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .foregroundStyle(Color(uiColor: theme.icon))
                                        .frame(width: 24, height: 24)
                                        .alignmentGuide(.top) { dimensions in
                                            dimensions[.top] - 5
                                        }
                                }
                            }
                        }
                        
                        switch viewModel.subtitletype {
                        case .html:
                            WMFHtmlText(html: viewModel.subtitle, styles: subtitleStyles)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        case .standard:
                            Text(viewModel.subtitle)
                                .font(Font(WMFFont.for(.body)))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .accentColor(Color(uiColor: theme.link))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        case .markdown:
                            Text(subtitleAttributedString(subtitle: viewModel.subtitle))
                                .font(Font(WMFFont.for(.body)))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .accentColor(Color(uiColor: theme.link))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if viewModel.contributionStatus == .contributor {
                            VStack(spacing: 16) {
                                Divider()
                                    .padding(.top, 8)
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(viewModel.toggleButtonTitle)
                                            .font(Font(WMFFont.for(.body)))
                                            .foregroundStyle(Color(uiColor: theme.text))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(viewModel.toggleButtonSubtitle)
                                            .font(Font(WMFFont.for(.caption2)))
                                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .layoutPriority(1)
                                    .padding(.trailing, 16)
                                    
                                    Toggle("", isOn: $viewModel.isIconOn)
                                        .toggleStyle(.switch)
                                        .labelsHidden()
                                        .onChange(of: viewModel.isIconOn) { newValue in
                                            if let toggleIcon = viewModel.onToggleIcon {
                                                toggleIcon(newValue)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: viewModel.contributionStatus == .noncontributor && !viewModel.forceHideDonateButton ? 66 : 0, trailing: sizeClassPadding))
                }
            )
            
            if viewModel.contributionStatus == .noncontributor && !viewModel.forceHideDonateButton {
                Group {
                    Button(action: { viewModel.onTappedDonateButton() }) {
                        Group {
                            if parentViewModel.isLoadingDonate {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: theme.destructive)))
                                    .scaleEffect(1.2)
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .onAppear {
                                                    let frame = geometry.frame(in: .global)
                                                    parentViewModel.donateButtonRect = frame
                                                }
                                        }
                                    )
                            } else {
                                HStack(alignment: .center, spacing: 6) {
                                    if let uiImage = WMFSFSymbolIcon.for(symbol: .heartFilled, font: .semiboldHeadline) {
                                        Image(uiImage: uiImage)
                                            .foregroundStyle(Color(uiColor: theme.destructive))
                                        Text(viewModel.donateButtonTitle)
                                            .font(Font(WMFFont.for(.semiboldHeadline)))
                                            .foregroundStyle(Color(uiColor: theme.destructive))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(uiColor: theme.newBorder), lineWidth: 1)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: theme.midBackground))
                        )
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 64 : 32)
                    .padding(.bottom, 16)
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .background(Color(theme.midBackground))
            }
        }
    }
}
