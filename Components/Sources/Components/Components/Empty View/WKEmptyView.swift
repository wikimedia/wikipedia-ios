import SwiftUI

public protocol WKEmptyViewDelegate: AnyObject {
    func didTapSearch()
    func didTapFilters()
}

public struct WKEmptyView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current
    @ObservedObject var viewModel: WKEmptyViewModel
    weak var delegate: WKEmptyViewDelegate?
    var type: WKEmptyViewStateType

    public var body: some View {
        GeometryReader { geometry in

            ZStack {
                Color(appEnvironment.theme.paperBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        Spacer()
                        Image(uiImage: viewModel.image)
                            .frame(width: 132, height: 118)
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WKFont.for(.boldBody)))
                            .foregroundColor(Color(appEnvironment.theme.text))
                            .padding([.top], 12)
                            .padding([.bottom], 8)
                            .multilineTextAlignment(.center)
                        if type == .filter {
                            WKEmptyViewFilterView(delegate: delegate, viewModel: viewModel)
                        } else {
                            Text(viewModel.localizedStrings.subtitle)
                                .font(Font(WKFont.for(.footnote)))
                                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                                .multilineTextAlignment(.center)
                        }
                        if type == .noItems {
                            WKResizableButton(title: viewModel.localizedStrings.buttonTitle, action: delegate?.didTapSearch)
                                .padding([.leading, .trailing], 32)
                        }
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding([.leading, .trailing], 32)
                }
            }
        }
    }

}

struct WKEmptyViewFilterView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current
    weak var delegate: WKEmptyViewDelegate?
    @ObservedObject var viewModel: WKEmptyViewModel

    var body: some View {

        var attributedString: AttributedString {
            return viewModel.filterString(localizedStrings: viewModel.localizedStrings)
        }
        
        Text(attributedString)
            .font(Font(WKFont.for(.footnote)))
            .padding(2)
            .foregroundColor(Color(appEnvironment.theme.secondaryText))
            .frame(height: 30)
            .environment(\.openURL, OpenURLAction { url in
                    delegate?.didTapFilters()
                    return .handled
                })
    }
}
