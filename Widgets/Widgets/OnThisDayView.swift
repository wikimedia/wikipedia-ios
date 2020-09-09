import WidgetKit
import SwiftUI
import WMF
import UIKit

// MARK: - Views

struct OnThisDayColors {
    static func blueColor(_ colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? Color(UIColor.blue50) : Color(UIColor.blue70)
    }

    static func grayColor(_ colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? Color(UIColor.base30) : Color(UIColor.base70)
    }

    static func widgetBackgroundColor(_ colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? .white : .black
    }

    static func boxShadowColor(_ colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? Color(UIColor.base70At55PercentAlpha) : .clear
    }

    static func boxBackgroundColor(_ colorScheme: ColorScheme) -> Color {
        return colorScheme == .light ? .white : Color(red: 34/255, green: 34/255, blue: 34/255)
    }
}

struct OnThisDayView: View {
    @Environment(\.widgetFamily) private var family
    var entry: OnThisDayProvider.Entry

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch family {
            case .systemLarge:
                VStack(alignment: .leading, spacing: 0) {
                    OnThisDayHeaderElement(monthDay: entry.monthDay, minYear: entry.earliestYear, maxYear: entry.latestYear)
                        .padding(.bottom, 9)
                    MainOnThisDayTopElement(eventYear: entry.eventYear, widgetSize: family)
                    /// The full `MainOnThisDayElement` is not used in the large widget. We need the `Spacer` and the `eventSnippet` text to be part of the same `VStack` to render correctly. (Otherwise, the "text is so long it must be cutoff" and/or the "text is so short we need blank space at the bottom" scenario perform incorrectly.)
                    if let eventSnippet = entry.eventSnippet, let title = entry.articleTitle, let articleSnippet = entry.articleSnippet {
                        ArticleRectangleElement(eventSnippet: eventSnippet, title: title, description: articleSnippet, image: entry.articleImage, link: entry.articleURL ?? entry.contentURL)
                            .padding(.top, 9)
                            .layoutPriority(1.0)
                    }
                    OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                }
                .padding(16)
            case .systemMedium:
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(eventYear: entry.eventYear, snippet: entry.eventSnippet, widgetSize: family)
                    OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                }
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 16, trailing: 16))
            case .systemSmall:
                MainOnThisDayElement(eventYear: entry.eventYear, snippet: entry.eventSnippet, widgetSize: family)
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 16, trailing: 16))
            @unknown default:
                MainOnThisDayElement(eventYear: entry.eventYear, snippet: entry.eventSnippet, widgetSize: family)
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 16, trailing: 16))
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
    @Environment(\.colorScheme) var colorScheme

    @SwiftUI.State private var circleYOffset: CGFloat = 0
    var dotStyle: DotStyle
    var isLineTopFaded: Bool
    var isLineBottomFaded: Bool
    var mainView: Content

    var body: some View {
        let lineWidth: CGFloat = 1
        HStack(alignment: .top) {
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
            .foregroundColor(OnThisDayColors.blueColor(colorScheme))
            mainView
        }
        .onPreferenceChange(SmallYValuePreferenceKey.self, perform: { yOffset in
            if dotStyle == .small {
                self.circleYOffset = yOffset
            }
        })
        .onPreferenceChange(LargeYValuePreferenceKey.self, perform: { yOffset in
            if dotStyle == .large {
                self.circleYOffset = yOffset
            }
        })
    }
}

/// This is extremely hacky. Once adding padding to views and/or a Spacer() view, the timeline portion of view doesn't take up the full vertical spacce that it should. After exploring numerous other options, I went with this choice - adding some arbitrary extra length to the end of the line. Someday when SwiftUI layout works better, we can remove the +20.
struct TimelinePathElement: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + 20))
        return path
    }
}

struct TimelineSmallCircleElement: View {
    @Environment(\.colorScheme) var colorScheme

    static let smallCircleHeight: CGFloat = 9.0
    let lineWidth: CGFloat
    let circleYOffset: CGFloat

    var body: some View {
        Circle()
        .overlay(
            Circle()
                .stroke(OnThisDayColors.blueColor(colorScheme), lineWidth: lineWidth)
        ).foregroundColor(OnThisDayColors.widgetBackgroundColor(colorScheme))
            .frame(width: TimelineSmallCircleElement.smallCircleHeight, height: TimelineSmallCircleElement.smallCircleHeight)
            .padding(EdgeInsets(top: circleYOffset, leading: 0, bottom: 0, trailing: 0))
    }
}

struct TimelineLargeCircleElement: View {
    static let largeCircleHeight: CGFloat = 17.0
    @Environment(\.colorScheme) var colorScheme

    let lineWidth: CGFloat
    let circleYOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
        Circle()
            .stroke(OnThisDayColors.blueColor(colorScheme), lineWidth: lineWidth)
            .overlay(
                Circle()
                .overlay(
                    Circle()
                        .stroke(OnThisDayColors.blueColor(colorScheme), lineWidth: lineWidth)
                        .foregroundColor(OnThisDayColors.blueColor(colorScheme))
                )
                    .frame(width: TimelineSmallCircleElement.smallCircleHeight, height: TimelineSmallCircleElement.smallCircleHeight)
            )
            .frame(width: geometry.size.width, height: geometry.size.width)
            .padding(.top, circleYOffset)
        }
    }
}

struct OnThisDayHeaderElement: View {
    @Environment(\.colorScheme) var colorScheme

    let monthDay: String
    let minYear: String
    let maxYear: String

