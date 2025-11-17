import SwiftUI

public struct WMFToastViewExploreSurveyViewModel {
    public struct LocalizableStrings {
        let title: String
        let subtitle: String
        let noThanksButtonTitle: String
        let takeSurveyButtonTitle: String
        
        public init(title: String, subtitle: String, noThanksButtonTitle: String, takeSurveyButtonTitle: String) {
            self.title = title
            self.subtitle = subtitle
            self.noThanksButtonTitle = noThanksButtonTitle
            self.takeSurveyButtonTitle = takeSurveyButtonTitle
        }
    }
    
    let localizableStrings: LocalizableStrings
    let noThanksAction: () -> Void
    let takeSurveyAction: () -> Void
    
    public init(localizableStrings: WMFToastViewExploreSurveyViewModel.LocalizableStrings, noThanksAction: @escaping () -> Void, takeSurveyAction: @escaping () -> Void) {
        self.localizableStrings = localizableStrings
        self.noThanksAction = noThanksAction
        self.takeSurveyAction = takeSurveyAction
    }
}

public struct WMFToastViewExploreSurveyView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let viewModel: WMFToastViewExploreSurveyViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, viewModel: WMFToastViewExploreSurveyViewModel) {
        self.appEnvironment = appEnvironment
        self.viewModel = viewModel
    }
    
    var cappedTraitCollection: UITraitCollection {
        if appEnvironment.traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            return UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        } else {
            return appEnvironment.traitCollection
        }
    }
    
    var cappedSubheadlineFont: UIFont {
        return WMFFont.for(.subheadline, compatibleWith: cappedTraitCollection)
    }
    
    var cappedBoldSubheadlineFont: UIFont {
        return WMFFont.for(.boldSubheadline, compatibleWith: cappedTraitCollection)
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let image = WMFSFSymbolIcon.for(symbol: .bubbleRightFill, font: .subheadline, compatibleWith: cappedTraitCollection) {
                Image(uiImage: image)
                    .foregroundColor(Color(theme.link))
                    .padding(.top, 2)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.localizableStrings.title)
                    .font(Font(cappedBoldSubheadlineFont))
                    .foregroundColor(Color(theme.text))
                
                Text(viewModel.localizableStrings.subtitle)
                    .font(Font(cappedSubheadlineFont))
                    .foregroundColor(Color(theme.text))
                
                HStack(spacing: 20) {

                    Button(action: {
                        viewModel.noThanksAction()
                    }, label: {
                        Text(viewModel.localizableStrings.noThanksButtonTitle)
                            .font(Font(cappedBoldSubheadlineFont))
                            .foregroundColor(Color(appEnvironment.theme.secondaryText))
                    })
                    
                    Button(action: {
                        viewModel.takeSurveyAction()
                    }, label: {
                        Text(viewModel.localizableStrings.takeSurveyButtonTitle)
                            .font(Font(cappedBoldSubheadlineFont))
                            .foregroundColor(Color(appEnvironment.theme.link))
                    })
                }
            }
            
        }
    }
}
