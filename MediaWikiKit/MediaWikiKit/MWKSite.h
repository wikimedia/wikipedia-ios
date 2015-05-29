//  Created by Brion on 11/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFDefaultSiteDomain;

@class MWKTitle;
@class MWKUser;

@interface MWKSite : NSObject

@property (nonatomic, copy, readonly) NSString* domain;
@property (nonatomic, copy, readonly) NSString* language;

- (instancetype)initWithDomain:(NSString*)domain language:(NSString*)language NS_DESIGNATED_INITIALIZER;

/// Convenience factory method wrapping the designated initializer.
+ (instancetype)siteWithDomain:(NSString*)domain language:(NSString*)language;

/// @return A site with the default domain and the language code returned by @c locale.
+ (instancetype)siteWithLocale:(NSLocale*)locale;

/// @return A site with the default domain and the current locale's language code.
+ (instancetype)siteWithCurrentLocale;

- (BOOL)isEqualToSite:(MWKSite* __nullable)other;

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
