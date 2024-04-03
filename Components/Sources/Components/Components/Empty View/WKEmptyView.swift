import SwiftUI

public protocol WKEmptyViewDelegate: AnyObject {
    func emptyViewDidTapSearch()
    func emptyViewDidTapFilters()
    func emptyViewDidShow(type: WKEmptyViewStateType)
}

public struct WKEmptyView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current
    @ObservedObject var viewModel: WKEmptyViewModel
    weak var delegate: WKEmptyViewDelegate?
    var type: WKEmptyViewStateType
    
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
                            .font(Font(WKFont.for(.boldBody)))
                            .foregroundColor(Color(appEnvironment.theme.text))
                            .padding([.top], 12)
                            .padding([.bottom], 8)
                            .multilineTextAlignment(.center)
                        if let attributedString = viewModel.filterString(localizedStrings: viewModel.localizedStrings),
                           type == .filter {
                            WKEmptyViewFilterView(delegate: delegate, attributedString: attributedString)
                        } else {
                            Text(viewModel.localizedStrings.subtitle)
                                .font(Font(WKFont.for(.subheadline)))
                                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                                .multilineTextAlignment(.center)
                        }
                        if let buttonTitle = viewModel.localizedStrings.buttonTitle,
                           type == .noItems {
                            let configuration = WKSmallButton.Configuration(style: .neutral)
                            WKSmallButton(configuration: configuration, title: buttonTitle, action: delegate?.emptyViewDidTapSearch)
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

struct WKEmptyViewFilterView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current
    weak var delegate: WKEmptyViewDelegate?
    let attributedString: AttributedString

    var body: some View {
        
        Text(attributedString)
            .font(Font(WKFont.for(.subheadline)))
            .padding(2)
            .foregroundColor(Color(appEnvironment.theme.secondaryText))
            .frame(height: 30)
            .environment(\.openURL, OpenURLAction { url in
                    delegate?.emptyViewDidTapFilters()
                    return .handled
                })
    }
}
