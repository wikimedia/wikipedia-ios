import SwiftUI
import WidgetKit

public struct WMFReadingChallengeWidgetView: View {

    @ObservedObject var viewModel: WMFReadingChallengeWidgetViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.widgetFamily) var widgetFamily

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var buttonBackground: Color {
        Color(uiColor: theme.link)
    }

    private var buttonForeground: Color {
        Color(uiColor: theme.paperBackground)
    }

    // MARK: - Init

    public init(viewModel: WMFReadingChallengeWidgetViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            viewModel.displaySet.color
                .ignoresSafeArea()
            switch widgetFamily {
            case .systemSmall:
                smallView
            case .systemMedium:
                switch viewModel.state {
                case .streakOngoingRead:
                    mediumStreakView
                case .streakOngoingNotYetRead:
                    mediumTwoButtonView
                case .notEnrolled, .notLiveYet, .challengeRemoved, .enrolledNotStarted:
                    notEnrolledMediumView
                default:
                    mediumView
                }
            default:
                smallView
            }
        }
    }

    // MARK: - W Icon Overlay

    var wIconOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Image("W")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26)
                    .foregroundColor(buttonForeground)
                    .shadow(color: Color(uiColor: theme.text).opacity(0.25), radius: 4, x: 0, y: 0)
                    .padding(16)
            }
            Spacer()
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        switch viewModel.state {
        case .notEnrolled, .notLiveYet, .challengeRemoved, .enrolledNotStarted:
            return AnyView(notEnrolledSmallView)
        default:
            if viewModel.displaySet.button1Title != nil {
                return AnyView(oneButtonSmallView)
            } else {
                return AnyView(noButtonsSmallView)
            }
        }
    }
    
    private var notEnrolledSmallView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                Spacer()
                if let button1Title = viewModel.displaySet.button1Title,
                   let button1URL = viewModel.displaySet.button1URL {
                    Link(destination: button1URL) {
                        Text(button1Title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundColor(buttonForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            wIconOverlay
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noButtonsSmallView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                HStack {
                    switch viewModel.state {
                    case .streakOngoingNotYetRead:
                        if let uiImage = UIImage(named: "flameWarning", in: .module, with: nil) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(viewModel.displaySet.color2)
                                .scaledToFit()
                                .frame(width: 30)
                        }
                    default:
                        if let icon = viewModel.displaySet.icon {
                            Image(uiImage: icon)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(viewModel.displaySet.color2)
                        }
                    }
                    Text(viewModel.displaySet.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundColor(viewModel.displaySet.color2)
                }
            }
            .padding()
            wIconOverlay
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Icon is now optional — renders button with or without leading icon
    private var oneButtonSmallView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                Text(viewModel.displaySet.title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundColor(viewModel.displaySet.color2)
                if let subtitle = viewModel.displaySet.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.mediumSubheadline)))
                        .foregroundColor(viewModel.displaySet.color2)
                }
                if let button1Title = viewModel.displaySet.button1Title,
                   let button1URL = viewModel.displaySet.button1URL {
                    Link(destination: button1URL) {
                        HStack {
                            if let icon = viewModel.displaySet.button1Icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .foregroundStyle(buttonForeground)
                            }
                            Text(button1Title)
                                .font(Font(WMFFont.for(.semiboldSubheadline)))
                                .foregroundColor(buttonForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(buttonBackground)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()
            wIconOverlay
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium View (generic: streak completed, incomplete, etc.)

    private var mediumView: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    HStack {
                        if let icon = viewModel.displaySet.icon {
                            Image(uiImage: icon)
                        }
                        Text(viewModel.displaySet.title)
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundColor(viewModel.displaySet.color2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let subtitle = viewModel.displaySet.subtitle {
                        Text(subtitle)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(viewModel.displaySet.color2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        if let button1Title = viewModel.displaySet.button1Title,
                           let button1URL = viewModel.displaySet.button1URL,
                           let button1Icon = viewModel.displaySet.button1Icon {
                            Link(destination: button1URL) {
                                HStack(spacing: 4) {
                                    Image(uiImage: button1Icon)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(buttonForeground)
                                        .frame(width: 14, height: 14)
                                    Text(button1Title)
                                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                                        .foregroundColor(buttonForeground)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(buttonBackground)
                                .clipShape(Capsule())
                            }
                        }
                        if let button2Title = viewModel.displaySet.button2Title,
                           let button2URL = viewModel.displaySet.button2URL,
                           let button2Icon = viewModel.displaySet.button2Icon {
                            Link(destination: button2URL) {
                                HStack(spacing: 4) {
                                    Image(uiImage: button2Icon)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(buttonForeground)
                                        .frame(width: 14, height: 14)
                                    Text(button2Title)
                                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                                        .foregroundColor(buttonForeground)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(buttonBackground)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110)
                        .padding(.trailing, 8)
                }
            }
            wIconOverlay
        }
    }

    // MARK: - Not Enrolled Medium View
    
    private var notEnrolledMediumView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.displaySet.title)
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundColor(viewModel.displaySet.color2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle = viewModel.displaySet.subtitle {
                            Text(subtitle)
                                .font(Font(WMFFont.for(.callout)))
                                .foregroundColor(viewModel.displaySet.color2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 80, alignment: .bottomLeading)
                            .padding([.trailing, .top], 8)
                    }
                }

                Spacer()

                if let button1Title = viewModel.displaySet.button1Title,
                   let button1URL = viewModel.displaySet.button1URL {
                    Link(destination: button1URL) {
                        Text(button1Title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundColor(buttonForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            wIconOverlay
        }
    }

    // MARK: - Medium 2 Button View

    private var mediumTwoButtonView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            if let flameImage = UIImage(named: "flameWarning", in: .module, with: nil) {
                                Image(uiImage: flameImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(viewModel.displaySet.color2)
                            }
                            Text(viewModel.displaySet.title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundColor(viewModel.displaySet.color2)
                        }
                        if let subtitle = viewModel.displaySet.subtitle {
                            Text(subtitle)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundColor(viewModel.displaySet.color2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110)
                            .padding(.trailing, 8)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if let button1Title = viewModel.displaySet.button1Title,
                       let button1URL = viewModel.displaySet.button1URL,
                       let button1Icon = viewModel.displaySet.button1Icon {
                        Link(destination: button1URL) {
                            HStack(spacing: 4) {
                                Image(uiImage: button1Icon)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(buttonForeground)
                                    .frame(width: 14, height: 14)
                                Text(button1Title)
                                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                                    .foregroundColor(buttonForeground)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                        }
                    }
                    if let button2Title = viewModel.displaySet.button2Title,
                       let button2URL = viewModel.displaySet.button2URL,
                       let button2Icon = viewModel.displaySet.button2Icon {
                        Link(destination: button2URL) {
                            HStack(spacing: 4) {
                                Image(uiImage: button2Icon)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(buttonForeground)
                                    .frame(width: 14, height: 14)
                                Text(button2Title)
                                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                                    .foregroundColor(buttonForeground)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            wIconOverlay
        }
    }

    // MARK: - Medium Streak View

    private var mediumStreakView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            if let icon = WMFSFSymbolIcon.for(symbol: .trophy, font: .boldCaption1, paletteColors: [UIColor(viewModel.displaySet.color2)]) {
                                Image(uiImage: icon)
                                    .font(Font(WMFFont.for(.boldCaption1)))
                                    .foregroundColor(viewModel.displaySet.color2)
                            }
                            if let subtitle = viewModel.displaySet.subtitle {
                                Text(subtitle)
                                    .font(Font(WMFFont.for(.boldCaption1)))
                                    .foregroundColor(viewModel.displaySet.color2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 30)
                        HStack {
                            if let icon = WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1, paletteColors: [UIColor(viewModel.displaySet.color2)]) {
                                Image(uiImage: icon)
                                    .font(Font(WMFFont.for(.boldTitle1)))
                                    .foregroundColor(viewModel.displaySet.color2)
                            }
                            Text(viewModel.displaySet.title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundColor(viewModel.displaySet.color2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110)
                            .padding(.trailing, 8)
                    }
                }
                if case .streakOngoingRead(let streak) = viewModel.state {
                    streakProgressBar(streak: streak)
                } else if case .streakOngoingNotYetRead(let streak) = viewModel.state {
                    streakProgressBar(streak: streak)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            wIconOverlay
        }
    }

    // MARK: - Streak Progress Bar

    private func calendarLabel(_ number: Int) -> some View {
        ZStack {
            if let calendarImage = UIImage(named: "calendar", in: .module, with: nil) {
                Image(uiImage: calendarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(viewModel.displaySet.color2)
            }
            Text("\(number)")
                .font(Font(WMFFont.for(.boldCaption1)))
                .foregroundColor(viewModel.displaySet.color2)
                .padding(.top, 4)
        }
        .frame(width: 32, height: 32)
    }

    private func streakProgressBar(streak: Int) -> some View {
        let progress = max(0, min(CGFloat(streak - 1) / CGFloat(24), 1))
        let progressColor = viewModel.displaySet.color3 ?? viewModel.displaySet.color2

        return HStack(spacing: 8) {
            calendarLabel(1)
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let thumbOffset = progress * trackWidth - 9.5
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(buttonForeground)
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                    Capsule()
                        .fill(progressColor)
                        .frame(width: max(0, progress * trackWidth), height: 8)
                    Circle()
                        .fill(viewModel.displaySet.color2)
                        .frame(width: 19, height: 19)
                        .offset(x: max(0, thumbOffset))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 19)
            calendarLabel(25)
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(viewModel.displaySet.color2, lineWidth: 1.5)
        )
        .padding(.vertical, 8)
    }
}
