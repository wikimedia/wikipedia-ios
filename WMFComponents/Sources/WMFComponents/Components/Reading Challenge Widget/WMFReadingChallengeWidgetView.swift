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

    public var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
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
        return AnyView(oneButtonSmallView)
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
                        if let image = WMFSFSymbolIcon.for(symbol: .flameFill, font: .boldTitle1) {
                            Image(uiImage: image)
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
                   let button1URL = viewModel.displaySet.button1URL {
                    Link(destination: button1URL) {
                        Text(button1Title)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .foregroundColor(viewModel.displaySet.color)
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
            ZStack(alignment: .topTrailing) {
                viewModel.displaySet.color
                    .ignoresSafeArea()
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("B")
                            .font(Font(WMFFont.for(.boldTitle3)))
                            .foregroundColor(viewModel.displaySet.color2)
                        // ...existing code...
                        if let subtitle = viewModel.displaySet.subtitle {
                            Text(subtitle)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundColor(viewModel.displaySet.color2)
                        }
                    }
                    Spacer()
                }
                .padding()
                wIconOverlay
            }
    }
}
