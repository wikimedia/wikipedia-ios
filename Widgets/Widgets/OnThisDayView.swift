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
    @Environment(\.widgetFamily) private var widgetSize
    var entry: OnThisDayProvider.Entry

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch widgetSize {
            case .systemLarge:
                VStack(alignment: .leading, spacing: 0) {
                    OnThisDayHeaderElement(monthDay: entry.monthDay, minYear: entry.earliestYear, maxYear: entry.latestYear)
                        .padding(.bottom, 9)
                    MainOnThisDayTopElement(monthDay: entry.monthDay, eventYear: entry.eventYear, fullDate: entry.fullDate)
                    /// The full `MainOnThisDayElement` is not used in the large widget. We need the `Spacer` and the `eventSnippet` text to be part of the same `VStack` to render correctly. (Otherwise, the "text is so long it must be cutoff" and/or the "text is so short we need blank space at the bottom" scenario perform incorrectly.)
                    if let eventSnippet = entry.eventSnippet, let title = entry.articleTitle, let articleSnippet = entry.articleSnippet {
                        ArticleRectangleElement(eventSnippet: eventSnippet, title: title, description: articleSnippet, image: entry.articleImage, link: entry.articleURL ?? entry.contentURL)
                            .padding(.top, 9)
                            .layoutPriority(1.0)
                    }
                    OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                }
                .padding([.top, .leading, .trailing], 16)
            case .systemMedium:
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, fulLDate: entry.fullDate, snippet: entry.eventSnippet)
                    OnThisDayAdditionalEventsElement(otherEventsCount: entry.otherEventsCount)
                }
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 16))
            case .systemSmall:
                MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, fulLDate: entry.fullDate, snippet: entry.eventSnippet)
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 16))
            @unknown default:
                MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, fulLDate: entry.fullDate, snippet: entry.eventSnippet)
                .padding(EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 16))
            }
        }
        .overlay(errorBox)
        .environment(\.layoutDirection, entry.isRTLLanguage ? .rightToLeft : .leftToRight)
        .widgetURL(entry.contentURL)
    }

    var errorBox: some View {
        if !entry.doesLanguageSupportOnThisDay {
            return AnyView(MissingOnThisDaySquare())
        } else {
            return AnyView(EmptyView())
        }
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

struct MissingOnThisDaySquare: View {
    @Environment(\.widgetFamily) private var widgetSize

    var body: some View {
        Rectangle().foregroundColor(Color(UIColor.base30))
            .overlay(
                Text(WMFLocalizedString("on-this-day-language-does-not-support-error", value: "English Wikipedia does not support On this day", comment: "error message shown when the language's Wikipedia does not have 'On this day' feature. Instead of 'English Wikipedia', use the language being translated into"))
                    .font(.caption)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .foregroundColor(.white)
                    .padding([.leading, .top, .bottom], 16)
                    .padding(.trailing, widgetSize == .systemSmall ? 16 : 90)
            )
    }
}

struct NoInternetSquare: View {
    @Environment(\.widgetFamily) private var widgetSize

    var body: some View {
        Rectangle().foregroundColor(Color(white: 22/255))
            .overlay(
                Text(WMFLocalizedString("on-this-day-no-internet-error", value: "No data available", comment: "error message shown when device is not connected to internet"))
                    .font(.caption)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .foregroundColor(.white)
                    .padding([.leading, .top, .bottom], 16)
                    .padding(.trailing, widgetSize == .systemSmall ? 16 : 90)
            )
    }
}

struct TimelineView<Content: View>: View {
    enum DotStyle {
        case large, small, none
    }
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) private var widgetSize

    @SwiftUI.State private var circleYOffset: CGFloat = 0
    var dotStyle: DotStyle
    var isLineTopFaded: Bool
    var isLineBottomFaded: Bool
    var mainView: Content

    var gradient: LinearGradient {
        if isLineTopFaded {
            let colorGradient = Gradient(stops: [
                Gradient.Stop(color: OnThisDayColors.widgetBackgroundColor(colorScheme), location: 0),
                Gradient.Stop(color: OnThisDayColors.blueColor(colorScheme), location: 0.65)
            ])
            return LinearGradient(gradient: colorGradient, startPoint: .top, endPoint: .bottom)
        /// No bottom gradient on large widgets. See Phab for details: https://phabricator.wikimedia.org/T259840#6448845
        } else if isLineBottomFaded && widgetSize != .systemLarge {
            let colorGradient = Gradient(stops: [
                // Small widgets have a much larger final section, and thus gradient starts later.
                Gradient.Stop(color: OnThisDayColors.blueColor(colorScheme), location: (widgetSize == .systemSmall ? 0.75 : 0.45)),
                Gradient.Stop(color: OnThisDayColors.widgetBackgroundColor(colorScheme), location: 1.0)
            ])
            return LinearGradient(gradient: colorGradient, startPoint: .top, endPoint: .bottom)
        } else {
            // plain blue
            return LinearGradient(gradient: Gradient(colors: [OnThisDayColors.blueColor(colorScheme)]), startPoint: .top, endPoint: .bottom)
        }
    }

    var body: some View {
        let lineWidth: CGFloat = 1
        HStack(alignment: .top) {
            ZStack(alignment: .top) {
                TimelinePathElement()
                    .stroke(lineWidth: lineWidth)
                    .fill(gradient)
                switch dotStyle {
                case .large: TimelineLargeCircleElement(lineWidth: lineWidth, circleYOffset: circleYOffset)
                case .small: TimelineSmallCircleElement(lineWidth: lineWidth, circleYOffset: circleYOffset)
                case .none: EmptyView()
                }
            }
            .frame(width: TimelineLargeCircleElement.largeCircleHeight)
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
                )
                    .frame(width: TimelineSmallCircleElement.smallCircleHeight, height: TimelineSmallCircleElement.smallCircleHeight)
                    .foregroundColor(OnThisDayColors.blueColor(colorScheme))
            )
            .frame(width: geometry.size.width, height: geometry.size.width)
            .padding(.top, circleYOffset)
        }
    }
}

