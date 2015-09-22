//
//  MWKSection.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFSharing.h"
#import "MWKSiteDataObject.h"

@class MWKArticle;
@class MWKImageList;

extern NSString* const MWKSectionShareSnippetXPath;

@interface MWKSection : MWKSiteDataObject
    <WMFSharing>

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readonly, weak, nonatomic) MWKArticle* article;

@property (readonly, copy, nonatomic) NSNumber* toclevel;      // optional
@property (readonly, copy, nonatomic) NSNumber* level;         // optional; string in JSON, but seems to be number-safe?
@property (readonly, copy, nonatomic) NSString* line;          // optional; HTML
@property (readonly, copy, nonatomic) NSString* number;        // optional; can be "1.2.3"
@property (readonly, copy, nonatomic) NSString* index;         // optional; can be "T-3" for transcluded sections
@property (readonly, strong, nonatomic) MWKTitle* fromtitle; // optional
@property (readonly, copy, nonatomic) NSString* anchor;        // optional
@property (readonly, assign, nonatomic) int sectionId;           // required; -> id
@property (readonly, assign, nonatomic) BOOL references;         // optional; marked by presence of key with empty string in JSON

/**
 * Lazily-initialized HTML content of this section.
 *
 * Might be wrapped in a `div` and/or `html`/`body` tags depending on where it came from and how you're parsing it.
 * HTML returned from the `mobileview` API module wraps sections in a `div`, and `TFHpple` wraps HTML in `<html><body>`.
 *
 * @return The HTML for this section of the receiver's `article` or `nil` if it doesn't exist on disk.
 */
@property (readonly, copy, nonatomic /*, nullable*/) NSString* text;
@property (readonly, strong, nonatomic) MWKImageList* images;

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict;

- (BOOL)     isLeadSection;
- (MWKTitle*)sourceTitle;

- (BOOL)isEqualToSection:(MWKSection*)section;

- (void)save;

///
/// @name Extraction
///

/**
 * Query the receiver's `text with the given `xpath`.
 *
 * @param xpath The xpath to use when selecting elements.
 *
 * @return A string obtained by joining the elements matching `xpath`.
 *
 * @see elementsInTextMatchingXPath:
 */
- (NSString*)textForXPath:(NSString*)xpath;

/**
 * Query the receiver's `text` with the given `xpath`.
 *
 * @param xpath The XPath to use when selecting HTML (or text) elements.
 *
 * @warning This might be expensive, but if you want to calculate/cache it off the main thread, create a separate
 *          section object to avoid properties from being get/set from different threads.
 *
 * @return An array of `TFHppleElement` objects which match the given XPath query, or `nil` if there were no results.
 */
- (NSArray*)elementsInTextMatchingXPath:(NSString*)xpath;

///
/// @name Section Hierarchy
///

/**
 *  Sections that are descendants of the receiver.
 *
 *  @return An array of @c MWKSection objects, or @c nil if the hierarchy has not been built yet.
 */
- (NSArray*)children;

/**
 *  Check if the receiver could be considered the parent of another section.
 *
 *  @param section The section to check.
 *
 *  @return @c YES if @c section has a @c level that is one greater than the receiver's @c level, otherwise @c NO.
 */
- (BOOL)isParentOfSection:(MWKSection*)section;

/**
 *  Check if another section is a sibling of the receiver.
 *
 *  @param section The section to check.
 *
 *  @return @c YES if @c section has a @c level equal to the receiver's, otherwise @c NO.
 */
- (BOOL)isSiblingOfSection:(MWKSection*)section;

/**
 *  Check if the receiver is an ancestor of another section.
 *
 *  This is different from @c isParentOfSection: in that it can check for degrees of separation greater than 1.
 *
 *  @param section The section to check.
 *
 *  @return @c YES if the receiver's @c level is less than the @c level of @c section, otherwise @c NO.
 */
- (BOOL)isAncestorOfSection:(MWKSection*)section;

#pragma mark - Internal

/**
 *  Add another section as a child of the receiver.
 *
 *  @param child The section to add as a child.
 */
- (void)addChild:(MWKSection*)child;

/**
 *  Remove all children from the receiver.
 */
- (void)removeAllChildren;

/**
 *  Determines whether this section's text is available (cached) *without* loading the entire text string from disk.
 */
- (BOOL)hasTextData;

@end
