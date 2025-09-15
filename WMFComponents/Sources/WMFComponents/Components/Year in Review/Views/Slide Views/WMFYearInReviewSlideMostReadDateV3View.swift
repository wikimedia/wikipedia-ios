import SwiftUI

struct WMFYearInReviewSlideMostReadDateV3View: View {
    let viewModel: WMFYearInReviewSlideMostReadDateV3ViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideMostReadDateV3ViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct WMFYearInReviewSlideMostReadDateV3ViewContent: View {
    let viewModel: WMFYearInReviewSlideMostReadDateV3ViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private func dateItemView(text: String, footer: String) -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(Font(WMFFont.for(.georgiaTitle3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
            Text(footer)
                .font(Font(WMFFont.for(.subheadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    var body: some View {
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
                            viewModel.tappedInfo()
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
                
                VStack(spacing: 16) {
                    dateItemView(text: viewModel.time, footer: viewModel.timeFooter)
                    dateItemView(text: viewModel.day, footer: viewModel.dayFooter)
                    dateItemView(text: viewModel.month, footer: viewModel.monthFooter)
                }
                .foregroundStyle(Color(uiColor: theme.text))
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}
