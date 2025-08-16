import SwiftUI

public struct WMFYearInReviewScrollView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var flashScrollIndicators: Bool = false
    
    let scrollViewContents: AnyView
    
    public init<ScrollViewContent: View>(
        scrollViewContents: ScrollViewContent
    ) {
        self.scrollViewContents = AnyView(scrollViewContents)
    }

    // MARK: - Lifecycle
    
    var scrollView: some View {
        ScrollView(showsIndicators: true) {
            scrollViewContents
        }
    }
    
    @available(iOS 17.0, *)
    var flashingScrollView: some View {
        scrollView
        .scrollIndicatorsFlash(trigger: flashScrollIndicators)
    }
    
    var nonFlashingScrollView: some View {
        scrollView
    }
    
    private var content: some View {
        Group {
            if #available(iOS 17.0, *) {
                flashingScrollView
            } else {
                nonFlashingScrollView
            }
        }
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
