import SwiftUI
import WidgetKit

public struct WMFReadingChallengeWidgetView: View {

    @ObservedObject var viewModel: WMFReadingChallengeWidgetViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.widgetFamily) var widgetFamily

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    // MARK: - Init

    public init(viewModel: WMFReadingChallengeWidgetViewModel) {
        self.viewModel = viewModel
    }

    private var isStreakState: Bool {
        switch viewModel.state {
        case .streakOngoingRead, .streakOngoingNotYetRead:
            return true
        default:
            return false
        }
    }

    public var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallView
        case .systemMedium:
            if isStreakState {
                mediumStreak
            } else {
                mediumView
            }
        default:
            smallView
        }
    }

    var wIconOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Image("W")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 0)
                    .padding(16)
            }
            Spacer()
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        if viewModel.displaySet.button1Title != nil {
            return AnyView(oneButtonSmallView)
        } else {
            return AnyView(noButtonsSmallView)
        }
    }
    
    private var noButtonsSmallView: some View {
        ZStack {
            viewModel.displaySet.color
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                
                HStack {
                    if let icon = viewModel.displaySet.icon {
                        Image(uiImage: icon)
                            .foregroundStyle(viewModel.displaySet.color2)
                    }

                    Text(viewModel.displaySet.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundColor(viewModel.displaySet.color2)
                }
            }
            .padding()
            wIconOverlay
                .frame(maxWidth: .infinity, alignment: .topTrailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var oneButtonSmallView: some View {
        ZStack {
            viewModel.displaySet.color
                .ignoresSafeArea()
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
                   let button1URL = viewModel.displaySet.button1URL,
                   let icon = viewModel.displaySet.button1Icon {
                    Link(destination: button1URL) {
                        HStack {
                            Image(icon)
                                .resizable()
                            Text(button1Title)
                                .font(Font(WMFFont.for(.semiboldSubheadline)))
                                .foregroundColor(viewModel.displaySet.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.displaySet.color2)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()
            wIconOverlay
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium View

    var mediumView: some View {
        // todo as needed - separate out into no buttons, one button, etc.
        ZStack(alignment: .topTrailing) {
            viewModel.displaySet.color
                .ignoresSafeArea()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    HStack {
                        if let icon = viewModel.displaySet.icon {
                            Image(uiImage: icon)
                                // todo fix
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
                                    Image(button1Icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                    Text(button1Title)
                                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                                        .foregroundColor(viewModel.displaySet.color)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(viewModel.displaySet.color2)
                                .clipShape(Capsule())
                            }
                        }
                        if let button2Title = viewModel.displaySet.button2Title,
                           let button2URL = viewModel.displaySet.button2URL,
                           let button2Icon = viewModel.displaySet.button2Icon {
                            Link(destination: button2URL) {
                                HStack(spacing: 4) {
                                    Image(button2Icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                    Text(button2Title)
                                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                                        .foregroundColor(viewModel.displaySet.color)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(viewModel.displaySet.color2)
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
    
    private var mediumStreak: some View {
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
        let progress = max(0, min(CGFloat(12 - 1) / CGFloat(24), 1))
        let progressColor = viewModel.displaySet.color3 ?? viewModel.displaySet.color2

        return HStack(spacing: 8) {
            calendarLabel(1)

            GeometryReader { geo in
                let trackWidth = geo.size.width
                let thumbOffset = progress * trackWidth - 9.5

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white)
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Capsule()
                                .stroke(viewModel.displaySet.color2.opacity(0.3), lineWidth: 0.5)
                        )

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
