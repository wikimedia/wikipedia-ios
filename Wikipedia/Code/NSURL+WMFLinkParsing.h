//
//  NSURL+WMFLinkParsing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFLinkParsing)

/**
 * Initialize a new URL with a Wikimedia `domain` and `language`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @return A new URL with the given domain and language.
 **/
+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString* __nullable)language;

/**
 * Initialize a new URL with a Wikimedia `domain`, `language`, `title` and `fragment`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param title         An optional Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL with the given domain, language, title and fragment.
 **/
+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString* __nullable)language title:(NSString* __nullable)title fragment:(NSString* __nullable)fragment;


/**
 * Return a new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 *
 * @param siteURL       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 **/
+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL title:(NSString* __nullable)title fragment:(NSString* __nullable)fragment;

/**
 * Return a new URL similar to the URL you call this method on but replace the title.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 *
 * @return A new URL based on the URL you call this method on with the given title.
 **/
- (NSURL*)wmf_URLWithTitle:(NSString*)title;

/**
 * Return a new URL similar to the URL you call this method on but replace the title and fragemnt.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL based on the URL you call this method on with the given title and fragment.
 **/
- (NSURL*)wmf_URLWithTitle:(NSString*)title fragment:(NSString* __nullable)fragment;

/**
 * Return a new URL similar to the URL you call this method on but replace the path.
 *
 * @param path         A full path - for example `/w/api.php`
 *
 * @return A new URL based on the URL you call this method on with the given path.
 **/
- (NSURL*)wmf_URLWithPath:(NSString*)path isMobile:(BOOL)isMobile;

@property (nonatomic, readonly) BOOL wmf_isInternalLink;

@property (nonatomic, readonly) BOOL wmf_isCitation;

@property (nonatomic, readonly) BOOL wmf_isMobile;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_internalLinkPath;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_title;

@property (nonatomic, copy, readonly, nullable) NSURL* wmf_mobileURL;

@property (nonatomic, copy, readonly, nullable) NSURL* wmf_desktopURL;

@property (nonatomic, readonly) BOOL wmf_isNonStandardURL;

@end

NS_ASSUME_NONNULL_END
