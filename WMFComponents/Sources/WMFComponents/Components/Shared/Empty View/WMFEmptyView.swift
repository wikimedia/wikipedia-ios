import SwiftUI

public protocol WMFEmptyViewDelegate: AnyObject {
    func emptyViewDidTapSearch()
    func emptyViewDidTapFilters()
    func emptyViewDidShow(type: WMFEmptyViewStateType)
}

public struct WMFEmptyView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFEmptyViewModel
    weak var delegate: WMFEmptyViewDelegate?
    var type: WMFEmptyViewStateType
    
    var foregroundColor: Color? {
        if let imageColor = viewModel.imageColor {
            return Color(uiColor: imageColor)
        }
        
        return nil
    }

    public var body: some View {
        GeometryReader { geometry in

            ZStack {
                Color(appEnvironment.theme.paperBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        Spacer()
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 132, height: 118)
                                .foregroundColor(foregroundColor)
                        }
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.boldCallout)))
                            .foregroundColor(Color(appEnvironment.theme.text))
                            .padding([.top], 12)
                            .padding([.bottom], 8)
                            .multilineTextAlignment(.center)
                        if let attributedString = viewModel.filterString(localizedStrings: viewModel.localizedStrings),
                           type == .filter {
                            WMFEmptyViewFilterView(delegate: delegate, attributedString: attributedString)
                        } else {
                            Text(viewModel.localizedStrings.subtitle)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                                .multilineTextAlignment(.center)
                        }
                        if let buttonTitle = viewModel.localizedStrings.buttonTitle,
                           type == .noItems {
                            let configuration = WMFSmallButton.Configuration(style: .neutral)
                            WMFSmallButton(configuration: configuration, title: buttonTitle, action: delegate?.emptyViewDidTapSearch)
                                .padding(EdgeInsets(top: 8, leading: 32, bottom: 0, trailing: 32))
                        }
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding([.leading, .trailing], 32)
                }
            }
        }
        .onAppear {
            delegate?.emptyViewDidShow(type: type)
        }
    }

}

struct WMFEmptyViewFilterView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    weak var delegate: WMFEmptyViewDelegate?
    let attributedString: AttributedString

    var body: some View {
        
        Text(attributedString)
            .font(Font(WMFFont.for(.subheadline)))
            .padding(2)
            .foregroundColor(Color(appEnvironment.theme.secondaryText))
            .frame(height: 30)
            .environment(\.openURL, OpenURLAction { url in
                    delegate?.emptyViewDidTapFilters()
                    return .handled
                })
    }
}
