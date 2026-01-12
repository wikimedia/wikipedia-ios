import SwiftUI

public struct WMFToastViewBasicViewModel {
    public struct LocalizableStrings {
        let title: String
        let buttonTitle: String
        
        public init(title: String, buttonTitle: String) {
            self.title = title
            self.buttonTitle = buttonTitle
        }
    }
    
    let localizableStrings: LocalizableStrings
    let buttonAction: () -> Void
    
    public init(localizableStrings: WMFToastViewBasicViewModel.LocalizableStrings, buttonAction: @escaping () -> Void) {
        self.localizableStrings = localizableStrings
        self.buttonAction = buttonAction
    }
}

public struct WMFToastViewBasicView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let viewModel: WMFToastViewBasicViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, viewModel: WMFToastViewBasicViewModel) {
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
    
    var cappedBoldSubheadlineFont: UIFont {
        return WMFFont.for(.boldSubheadline, compatibleWith: cappedTraitCollection)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.localizableStrings.title)
                .font(Font(cappedBoldSubheadlineFont))
                .foregroundColor(Color(theme.text))
            
            Button(action: {
                viewModel.buttonAction()
            }, label: {
                Text(viewModel.localizableStrings.buttonTitle)
                    .font(Font(cappedBoldSubheadlineFont))
                    .foregroundColor(Color(appEnvironment.theme.link))
            })
        }
    }
}