    var body: some View {
        VStack(spacing: 8) {
            Text(WMFLocalizedString("widget-onthisday-name", value: "On this day", comment: "Name of 'On this day' view in iOS widget gallery"))
                .foregroundColor(OnThisDayColors.grayColor(colorScheme))
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(monthDay)
                .font(.title2)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
    //            let yearsString = String(format: WMFLocalizedString("on-this-day-detail-header-date-range", language: language, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the oldest event year - i.e. '300 BC', %2$@ is replaced with string version of the most recent event year - i.e. '2006', "), locale: locale, lastEventEraString, firstEventEraString)

            Text(verbatim: "\(minYear) - \(maxYear)")
                .foregroundColor(OnThisDayColors.grayColor(colorScheme))
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MainOnThisDayElement: View {
    var eventYear: Int
    var snippet: String?
    var widgetSize: WidgetFamily

    /// For unknown reasons, the layout of the `TimelineView` for a large widget is different from the rest. (A larger comment is above.) One side affect is that (as of iOS 14, beta 6) the large dot is not properly centered on the large widget. This `isLargeWidget` boolean allows us to manually correct for the error.

    var body: some View {
        VStack(spacing: 0) {
            MainOnThisDayTopElement(eventYear: eventYear, widgetSize: widgetSize)
            if let snippet = snippet {
                TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
                        Text(snippet)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 9)
                ).layoutPriority(1.0)
            }
        }.layoutPriority(1.0)
    }
}

struct MainOnThisDayTopElement: View {
    let eventYearPadding: CGFloat = 16.0
    @Environment(\.colorScheme) var colorScheme

    var eventYear: Int
    var widgetSize: WidgetFamily

    var dateString: String {
        if widgetSize == .systemLarge {
            return "\(eventYear)"
        } else {
            let now = Date()
            let currentComponents = Calendar.current.dateComponents([.month, .day], from: now)
            let dateComponentsInPast = DateComponents(year: eventYear, month: currentComponents.month, day: currentComponents.day)
            guard let dateInPast = Calendar.current.date(from: dateComponentsInPast) else {
                return "\(eventYear)"
            }

            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .long
            return dateFormatter.string(from: dateInPast)
        }
    }

    var body: some View {
        if let currentYear = Calendar.current.dateComponents([.year], from: Date()).year {
            TimelineView(dotStyle: .large, isLineTopFaded: true, isLineBottomFaded: false, mainView:
                    Text(verbatim: dateString)
                        .font(.subheadline)
                        .foregroundColor(OnThisDayColors.blueColor(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay (
                            GeometryReader { geometryProxy in
                              Color.clear
                                .preference(key: LargeYValuePreferenceKey.self, value: startYOfCircle(viewHeight: geometryProxy.size.height, circleHeight: TimelineLargeCircleElement.largeCircleHeight, topPadding: eventYearPadding))
                            }
                        )
                        .padding(.top, eventYearPadding)
            )
            TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
                    Text(String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: nil), (currentYear-eventYear)))
                        .font(.caption)
                        .foregroundColor(OnThisDayColors.grayColor(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 3)
            )
        }
    }
}

struct ArticleRectangleElement: View {
    @Environment(\.colorScheme) var colorScheme

    let eventSnippet: String
    let title: String
    let description: String
    let image: UIImage?
    let link: URL

    var body: some View {
        TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
            VStack(alignment: .leading, spacing: 0) {
                Text(eventSnippet)
                    .font(.caption)
                Link(destination: link) {
                    HStack(spacing: 9) {
                        VStack {
                            Text(title)
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let description = description {
                                Text(description)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(OnThisDayColors.grayColor(colorScheme))
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
                                .shadow(color: OnThisDayColors.boxShadowColor(colorScheme), radius: 4.0, x: 0, y: 2)
                                .foregroundColor(OnThisDayColors.boxBackgroundColor(colorScheme))
                        )
                        .padding([.top, .bottom], 9)
                        .padding([.trailing], 35)
                }
                Spacer(minLength: 0)
            }
        )
    }
}

struct OnThisDayAdditionalEventsElement: View {
    @Environment(\.colorScheme) var colorScheme

    let otherEventsCount: Int

    var body: some View {
        if otherEventsCount > 0 {
            TimelineView(dotStyle: .small, isLineTopFaded: true, isLineBottomFaded: false, mainView:
                Text(String.localizedStringWithFormat(WMFLocalizedString("on-this-day-footer-with-event-count", value: "%1$d more historical events on this day", comment: "Footer for presenting user option to see longer list of 'On this day' articles. %1$@ will be substituted with the number of events"), otherEventsCount))
                    .font(.footnote)
                    .bold()
                    .lineLimit(1)
                    .foregroundColor(OnThisDayColors.blueColor(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 8)
                .overlay (
                    GeometryReader { geometryProxy in
                      Color.clear
                        .preference(key: SmallYValuePreferenceKey.self, value: startYOfCircle(viewHeight: geometryProxy.size.height, circleHeight: TimelineSmallCircleElement.smallCircleHeight, topPadding: 4))
                        /// The padding of 4 is a little arbitrary. These views aren't perfectly laid out in SwiftUI - see the "+20" comment above - and we needed an extra 4 points to make this layout properly.
                    }
                )
            )
        }
    }
}

private func startYOfCircle(viewHeight: CGFloat, circleHeight: CGFloat, topPadding: CGFloat = 0) -> CGFloat {
    return topPadding + ((viewHeight - circleHeight)/2)
}

// MARK: - Preview

struct OnThisDayDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        OnThisDayView(entry: OnThisDayData.shared.placeholderEntry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
