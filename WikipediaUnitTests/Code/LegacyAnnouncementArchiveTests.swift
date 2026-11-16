import Foundation
import Testing
@testable import Wikipedia
@testable import WMF

/// App versions before the Mantle removal archived a `WMFAnnouncement` into
/// `WMFContentGroup.contentPreview`. Core Data decodes that value when it faults the row in, and it
/// stops the app with an exception if the class is not in the allowed classes of the transformer.
/// The app then cannot start, because the code that deletes the row is the code that fails.
struct LegacyAnnouncementArchiveTests {

    /// Builds an archive of the shape that an earlier app version wrote. Mantle encoded one key for
    /// each property, and one more key for the model version.
    private func makeLegacyArchive() throws -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.setClassName("WMFAnnouncement", for: LegacyAnnouncementStandIn.self)
        archiver.encode(LegacyAnnouncementStandIn(), forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    private func makeTransformer() throws -> ValueTransformer {
        let transformerClass = try #require(NSClassFromString("WMFSecureUnarchiveFromDataTransformer") as? ValueTransformer.Type)
        return transformerClass.init()
    }

    @Test
    func theTransformerAllowsTheAnnouncementClass() throws {
        let allowed = SecureUnarchiveFromDataTransformer.allowedTopLevelClasses
        #expect(allowed.contains { $0 == WMFAnnouncement.self })
    }

    /// A regression stops the test process with `NSInvalidUnarchiveOperationException`, as it stops
    /// the app. The test framework shows this as a crash, not as a failed expectation.
    @Test
    func theTransformerDecodesAnArchiveFromAnEarlierAppVersion() throws {
        let transformer = try makeTransformer()
        // NSSecureUnarchiveFromDataTransformer decodes in the forward direction.
        let decoded = transformer.transformedValue(try makeLegacyArchive())
        #expect(decoded is WMFAnnouncement)
    }

    /// Core Data declares `contentPreview` as a copy property. Thus the setter calls `copyWithZone:`.
    @Test
    func theAnnouncementAnswersCopyWithZone() {
        let announcement = WMFAnnouncement()
        #expect(announcement.responds(to: NSSelectorFromString("copyWithZone:")))
        #expect(announcement.copy() is WMFAnnouncement)
    }
}

/// Stands in for the Mantle announcement, to write an archive with the same class name and keys.
@objc(LegacyAnnouncementStandIn)
private final class LegacyAnnouncementStandIn: NSObject, NSSecureCoding {

    static var supportsSecureCoding: Bool { true }

    override init() {
        super.init()
    }

    init?(coder: NSCoder) {
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(4 as NSNumber, forKey: "MTLModelVersion")
        coder.encode("EN0825" as NSString, forKey: "identifier")
        coder.encode("fundraising" as NSString, forKey: "type")
        coder.encode(Date(timeIntervalSince1970: 0) as NSDate, forKey: "startTime")
        coder.encode(Date(timeIntervalSince1970: 100) as NSDate, forKey: "endTime")
        coder.encode(["iOS"] as NSArray, forKey: "platforms")
        coder.encode(["US"] as NSArray, forKey: "countries")
        coder.encode("banner" as NSString, forKey: "placement")
        coder.encode(URL(string: "https://upload.wikimedia.org/image.jpg")! as NSURL, forKey: "imageURL")
        coder.encode("Please help." as NSString, forKey: "text")
        coder.encode("Donate" as NSString, forKey: "actionTitle")
        coder.encode("https://donate.wikimedia.org" as NSString, forKey: "actionURLString")
    }
}
