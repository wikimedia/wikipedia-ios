@import Foundation;

@interface NSBundle (WMFInfoUtils)

- (NSString *)wmf_bundleName;

///
/// @name App Version Information
///

/// @return The value for Info.plist key `CFBundleIdentifier`, i.e. the app's bundle identifier.
- (NSString *)wmf_bundleIdentifier;

/// @return `YES` if `wmf_bundleIdentifier` ends in "wikipedia", otherwise `NO`.
- (BOOL)wmf_isAppStoreBundleIdentifier;

/// @return The value for Info.plist key `CFBundleShortVersionString`, i.e. the "public" app version.
- (NSString *)wmf_shortVersionString;

/// @return The value for Info.plist key `CFBundleVersion`, i.e. the build number.
- (NSString *)wmf_bundleVersion;

/// @return A string which represents the full app verison, including the build number: `M.m.p.build`.
- (NSString *)wmf_debugVersion;

/// @return A string that shows the full version in "TestFlight/Apple" format: `M.m.p (build)`.
- (NSString *)wmf_releaseVersion;

/// @return Either `wmf_releaseVersion` or `wmf_debugVersion` depending on the bundle identifier.
- (NSString *)wmf_versionForCurrentBundleIdentifier;

@end
