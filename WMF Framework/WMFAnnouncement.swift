import Foundation

/// An announcement that an earlier app version saved to Core Data.
///
/// The app no longer shows announcements, and it no longer creates these objects. But app versions
/// before the Mantle removal archived a `WMFAnnouncement` into `WMFContentGroup.contentPreview`.
/// Core Data decodes that value when it faults the row in. Thus this class must stay, and must stay
/// in the allowed classes of `WMFSecureUnarchiveFromDataTransformer`, or the app cannot read those
/// rows and stops with an exception.
///
/// The class decodes no properties, because nothing reads them. It only lets Core Data fault the row
/// in, so that `WMFDatabaseHousekeeper` and `WMFFeedPromptsContentSource` can delete it.
/// Remove this class when the announcement rows are no longer on disk.
@objc(WMFAnnouncement)
@objcMembers
public final class WMFAnnouncement: NSObject, NSSecureCoding, NSCopying {

    public override init() {
        super.init()
    }

    // MARK: - NSCopying

    /// Core Data declares `WMFContentGroup.contentPreview` as a copy property.
    public func copy(with zone: NSZone? = nil) -> Any {
        return WMFAnnouncement()
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    public init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {
    }
}
