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
    @Environment(\.sizeCategory) var textSize
    var entry: OnThisDayProvider.Entry

    var needsVerticalCompression: Bool {
        return textSize == .extraExtraExtraLarge
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch widgetSize {
            case .systemLarge:
                VStack(alignment: .leading, spacing: 0) {
                    OnThisDayHeaderElement(widgetTitle: entry.onThisDayTitle, yearRange: entry.yearRange, monthDay: entry.monthDay)
                        .padding(.bottom, needsVerticalCompression ? 3 : 9)
                    MainOnThisDayTopElement(monthDay: entry.monthDay, eventYear: entry.eventYear, eventYearsAgo: entry.eventYearsAgo, fullDate: entry.fullDate)
                    /// The full `MainOnThisDayElement` is not used in the large widget. We need the `Spacer` and the `eventSnippet` text to be part of the same `VStack` to render correctly. (Otherwise, the "text is so long it must be cutoff" and/or the "text is so short we need blank space at the bottom" scenario perform incorrectly.)
                    if let eventSnippet = entry.eventSnippet, let title = entry.articleTitle, let articleSnippet = entry.articleSnippet {
                        LargeWidgetMiddleSection(eventSnippet: eventSnippet, title: title, description: articleSnippet, image: entry.articleImage, link: entry.articleURL ?? entry.contentURL)
                            .padding(.top, needsVerticalCompression ? 3 : 9)
                            .layoutPriority(1.0)
                    }
                    OnThisDayAdditionalEventsElement(otherEventsText: entry.otherEventsText)
                }
                .padding([.top, .leading, .trailing], 16)
            case .systemMedium:
                VStack(alignment: .leading, spacing: 0) {
                    MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, eventYearsAgo: entry.eventYearsAgo, fullDate: entry.fullDate, snippet: entry.eventSnippet)
                    OnThisDayAdditionalEventsElement(otherEventsText: entry.otherEventsText)
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            case .systemSmall:
                MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, eventYearsAgo: entry.eventYearsAgo, fullDate: entry.fullDate, snippet: entry.eventSnippet)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            @unknown default:
                MainOnThisDayElement(monthDay: entry.monthDay, eventYear: entry.eventYear, eventYearsAgo: entry.eventYearsAgo, fullDate: entry.fullDate, snippet: entry.eventSnippet)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .overlay(errorBox)
        .environment(\.layoutDirection, entry.isRTLLanguage ? .rightToLeft : .leftToRight)
        .widgetURL(entry.contentURL)
    }

    var errorBox: some View {
        if let error = entry.error {
            return AnyView(ErrorSquare(error: error))
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

struct ErrorSquare: View {
    @Environment(\.widgetFamily) private var widgetSize
    let error: OnThisDayData.ErrorType

    var body: some View {
        Rectangle().foregroundColor(error.errorColor)
            .overlay(
                Text(error.errorText)
                    .font(.caption)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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
    @Environment(\.sizeCategory) var textSize
    let widgetTitle: String
    let yearRange: String
    let monthDay: String

    var needsVerticalCompression: Bool {
        return textSize == .extraExtraExtraLarge
    }

    var body: some View {
        /// Custom spacing (handled by middle text element) from 10 Sept 2020 video call w/ Carolyn, the app designer.
        VStack(spacing: 0) {
            Text(widgetTitle)
                .foregroundColor(OnThisDayColors.grayColor(colorScheme))
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(monthDay)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, needsVerticalCompression ? 2 : 5)
                .padding(.bottom, needsVerticalCompression ? 2 : 7)
            Text(yearRange)
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
    var eventYear: String
    var eventYearsAgo: String?
    var fullDate: String
    var snippet: String?

    /// For unknown reasons, the layout of the `TimelineView` for a large widget is different from the rest. (A larger comment is above.) One side affect is that (as of iOS 14, beta 6) the large dot is not properly centered on the large widget. This `isLargeWidget` boolean allows us to manually correct for the error.

    var body: some View {
        VStack(spacing: 0) {
            MainOnThisDayTopElement(monthDay: monthDay, eventYear: eventYear, eventYearsAgo: eventYearsAgo, fullDate: fullDate)
            if let snippet = snippet {
                TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: widgetSize == .systemSmall, mainView:
                        Text(snippet)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 9)
                            .padding(.bottom, (widgetSize == .systemMedium ? 4 : 8))
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
    var eventYear: String
    var eventYearsAgo: String?
    var fullDate: String

    var firstLineText: String {
        if widgetSize != .systemMedium {
            return eventYear
        } else {
            return fullDate
        }
    }

    private var secondLineText: String? {
        if widgetSize == .systemSmall {
            return monthDay
        } else {
            return eventYearsAgo
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

struct LargeWidgetMiddleSection: View {
    let eventSnippet: String
    let title: String
    let description: String
    let image: UIImage?
    let link: URL?

    var body: some View {
        TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
            VStack(alignment: .leading, spacing: 0) {
                Text(eventSnippet)
                    .font(.caption)
                if let link = link {
                    Link(destination: link) {
                        ArticleRectangleBox(title: title, description: description, image: image)
                    }
                } else {
                    ArticleRectangleBox(title: title, description: description, image: image)
                }
                Spacer(minLength: 0)
            }
        )
    }
}

struct ArticleRectangleBox: View {
    @Environment(\.colorScheme) var colorScheme

    let title: String
    let description: String
    let image: UIImage?

    var body: some View {
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
}

struct OnThisDayAdditionalEventsElement: View {
    @Environment(\.colorScheme) var colorScheme

    let otherEventsText: String

    var body: some View {
        TimelineView(dotStyle: .small, isLineTopFaded: false, isLineBottomFaded: true, mainView:
            Text(otherEventsText)
                .font(.footnote)
                .bold()
                .lineLimit(1)
                .foregroundColor(OnThisDayColors.blueColor(colorScheme))
                .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.top, 2)
            .overlay (
                GeometryReader { geometryProxy in
                  Color.clear
                    .preference(key: SmallYValuePreferenceKey.self, value: startYOfCircle(viewHeight: geometryProxy.size.height, circleHeight: TimelineSmallCircleElement.smallCircleHeight, topPadding: 0))
                    /// The padding of 0 is a little arbitrary. These views aren't perfectly laid out in SwiftUI - see the "+20" comment above - and depending on spacing/padding we sometims need to tweak the padding to make this layout properly.
                }
            )
            .padding(.bottom, 16)
        )
    }
}

private func startYOfCircle(viewHeight: CGFloat, circleHeight: CGFloat, topPadding: CGFloat = 0) -> CGFloat {
    return topPadding + ((viewHeight - circleHeight)/2)
}

// MARK: - Preview

struct OnThisDayDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        OnThisDayView(entry: OnThisDayData.shared.placeholderEntryFromLanguage(nil))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
