import SwiftUI

struct WMFYearInReviewContributionSlideView: View {
    @ObservedObject var viewModel: WMFYearInReviewContributorSlideViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding var isLoading: Bool
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideContributionViewContent(viewModel: viewModel, isLoading: $isLoading))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct WMFYearInReviewSlideContributionViewContent: View {
    @ObservedObject var viewModel: WMFYearInReviewContributorSlideViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    @State private var buttonRect: CGRect = .zero
    @Binding var isLoading: Bool
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private func subtitleAttributedString(subtitle: String) -> AttributedString {
        return (try? AttributedString(markdown: subtitle)) ?? AttributedString(subtitle)
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
            return HtmlUtils.Styles(font: WMFFont.for(.title3), boldFont: WMFFont.for(.title3), italicsFont: WMFFont.for(.title3), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
        }
    
    var body: some View {
        VStack(spacing: 48) {
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
            
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Spacer()
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                        Button {
                            
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
                        .font(Font(WMFFont.for(.title3)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .accentColor(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .markdown:
                    Text(subtitleAttributedString(subtitle: viewModel.subtitle))
                        .font(Font(WMFFont.for(.title3)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .accentColor(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                switch viewModel.contributionStatus {
                case .contributor:
                    VStack(spacing: 16) {
                        Divider()
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.toggleButtonTitle)
                                    .font(Font(WMFFont.for(.title3)))
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
                case .noncontributor:
                    if !viewModel.forceHideDonateButton {
                        
                        Button(action: { viewModel.onTappedDonateButton(buttonRect) }) {
                            
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: theme.destructive)))
                                        .scaleEffect(1.2)
                                } else {
                                    HStack(alignment: .center, spacing: 6) {
                                        if let uiImage = WMFSFSymbolIcon.for(symbol: .heartFilled, font: .semiboldHeadline) {
                                            Image(uiImage: uiImage)
                                                .foregroundStyle(Color(uiColor: theme.destructive))
                                        }
                                        Text(viewModel.donateButtonTitle)
                                            .font(Font(WMFFont.for(.semiboldHeadline)))
                                            .foregroundStyle(Color(uiColor: theme.destructive))
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
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let frame = geometry.frame(in: .global)
                                        buttonRect = frame
                                    }
                            }
                        )
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}
