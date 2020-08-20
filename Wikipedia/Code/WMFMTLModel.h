@import Foundation;
@import Mantle;

NS_ASSUME_NONNULL_BEGIN

/// WMFMTLModel allows us to implement NSSecureCoding for all of our MTLModel objects in one place
/// Long term, Mantle should likely be removed and replaced with Codable Swift structs.
@interface WMFMTLModel : MTLModel <NSSecureCoding>

@end

NS_ASSUME_NONNULL_END
