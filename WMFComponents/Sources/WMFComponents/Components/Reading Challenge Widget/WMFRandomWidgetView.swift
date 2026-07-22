import SwiftUI
import WidgetKit

public struct WMFRandomWidgetView: View {

    @ObservedObject var viewModel: WMFRandomWidgetViewModel
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

    // MARK: - Design Canvas Size

    private let mediumCanvasWidth: CGFloat = 329
    private let mediumCanvasHeight: CGFloat = 155

    private var traitCollection: UITraitCollection {
        return UITraitCollection(preferredContentSizeCategory: .large)
    }

    // MARK: - Init

    public init(viewModel: WMFRandomWidgetViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            viewModel.displaySet.color
                .ignoresSafeArea()
            switch widgetFamily {
            case .systemSmall:
                smallRandomizerView
            default:
                mediumRandomizerView
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

    // MARK: - Small Randomizer View

    private var smallRandomizerView: some View {
        ZStack {
            VStack(alignment: .center, spacing: 10) {
                if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                    Spacer()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                }
                if let button1Title = viewModel.displaySet.button1Title,
                   let button1URL = viewModel.displaySet.button1URL {
                    Link(destination: button1URL) {
                        HStack {
                            Text(button1Title)
                                .font(Font(WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)))
                                .foregroundColor(buttonForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(buttonBackground)
                        .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            wIconOverlay
        }
    }

    // MARK: - Medium Randomizer View

    private var mediumRandomizerView: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / mediumCanvasWidth, geo.size.height / mediumCanvasHeight)

            ZStack {
                VStack(alignment: .center, spacing: 10) {
                    if let uiImage = UIImage(named: viewModel.displaySet.image, in: .module, with: nil) {
                        Spacer()
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 100)
                    }
                    if let button1Title = viewModel.displaySet.button1Title,
                       let button1URL = viewModel.displaySet.button1URL {
                        Link(destination: button1URL) {
                            HStack {
                                Text(button1Title)
                                    .font(Font(WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)))
                                    .foregroundColor(buttonForeground)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                wIconOverlay
            }
            .frame(width: mediumCanvasWidth, height: mediumCanvasHeight)
            .scaleEffect(scale, anchor: .center)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
