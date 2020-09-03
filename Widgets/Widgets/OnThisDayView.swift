import WidgetKit
import SwiftUI
import WMF
import UIKit

// MARK: - Views

let mainColor = Color(UIColor.blue50)
let grayColor = Color(UIColor.base30)
let silverColor = Color(UIColor.base70At55PercentAlpha)

struct OnThisDayView: View {
    @Environment(\.widgetFamily) private var family
    var entry: OnThisDayProvider.Entry

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch family {
            case .systemLarge:
                VStack(spacing: 0) {
                    OnThisDayHeaderElement(date: entry.date, minYear: entry.earliestYear, maxYear: entry.latestYear)
                    Spacer(minLength: 10)
                    VStack(alignment: .leading, spacing: 0) {
                        MainOnThisDayElement(eventYear: entry.year, snippet: entry.snippet, widgetSize: family)
                        if let article = entry.page {
                            ArticleRectangleElement(article: article, image: entry.pageImage, link: entry.page?.articleURL ?? entry.contentURL)
                        }
                        TimelineElementSpacer().layoutPriority(1)
                        OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                    }
                }
                .padding(16)
            case .systemMedium:
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(eventYear: entry.year, snippet: entry.snippet, widgetSize: family)
                    TimelineElementSpacer().layoutPriority(1)
                    OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                }
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 16, trailing: 16))
            case .systemSmall:
                /// While the medium and large sizes give a higher `layoutPriority` to `TimelineElementSpacer`, there is intentionally none here. When giving it a priority, it negatively affected the timeline element for `MainOnThisDayElement`, causing it's large dot to appear higher than it should.
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(eventYear: entry.year, snippet: entry.snippet, widgetSize: family)
                    TimelineElementSpacer()
                }
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 16, trailing: 16))
            @unknown default:
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(eventYear: entry.year, snippet: entry.snippet, widgetSize: family)
                    TimelineElementSpacer()
                }
            }
        }
        .widgetURL(entry.contentURL)
    }
}

struct LargeYValuePreferenceKey: PreferenceKey {
    typealias value = CGFloat
    static var defaultValue: CGFloat = 20
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SmallYValuePreferenceKey: PreferenceKey {
    typealias value = CGFloat
    static var defaultValue: CGFloat = 20
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TimelineView<Content: View>: View {
    enum DotStyle {
        case large, small, none
    }

    @SwiftUI.State private var circleYOffset: CGFloat = 0
    var dotStyle: DotStyle
    var isLineTopFaded: Bool
    var isLineBottomFaded: Bool
    var mainView: Content // need to set this as state maybe?

    var body: some View {
        let lineWidth: CGFloat = 1
        HStack {
            ZStack(alignment: .top) {
                TimelinePathElement()
                    .stroke(lineWidth: lineWidth)
                switch dotStyle {
                case .large: TimelineLargeCircleElement(lineWidth: lineWidth, circleYOffset: circleYOffset)
                case .small: TimelineSmallCircleElement(lineWidth: lineWidth, circleYOffset: circleYOffset)
                case .none: EmptyView()
                }
            }
                .frame(width: TimelineLargeCircleElement.largeCircleHeight)
                .foregroundColor(mainColor)
            mainView
        }
        .onPreferenceChange(SmallYValuePreferenceKey.self, perform: { yOffset in
            if dotStyle == .small {
                self.circleYOffset = yOffset
                print("TimelineViewSmall new size: \(yOffset) for dotStyle \(dotStyle)") // DON'T COMMIT THIS
            }
        })
        .onPreferenceChange(LargeYValuePreferenceKey.self, perform: { yOffset in
            if dotStyle == .large {
                self.circleYOffset = yOffset
                print("TimelineViewLarge new size: \(yOffset) for dotStyle \(dotStyle)") // DON'T COMMIT THIS
            }
        })
    }
}

/// This is extremely hacky. Once adding padding to views and/or a Spacer() view, the timeline portion of view doesn't take up the full vertical spacce that it should. After exploring numerous other options, I went with this choice - adding some arbitrary extra length to each end of the line. Someday when SwiftUI layout works better, we can remove the -15 and +20.
struct TimelinePathElement: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY - 15))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + 20))
        return path
    }
}

struct TimelineSmallCircleElement: View {
    static let smallCircleHeight: CGFloat = 9.0
    let lineWidth: CGFloat
    let circleYOffset: CGFloat

    var body: some View {
        Circle()
        .overlay(
            Circle()
           .stroke(mainColor, lineWidth: lineWidth)
        ).foregroundColor(.white)
            .frame(width: TimelineSmallCircleElement.smallCircleHeight, height: TimelineSmallCircleElement.smallCircleHeight)
            .padding(EdgeInsets(top: circleYOffset, leading: 0, bottom: 0, trailing: 0))
    }
}

struct TimelineLargeCircleElement: View {
    static let largeCircleHeight: CGFloat = 17.0

