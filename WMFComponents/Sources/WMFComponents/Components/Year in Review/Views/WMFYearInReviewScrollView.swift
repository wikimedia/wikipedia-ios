import SwiftUI

struct WMFYearInReviewScrollView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var flashScrollIndicators: Bool = false
    
    private let scrollViewContents: AnyView
    private let needsClearBackground: Bool
    
    init<ScrollViewContent: View>(
        scrollViewContents: ScrollViewContent,
        needsClearBackground: Bool = false
    ) {
        self.scrollViewContents = AnyView(scrollViewContents)
        self.needsClearBackground = needsClearBackground
    }

    // MARK: - Lifecycle
    
    private var scrollView: some View {
        ScrollView(showsIndicators: true) {
            scrollViewContents
        }
    }
    
    @available(iOS 17.0, *)
    private var flashingScrollView: some View {
        scrollView
        .scrollIndicatorsFlash(trigger: flashScrollIndicators)
    }
    
    private var nonFlashingScrollView: some View {
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

    var body: some View {
        content
            .background {
                Color(needsClearBackground ? .clear : appEnvironment.theme.midBackground).ignoresSafeArea()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    flashScrollIndicators.toggle()
                }
            }
    }

}
