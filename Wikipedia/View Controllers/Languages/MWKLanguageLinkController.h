//
//  MWKLanguageLinkController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKTitle;
@class MWKLanguageLink;

@interface MWKLanguageLinkController : NSObject

/**
 * Returns languages of the reviever, with preferred languages listed first.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (readonly, copy, nonatomic) NSArray* filteredLanguages;

/**
 * Subset of the languages in the receiver which intersect with the user's preferred languages.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (readonly, copy, nonatomic) NSArray* filteredPreferredLanguages;

/**
 * All the languages in the receiver minus @c filteredPreferredLanguages.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (readonly, copy, nonatomic) NSArray* filteredOtherLanguages;

/**
 * String used to filter languages in each section by their @c languageCode or @c languageName.
 *
 * Setting this property to @c nil will disable filtering.
 *
 * @return The string to filter by, or @c nil if disabled.
 */
@property (readwrite, copy, nullable, nonatomic) NSString* languageFilter;

- (void)loadStaticSiteLanguageData;

- (void)loadLanguagesForTitle:(MWKTitle*)title
                      success:(dispatch_block_t)success
                      failure:(void (^ __nullable)(NSError* __nonnull))failure;

- (void)saveSelectedLanguage:(MWKLanguageLink*)language;

- (void)saveSelectedLanguageCode:(NSString*)languageCode;

@end

NS_ASSUME_NONNULL_END
