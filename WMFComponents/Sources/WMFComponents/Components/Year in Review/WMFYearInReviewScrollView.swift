import SwiftUI

public struct WMFYearInReviewScrollView: View {

    // MARK: - Properties
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonAction: (() -> Void)?

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    @ScaledMetric var scrollViewBottomInset = 125.0
    
    @State private var flashScrollIndicators: Bool = false
    
    let scrollViewContents: AnyView
    let contents: AnyView?
    let hasLargeInsets: Bool
    let gifName: String
    let altText: String
    
    public init<ScrollViewContent: View>(
        scrollViewContents: ScrollViewContent,
        @ViewBuilder contents: () -> AnyView? = { nil },
        hasLargeInsets: Bool = true,
        gifName: String,
        altText: String
    ) {
        self.scrollViewContents = AnyView(scrollViewContents)
        self.contents = contents()
        self.hasLargeInsets = hasLargeInsets
        self.altText = altText
        self.gifName = gifName
    }

    // MARK: - Lifecycle
    
    @available(iOS 17.0, *)
    var flashingScrollView: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 16) {
                ZStack {
                    Image(gifName, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    WMFGIFImageView(gifName)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(altText)
                scrollViewContents
                    .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: hasLargeInsets ? scrollViewBottomInset : 0, trailing: sizeClassPadding))
            }
        }
        .scrollIndicatorsFlash(trigger: flashScrollIndicators)
    }
    
    var scrollView: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 16) {
                ZStack {
                    Image(gifName, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                    WMFGIFImageView(gifName)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(altText)
                scrollViewContents
                    .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: scrollViewBottomInset, trailing: sizeClassPadding))
            }
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var content: some View {
        ZStack(alignment: .bottom, content: {
            if #available(iOS 17.0, *) {
                flashingScrollView
            } else {
                scrollView
            }
            if contents != nil {
                contents
                    .padding(EdgeInsets(top: 12, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
                    .background {
                        Color(appEnvironment.theme.midBackground).ignoresSafeArea()
                    }
            }
        })
    }

    public var body: some View {
        content
            .background {
                Color(appEnvironment.theme.midBackground).ignoresSafeArea()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    flashScrollIndicators.toggle()
                }
            }
    }

}
