//
//  MWKLanguageLinkController_Private.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKLanguageLinkController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Delete all previously selected languages.
 * @warning For testing only!
 */
extern void WMFDeletePreviouslySelectedLanguages();

/**
 * Reads previously selected languages from storage.
 * @return The previously selected languages, or an empty array of none were previously selected.
 */
extern NSArray* WMFReadPreviouslySelectedLanguages();

@interface MWKLanguageLinkController ()

@property (copy, nonatomic) NSArray* languageLinks;

/// @return All the language codes in @c filteredPreferredLanguages
- (NSArray*)filteredPreferredLanguageCodes;

/// @return All the language codes in @c languageLinks
- (NSArray*)languageCodes;

@end

NS_ASSUME_NONNULL_END