struct OnThisDayHeaderElement: View {
    @Environment(\.colorScheme) var colorScheme
    let language = MWKDataStore.shared().languageLinkController.appLanguage

    let monthDay: String
    let minYear: String
    let maxYear: String

    var body: some View {
        /// Custom spacing (handled by middle text element) from 10 Sept 2020 video call w/ Carolyn, the app designer.
        VStack(spacing: 0) {
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
                .padding(.top, 5)
                .padding(.bottom, 7)
            Text(CommonStrings.onThisDayHeaderDateRangeMessage(with: language?.languageCode, locale: NSLocale.wmf_locale(for: language?.languageCode), lastEvent: minYear, firstEvent: maxYear))
                .foregroundColor(OnThisDayColors.grayColor(colorScheme))
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MainOnThisDayElement: View {
    @Environment(\.widgetFamily) private var widgetSize

    var monthDay: String
    var eventYear: Int
    var fulLDate: String
    var snippet: String?

    /// For unknown reasons, the layout of the `TimelineView` for a large widget is different from the rest. (A larger comment is above.) One side affect is that (as of iOS 14, beta 6) the large dot is not properly centered on the large widget. This `isLargeWidget` boolean allows us to manually correct for the error.

    var body: some View {
        VStack(spacing: 0) {
            MainOnThisDayTopElement(monthDay: monthDay, eventYear: eventYear, fullDate: fulLDate)
            if let snippet = snippet {
                TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: widgetSize == .systemSmall, mainView:
                        Text(snippet)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 9)
                            .padding(.bottom, (widgetSize == .systemSmall ? 16 : 8))
                ).layoutPriority(1.0)
            }
        }.layoutPriority(1.0)
    }
}

struct MainOnThisDayTopElement: View {
    let eventYearPadding: CGFloat = 16.0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) private var widgetSize

    var monthDay: String
    var eventYear: Int
    var fullDate: String

    var firstLineText: String {
        if widgetSize != .systemMedium {
            return "\(eventYear)"
        } else {
            return fullDate
        }
    }

    private var secondLineText: String? {
        let language = MWKDataStore.shared().languageLinkController.appLanguage
        if widgetSize == .systemSmall {
            return monthDay
        } else if let currentYear = Calendar.current.dateComponents([.year], from: Date()).year {
            return String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(forWikiLanguage: language?.languageCode), (currentYear-eventYear))
        } else {
            return nil
        }
    }

    var body: some View {
        if let secondLineText = secondLineText {
            TimelineView(dotStyle: .large, isLineTopFaded: true, isLineBottomFaded: false, mainView:
                    Text(firstLineText)
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
                    Text(secondLineText)
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
            TimelineView(dotStyle: .small, isLineTopFaded: false, isLineBottomFaded: true, mainView:
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
                .padding(.bottom, 16)
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
