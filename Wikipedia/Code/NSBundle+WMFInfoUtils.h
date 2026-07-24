#import <Foundation/Foundation.h>

@interface NSBundle (WMFInfoUtils)

- (NSString *)wmf_bundleName;

///
/// @name App Version Information
///

/// @return The value for Info.plist key `CFBundleIdentifier`, i.e. the app's bundle identifier.
- (NSString *)wmf_bundleIdentifier;

/// @return The value for Info.plist key `CFBundleVersion`, i.e. the build number.
- (NSString *)wmf_bundleVersion;

/// @return A version string reflecting the build environment:
///         App Store production: `{build}-r-{date}` (e.g. `5054-r-2027-01-01`)
///         TestFlight (any target): `{build}-beta-{date}` (e.g. `5054-beta-2027-01-01`)
///         All others (debug/local): `{build}-alpha-{date}` (e.g. `0-alpha-0-0-0`)
- (NSString *)wmf_appVersion;

// @return The value for Info.plist key `MerchantID`
- (NSString *)wmf_merchantID;

// Heuristics for whether or not this is running in TestFlight or not (inspects the appStoreReceiptURL for sandbox)
- (BOOL)isTestFlight;
@end
