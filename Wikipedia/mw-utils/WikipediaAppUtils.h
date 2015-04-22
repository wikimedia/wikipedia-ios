//  Created by Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// TODO: use developer constants?
//extern NSString * const WMFHockeyAppDeveloperXcodeCFBundleIdentifier;
//extern NSString * const WMFHockeyAppDeveloperXcodeAppId;
extern NSString* const WMFHockeyAppAlphaHockeyCFBundleIdentifier;
extern NSString* const WMFHockeyAppAlphaHockeyAppId;
extern NSString* const WMFHockeyAppBetaTestFlightCFBundleIdentifier;
extern NSString* const WMFHockeyAppBetaTestFlightAppId;
//extern NSString * const WMFHockeyAppStableCFBundleIdentifier;
//extern NSString * const WMFHockeyAppStableAppId;
// TODO: use stable channel constants

#define MWLocalizedString(key, throwaway) [WikipediaAppUtils localizedStringForKey : key]
#define MWCurrentArticleLanguageLocalizedString(key, throwaway) [WikipediaAppUtils currentArticleLanguageLocalizedString : key]

/**
 * Provides compile time checking for keypaths on a given object.
 * @discussion Example usage:
 *
 *      WMF_SAFE_KEYPATH([NSString new], lowercaseString); //< @"lowercaseString"
 *      WMF_SAFE_KEYPATH([NSString new], fooBar); //< compiler error!
 *
 * @note Inspired by [EXTKeypathCoding.h](https://github.com/jspahrsummers/libextobjc/blob/master/extobjc/EXTKeyPathCoding.h#L14)
 */
#define WMF_SAFE_KEYPATH(obj, keyp) ((NO, (void)obj.keyp), @#keyp)

/**
 * Compare two *objects* using @c == and <code>[a sel b]</code>, where @c sel is a equality selector
 * (e.g. @c isEqualToString:).
 * @param a   First object, can be @c nil.
 * @param sel The selector used to compare @c a to @c b, if <code>a == b</code> is @c false.
 * @param b   Second object, can be @c nil.
 * @return @c YES if the objects are the same pointer or invoking @c sel returns @c YES, otherwise @c NO.
 */
#define WMF_EQUAL(a, sel, b) (((a) == (b)) || ([(a) sel (b)]))

/**
 * Compare two objects using `==` and `isEqual:`.
 * @see WMF_EQUAL
 */
#define WMF_IS_EQUAL(a, b) (WMF_EQUAL(a, isEqual :, b))

/// Circularly rotate an unsigned int (useful when implementing <code>-[NSObject hash]</code>).
FOUNDATION_EXPORT NSUInteger CircularBitwiseRotation(NSUInteger x, NSUInteger s)
__attribute__((pure, always_inline, const));

/// Conert @c m megabytes to bytes.
FOUNDATION_EXPORT NSUInteger MegabytesToBytes(NSUInteger m)
__attribute__((pure, always_inline, const));

/// Normalizes page titles extracted from URLs, replacing percent escapes and underscores.
FOUNDATION_EXPORT NSString* WMFNormalizedPageTitle(NSString* rawPageTitle);

@interface WikipediaAppUtils : NSObject

+ (NSString*)appVersion;
+ (NSString*)bundleID;
+ (NSString*)formFactor;
+ (NSString*)versionedUserAgent;
+ (NSString*)localizedStringForKey:(NSString*)key;
+ (NSString*)currentArticleLanguageLocalizedString:(NSString*)key;
+ (NSString*)relativeTimestamp:(NSDate*)date;
+ (NSString*)domainNameForCode:(NSString*)code;
+ (NSString*)wikiLangForSystemLang:(NSString*)code;
+ (BOOL)     isDeviceLanguageRTL;

+ (NSTextAlignment)rtlSafeAlignment;

+ (void)copyAssetsFolderToAppDataDocuments;

@end
