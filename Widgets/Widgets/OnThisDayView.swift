import WidgetKit
import SwiftUI
//import WMF
import UIKit

// MARK: - Views

struct OnThisDayView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PictureOfTheDayProvider.Entry

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            switch family {
            case .systemLarge:
                VStack(spacing: 0) {
                    OnThisDayHeaderElement()
                    Spacer(minLength: 10)
                    VStack(alignment: .leading, spacing: -10) {
                        MainOnThisDayElement()
                        ArticleRectangleElement()
                        OnThisDayAdditionalEventsElement()
                    }
                }
                    .padding()
            case .systemSmall:
                MainOnThisDayElement()
            case .systemMedium:
                VStack(alignment: .leading, spacing: -10) {
                    MainOnThisDayElement()
                    OnThisDayAdditionalEventsElement()
                }
            @unknown default:
                MainOnThisDayElement()
            }
        }
        .widgetURL(entry.contentURL)
    }
}

struct TimelineView<Content: View>: View {
    enum DotStyle {
        case large, small, none
    }

    var dotStyle: DotStyle
    var isLineTopFaded: Bool
    var isLineBottomFaded: Bool
    var mainView: Content

    var body: some View {
        HStack {
            TimelinePathElement()
                .stroke(lineWidth: 3.0)
                .foregroundColor(.green)
                .frame(width: 10)
            mainView
        }
    }
}

struct TimelinePathElement: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct OnThisDayHeaderElement: View {
    var body: some View {
        Text("On this day header")
            .font(.subheadline)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text("Date in larger text")
            .font(.headline)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text("Year range")
            .font(.subheadline)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MainOnThisDayElement: View {
    var body: some View {
        TimelineView(dotStyle: .large, isLineTopFaded: true, isLineBottomFaded: false, mainView: DateEventElement())
    }
}

struct DateEventElement: View {
    var body: some View {
        VStack {
            Text("2003")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("14 years ago")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla p")
                .lineLimit(3)
        }
    }
}

struct ArticleRectangleElement: View {
    var body: some View {
        TimelineView(dotStyle: .none, isLineTopFaded: false, isLineBottomFaded: false, mainView:
            HStack {
                VStack {
                    Text("Article Name")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Short article description that gets cut off one line into ellipsis")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Image("W") // replace this w/ Image(uiImage: "blah") when it's dynamic
                    .resizable()
                    .frame(width: 40, height: 54, alignment: .center)
                    .scaledToFill()
            }
                .padding(5)
                .background(RoundedRectangle(cornerRadius: 5.0).foregroundColor(.gray))
        )
    }
}

struct OnThisDayAdditionalEventsElement: View {
    var body: some View {
        TimelineView(dotStyle: .small, isLineTopFaded: true, isLineBottomFaded: false, mainView:
            Button(action: {}) {
                Text("45 more items if you click here in the next 20 seconds")
                    .frame(maxWidth: .infinity, alignment: .leading)
            })
    }
}

// MARK: - Preview

struct OnThisDayDayWidget_Previews: PreviewProvider {
    static var previews: some View {
        OnThisDayView(entry: PictureOfTheDayData.shared.placeholderEntry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
