import SwiftUI

struct WMFYearInReviewScrollView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var flashScrollIndicators: Bool = false
    
    private let scrollViewContents: AnyView
    private let forceBackgroundColor: UIColor?
    
    init<ScrollViewContent: View>(
        scrollViewContents: ScrollViewContent,
        forceBackgroundColor: UIColor? = nil
    ) {
        self.scrollViewContents = AnyView(scrollViewContents)
        self.forceBackgroundColor = forceBackgroundColor
    }

    // MARK: - Lifecycle
    
    private var scrollView: some View {
        ScrollView(showsIndicators: true) {
            scrollViewContents
        }
    }

    private var flashingScrollView: some View {
        scrollView
        .scrollIndicatorsFlash(trigger: flashScrollIndicators)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private var content: some View {
        Group {
            flashingScrollView
        }
    }

    var body: some View {
        content
            .background {
                if let forceBackgroundColor {
                    Color(forceBackgroundColor).ignoresSafeArea()
                } else {
                    Color(appEnvironment.theme.midBackground).ignoresSafeArea()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    flashScrollIndicators.toggle()
                }
            }
    }

}