    let lineWidth: CGFloat
    let circleYOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
        Circle()
            .stroke(mainColor, lineWidth: lineWidth)
            .overlay(
                Circle()
                .overlay(
                    Circle()
                    .stroke(mainColor, lineWidth: lineWidth)
                    .foregroundColor(mainColor)
                )
                    .frame(width: TimelineSmallCircleElement.smallCircleHeight, height: TimelineSmallCircleElement.smallCircleHeight)
            )
            .frame(width: geometry.size.width, height: geometry.size.width)
            .padding(.top, circleYOffset)
        }
    }
}

struct OnThisDayHeaderElement: View {
    let date: Date
    let minYear: String
    let maxYear: String

    var body: some View {
        Text(WMFLocalizedString("widget-onthisday-name", value: "On this day", comment: "Name of 'On this day' view in iOS widget gallery"))
            .foregroundColor(grayColor)
            .font(.subheadline)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        // TODO: Update next line to the language being used instead of nil
        Text(DateFormatter.wmf_monthNameDayNumberGMTFormatter(for: nil).string(from: date))
            .font(.title2)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
//            let yearsString = String(format: WMFLocalizedString("on-this-day-detail-header-date-range", language: language, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the oldest event year - i.e. '300 BC', %2$@ is replaced with string version of the most recent event year - i.e. '2006', "), locale: locale, lastEventEraString, firstEventEraString)
        Text(verbatim: "\(minYear) - \(maxYear)")
            .foregroundColor(grayColor)
            .font(.subheadline)
            .bold()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimelineElementSpacer: View {
    var body: some View {
        TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView: Spacer())
    }
}

struct MainOnThisDayElement: View {
    let eventYearPadding: CGFloat = 16.0

    var eventYear: Int?
    var snippet: String?
    var widgetSize: WidgetFamily

    /// For unknown reasons, the layout of the `TimelineView` for a large widget is different from the rest. (A larger comment is above.) One side affect is that (as of iOS 14, beta 6) the large dot is not properly centered on the large widget. This `isLargeWidget` boolean allows us to manually correct for the error.

    var body: some View {
        VStack(spacing: 0) {
            if let eventYear = eventYear, let currentYear = Calendar.current.dateComponents([.year], from: Date()).year {
                TimelineView(dotStyle: .large, isLineTopFaded: true, isLineBottomFaded: false, mainView:
                        Text(verbatim: "\(eventYear)")
                            .font(.subheadline)
                            .foregroundColor(mainColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay (
                                GeometryReader { geometryProxy in
                                  Color.clear
                                    .preference(key: LargeYValuePreferenceKey.self, value: (widgetSize == .systemLarge ? 4 : 2) + startYOfCircle(viewHeight: geometryProxy.size.height, circleHeight: TimelineLargeCircleElement.largeCircleHeight))
                                }
                            )
                            .padding(.top, eventYearPadding)
                )
                TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
                        Text(String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: nil), (currentYear-eventYear)))
                            .font(.caption)
                            .foregroundColor(grayColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 3)
                )
            }
            if let snippet = snippet {
                TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
                        Text(snippet)
                            .font(.caption)
                            .lineLimit(3)
                                // this makes the top dot move :BIGMAD:
//                            .lineLimit(widgetSize == .systemSmall ? nil : 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 9)
                            .fixedSize(horizontal: false, vertical: true)
                )
            }
        }
    }
}

struct ArticleRectangleElement: View {
    var article: WMFFeedArticlePreview
    let image: UIImage?
    let link: URL

    var body: some View {
        TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
            Link(destination: link) {
                HStack(spacing: 9) {
                    VStack {
                        Text(article.displayTitle)
                            .font(.caption)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let description = article.descriptionOrSnippet {
                            Text(description)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(grayColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36, alignment: .center)
                            .cornerRadius(2.0)
                    }
                }
                    .padding(9)
                    .background(
                        RoundedRectangle(cornerRadius: 2.0)
                            .shadow(color: silverColor, radius: 4.0, x: 0, y: 2)
                            .foregroundColor(.white)
                    )
                    .padding([.top, .bottom], 9)
                    .padding([.trailing], 35)
            }
        )
    }
}

struct OnThisDayAdditionalEventsElement: View {
    let otherEventsCount: Int

    var body: some View {
        if otherEventsCount > 0 {
            TimelineView(dotStyle: .small, isLineTopFaded: true, isLineBottomFaded: false, mainView:
//            Button(action: {}) {
                    Text(String.localizedStringWithFormat(WMFLocalizedString("on-this-day-footer-with-event-count", value: "%1$d more historical events on this day", comment: "Footer for presenting user option to see longer list of 'On this day' articles. %1$@ will be substituted with the number of events"), otherEventsCount))
                        .font(.footnote)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(mainColor)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
//                        .layoutPriority(1.5)
//            }
//            .frame(alignment: .top)
                .overlay (
                    GeometryReader { geometryProxy in
                      Color.clear
                        .preference(key: SmallYValuePreferenceKey.self, value: startYOfCircle(viewHeight: geometryProxy.size.height, circleHeight: TimelineSmallCircleElement.smallCircleHeight))
                    }
                )
            )
        }
    }
}

private func startYOfCircle(viewHeight: CGFloat, circleHeight: CGFloat) -> CGFloat {
    return (viewHeight - circleHeight)/2
}

// MARK: - Preview

struct OnThisDayDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        OnThisDayView(entry: OnThisDayData.shared.placeholderEntry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
