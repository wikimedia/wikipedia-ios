import SwiftUI

public struct WMFYearInReview: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public var donePressed: (() -> Void)?
    var slides: [YearInReviewSlide]
    
    public init(slides: [YearInReviewSlide]) {
        self.slides = slides
    }

    public var body: some View {
        NavigationView {
            VStack {
                WMFSlideShow(slides: slides)
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        donePressed?()
                    }) {
                        Text("Done")
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("Donate")
                    }) {
                        HStack {
                            if let uiImage = WMFSFSymbolIcon.for(symbol: .heartFilled, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                                Image(uiImage: uiImage)
                                    .foregroundStyle(Color(uiColor: theme.destructive))
                            }
                            Text("Donate")
                                .foregroundStyle(Color(uiColor: theme.destructive))
                                .font(Font(WMFFont.for(.semiboldHeadline)))
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            print("Share")
                        }) {
                            HStack(alignment: .center, spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Color(uiColor: theme.link))
                                Text("Share")
                                    .foregroundStyle(Color(uiColor: theme.link))
                                    .font(Font(WMFFont.for(.semiboldHeadline)))
                            }
                        }
                        Spacer()
                        Button(action: {
                            print("Next")
                        }) {
                            Text("Next")
                                .foregroundStyle(Color(uiColor: theme.link))
                                .font(Font(WMFFont.for(.semiboldHeadline)))
                        }
                    }
                }
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
    }
}

public struct YearInReviewSlide {
    let imageName: String
    let title: String
    let informationBubbleText: String?
    let subtitle: String
    
    public init(imageName: String, title: String, informationBubbleText: String?, subtitle: String) {
        self.imageName = imageName
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
    }
}
