//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFDefaultSiteDomain;

@class MWKTitle;
@class MWKUser;

/// Represents a mediawiki instance dedicated to a specific language.
@interface MWKSite : NSObject <NSCopying>

/// The hostname for the site, defaults to @c WMFDefaultSiteDomain.
@property (nonatomic, copy, readonly) NSString* domain;

/// The language code for the site. Should be ISO 639-x/IETF BCP 47
/// @see kCFLocaleLanguageCode
@property (nonatomic, copy, readonly) NSString* language;

///
/// @name Computed Properties
///

- (NSURL*)URL;

- (NSURL*)mobileURL;

- (NSURL*)apiEndpoint;

- (NSURL*)mobileApiEndpoint;

- (instancetype)initWithDomain:(NSString*)domain language:(NSString*)language NS_DESIGNATED_INITIALIZER;

/// Create a site using @c language and the default domain.
- (instancetype)initWithLanguage:(NSString*)language;

+ (instancetype)siteWithDomain:(NSString*)domain language:(NSString*)language;

+ (instancetype)siteWithLanguage:(NSString*)language;

/// @return A site with the default domain and the language code returned by @c locale.
+ (instancetype)siteWithLocale:(NSLocale*)locale;

/// @return A site with the default domain and the current locale's language code.
+ (instancetype)siteWithCurrentLocale;

- (BOOL)isEqualToSite:(MWKSite* __nullable)other;

- (UIUserInterfaceLayoutDirection)layoutDirection;

- (NSTextAlignment)textAlignment;

///
/// @name Title Factory Convenience Methods
///

/**
 * @return A title initialized with the receiver as its @c site.
 * @see -[MWKTitle initWithString:site:]
 */
- (MWKTitle*)titleWithString:(NSString*)string;

/**
 * @return A title initialized with the receiver as its @c site.
 * @see -[MWKTitle initWithString:site:]
 */
- (MWKTitle*)titleWithInternalLink:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
