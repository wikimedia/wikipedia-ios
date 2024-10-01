import SwiftUI

public struct WMFSlideShow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding private var currentSlide: Int
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let slides: [YearInReviewSlide]
    
    public init(currentSlide: Binding<Int>, slides: [YearInReviewSlide]) {
        self._currentSlide = currentSlide
        self.slides = slides
        
        UIPageControl.appearance().currentPageIndicatorTintColor = theme.link.withAlphaComponent(0.3)
        UIPageControl.appearance().pageIndicatorTintColor = theme.link.withAlphaComponent(0.3)
    }
    
    public var body: some View {
        VStack {
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { slide in
                    VStack(alignment: .leading, spacing: 16) {
                        Image(slides[slide].imageName, bundle: .module)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(slides[slide].title)
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Text(slides[slide].subtitle)
                            .font(Font(WMFFont.for(.title3)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Spacer()
                    }
                    .tag(slide)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], 36)
            .padding(.top, 48)
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 34)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
    
    
    // Side quest from Robin
//    @ViewBuilder
//    private func titleView(title: String) -> some View {
//        let titleParts = splitTitleAndExtractNumber(title)
//        HStack(alignment: .bottom, spacing: 0) {
//            Text(titleParts.firstPart)
//                .font(Font(WMFFont.for(.boldTitle1)))
//                .foregroundStyle(Color(uiColor: theme.text))
//            if !titleParts.number.isEmpty {
//                AnimatedCounterView(finalCount: Int(titleParts.number) ?? 0)
//            }
//            Text(titleParts.secondPart)
//                .font(Font(WMFFont.for(.boldTitle1)))
//                .foregroundStyle(Color(uiColor: theme.text))
//        }
//        .multilineTextAlignment(.leading)
//    }
// }
//    

//    struct SlideTitleParts {
//        let firstPart: String
//        let number: String
//        let secondPart: String
//    }
//
//    func splitTitleAndExtractNumber(_ title: String) -> SlideTitleParts {
//        let numberRegex = try? NSRegularExpression(pattern: "\\d+")
//        
//        if let match = numberRegex?.firstMatch(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count)),
//           let range = Range(match.range, in: title) {
//            let number = String(title[range])
//            
//            let parts = title.components(separatedBy: number)
//            let firstPart = parts.first ?? ""
//            let secondPart = parts.count > 1 ? parts[1] : ""
//            
//            return SlideTitleParts(firstPart: firstPart, number: number, secondPart: secondPart)
//        }
//        
//        return SlideTitleParts(firstPart: title, number: "", secondPart: "")
//    }
//
// }
//
// struct AnimatedCounterView: View {
//    @ObservedObject var appEnvironment = WMFAppEnvironment.current
//    
//    var theme: WMFTheme {
//        return appEnvironment.theme
//    }
//    
//    @State private var currentCount: Int = 0
//    let finalCount: Int
//    
//    public init(finalCount: Int) {
//        self.finalCount = finalCount
//    }
//    
//    var body: some View {
//        Text("\(currentCount)")
//            .font(Font(WMFFont.for(.boldTitle1)))
//            .foregroundStyle(Color(uiColor: theme.text))
//            .onAppear {
//                startCounting()
//            }
//    }
//    
//    private func startCounting() {
//        var startingCount = 0
//        if finalCount - 50 > 0 {
//            startingCount = finalCount - 50
//        }
//        currentCount = startingCount
//        
//        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
//            if currentCount < finalCount {
//                withAnimation {
//                    currentCount += 1
//                }
//            } else {
//                timer.invalidate()
//            }
//        }
//    }
// }
