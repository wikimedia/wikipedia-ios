import SwiftUI
import WMFData

public struct WMFProjectIconView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private let project: WMFProject

    public init(project: WMFProject) {
        self.project = project
    }

    public var body: some View {
        switch project {
        case .wikipedia(let wmfLanguage):
            let capitalizedText = wmfLanguage.languageCode.localizedUppercase
            HStack {
                Text(capitalizedText)
                    .background(Color(appEnvironment.theme.paperBackground))
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(appEnvironment.theme.secondaryText))
                    .padding([.leading, .trailing], 3)
                    .padding([.top, .bottom], 4)

            }
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke(Color(appEnvironment.theme.secondaryText), lineWidth: 1)
            )

        case .wikidata:
            if let image = UIImage(named: "project-wikidata", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: image)
                    .scaledToFit()
                    .background(Color(appEnvironment.theme.paperBackground))
                    .foregroundColor(Color(appEnvironment.theme.secondaryText))
                    .padding(6)
            }

        case .commons:
            if let image = UIImage(named: "project-commons", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: image)
                    .scaledToFit()
                    .background(Color(appEnvironment.theme.paperBackground))
                    .foregroundColor(Color(appEnvironment.theme.secondaryText))
                    .padding(6)
            }
        }
    }
}
