import Foundation

public extension URL {
    var isThankYouDonationURL: Bool {
        return self.host == "thankyou.wikipedia.org"
    }

    var isDonationURL: Bool {
        return self.host == "donate.wikimedia.org"
    }
}
