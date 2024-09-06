import SwiftUI

struct WMFDonateHistoryView: View {

    @ObservedObject var viewModel: WMFDonateHistoryViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var body: some View {
        if let items = viewModel.localDonationViewModels, !items.isEmpty {
            VStack {
                List(items, id: \.self) { item in
                    Text("\(item.donationDate) - \(item.donationAmount)")
                }
                .listBackgroundColor(Color(appEnvironment.theme.baseBackground))

                Spacer()

                WMFLargeButton(appEnvironment: appEnvironment, configuration: .primary, title: viewModel.localizedStrings.buttonTitle) {
                    viewModel.deleteLocalDonationHistory()
                }
                .padding([.top], 16)
                .padding([.leading, .trailing, .bottom], 30)
            }
            .background(Color(appEnvironment.theme.baseBackground))
            .ignoresSafeArea(edges: .bottom)

        } else {
            Text(viewModel.localizedStrings.emptyMessage)
                .padding(20)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                .multilineTextAlignment(.center)
                .background(Color(appEnvironment.theme.paperBackground))
        }

    }

}
