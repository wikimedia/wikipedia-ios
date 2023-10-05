import Foundation

public extension URL {
    var isThankYouDonationURL: Bool {
        return self.host == "thankyou.wikipedia.org" || self.host == "thankyou.wikimedia.org"
    }
    
    var isDonationURL: Bool {
        return self.host == "donate.wikipedia.org" || self.host == "donate.wikimedia.org"
    }
}
