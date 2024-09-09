import Foundation
import WMFData
import Combine

public class  WMFDonateHistoryViewModel: ObservableObject {
    @Published private(set) var localHistory: [WMFDonateLocalHistory]?
    @Published var localDonationViewModels: [WMFDonateHistoryViewItemModel]?

    private let dataController = WMFDonateDataController.shared

    public let localizedStrings: WMFDonateHistoryViewModel.LocalizedStrings

    public struct LocalizedStrings {
        let viewTitle: String
        let buttonTitle: String
        let emptyMessage: String

        public init(viewTitle: String, buttonTitle: String, emptyMessage: String) {
            self.viewTitle = viewTitle
            self.buttonTitle = buttonTitle
            self.emptyMessage = emptyMessage
        }
    }

    public init(localizedStrings: WMFDonateHistoryViewModel.LocalizedStrings) {
        self.localizedStrings = localizedStrings
        localHistory = dataController.loadLocalDonationHistory()
        localDonationViewModels = donationsOrderedByDate()
    }

    func deleteLocalDonationHistory() {
        dataController.deleteLocalDonationHistory()
        localHistory = nil
        localDonationViewModels = nil
    }

    func donationsOrderedByDate() -> [WMFDonateHistoryViewItemModel]? {
        guard let localHistory else {
            return nil
        }

        let sortedDonations = sortDonationsByDate(localHistory)
        var donationViewModels: [WMFDonateHistoryViewItemModel] = []

        for item in sortedDonations {

            let formattedDate = formatTimestampToLocalDate(item.donationTimestamp)
            let formattedAmount = formatDonationAmount(item.donationAmount)

            let donationItem = WMFDonateHistoryViewItemModel(
                id: UUID(),
                donationDate: formattedDate,
                donationAmount: formattedAmount
            )
            donationViewModels.append(donationItem)
        }

        return donationViewModels
    }

    private func formatTimestampToLocalDate(_ timestamp: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: timestamp) else {
            return timestamp
        }

        let localizedFormatter = DateFormatter()
        localizedFormatter.dateStyle = .medium
        localizedFormatter.locale = Locale.current
        return localizedFormatter.string(from: date)
    }

    private func sortDonationsByDate(_ donations: [WMFDonateLocalHistory]) -> [WMFDonateLocalHistory] {
        return donations.sorted {
            let dateFormatter = ISO8601DateFormatter()
            guard let date1 = dateFormatter.date(from: $0.donationTimestamp),
                  let date2 = dateFormatter.date(from: $1.donationTimestamp) else {
                return false
            }
            return date1 < date2
        }
    }

    private func formatDonationAmount(_ amount: Decimal) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale.current
        return numberFormatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

}

struct WMFDonateHistoryViewItemModel: Identifiable, Hashable {
    var id: UUID
    let donationDate: String
    let donationAmount: String
}
