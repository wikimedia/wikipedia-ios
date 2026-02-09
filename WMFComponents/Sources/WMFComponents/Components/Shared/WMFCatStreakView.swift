import SwiftUI
import WMFData

public struct WMFCatStreakView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: WMFCatStreakViewModel
    
    let useEnvironmentColorScheme: Bool
    let imageSize: CGFloat
    let showBackground: Bool
    let showProgressIndicator: Bool
    
    private var theme: WMFTheme {
        if useEnvironmentColorScheme {
            return colorScheme == .dark ? .dark : .light
        } else {
            return appEnvironment.theme
        }
    }
    
    public init(
        viewModel: WMFCatStreakViewModel,
        useEnvironmentColorScheme: Bool = false,
        imageSize: CGFloat = 120,
        showBackground: Bool = true,
        showProgressIndicator: Bool = true
    ) {
        self.viewModel = viewModel
        self.useEnvironmentColorScheme = useEnvironmentColorScheme
        self.imageSize = imageSize
        self.showBackground = showBackground
        self.showProgressIndicator = showProgressIndicator
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Cat image
            if let catImageData = viewModel.catImageData,
               let uiImage = UIImage(data: catImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(theme.border), lineWidth: 1)
                    )
            } else {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(theme.midBackground))
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Group {
                            if showProgressIndicator {
                                ProgressView()
                                    .tint(Color(theme.accent))
                            }
                        }
                    )
            }
            
            // Streak info
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.streakTitle)
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundColor(Color(theme.text))
                
                if viewModel.streakCount > 0 {
                    HStack(spacing: 4) {
                        Text(viewModel.streakCountText)
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundColor(Color(theme.accent))
                        
                        Text(viewModel.streakDaysLabel)
                            .font(Font(WMFFont.for(.headline)))
                            .foregroundColor(Color(theme.secondaryText))
                    }
                    
                    Text(viewModel.streakMessage)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(theme.secondaryText))
                        .lineLimit(2)
                } else {
                    Text(viewModel.zeroStreakMessage)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(theme.secondaryText))
                        .lineLimit(3)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .if(showBackground) { view in
            view.background(Color(theme.paperBackground))
                .cornerRadius(12)
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

@MainActor
public final class WMFCatStreakViewModel: ObservableObject {
    @Published public var catImageData: Data?
    @Published public var streakCount: Int
    
    public var streakCountText: String {
        return "\(streakCount)"
    }
    
    public var streakTitle: String
    public var streakDaysLabel: String
    public var streakMessage: String
    public var zeroStreakMessage: String
    
    public init(
        catImageData: Data? = nil,
        streakCount: Int,
        streakTitle: String,
        streakDaysLabel: String,
        streakMessage: String,
        zeroStreakMessage: String
    ) {
        self.catImageData = catImageData
        self.streakCount = streakCount
        self.streakTitle = streakTitle
        self.streakDaysLabel = streakDaysLabel
        self.streakMessage = streakMessage
        self.zeroStreakMessage = zeroStreakMessage
    }
    
    public func updateCatImage(_ imageData: Data?) {
        self.catImageData = imageData
    }
    
    public func updateStreak(_ streak: Int) {
        self.streakCount = streak
    }
}
