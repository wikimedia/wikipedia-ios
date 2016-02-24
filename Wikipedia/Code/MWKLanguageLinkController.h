
#import <Foundation/Foundation.h>
#import "MWKLanguageFilter.h"

@class MWKTitle;
@class MWKLanguageLink;

NS_ASSUME_NONNULL_BEGIN

@interface MWKLanguageLinkController : NSObject<MWKLanguageFilterDataSource>

+ (instancetype)sharedInstance;

/**
 * Returns all languages of the receiver, sorted by name, minus unsupported languages.
 *
 * Observe this property to be notifified of changes to the list of languages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink*>* allLanguages;

/**
 * Returns the user's preferred languages.
 * Preferred languages will always contain the user's OS preferred languages, even if they are removed.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink*>* preferredLanguages;

/**
 * All the languages in the receiver minus @c preferredLanguages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink*>* otherLanguages;


/**
 *  Uniquely adds a new preferred language. The new lnguage will be the first preferred language.
 *
 *  @param language the language to add
 */
- (void)addPreferredLanguage:(MWKLanguageLink*)language;

/**
 *  Uniquely appends a new preferred language. The new lnguage will be the last preferred language.
 *
 *  @param language the language to append
 */
- (void)appendPreferredLanguage:(MWKLanguageLink*)language;

/**
 *  Reorders a preferred language to the index given. The language must already exist in a user's preferred languages
 *
 *  @param language the language to reorder
 *  @param newIndex the new index of the langage
 */
- (void)reorderPreferredLanguage:(MWKLanguageLink*)language toIndex:(NSUInteger)newIndex;

/**
 *  Removes a preferred language.
 *
 *  @param language the language to remove
 */
- (void)removePreferredLanguage:(MWKLanguageLink*)langage;


- (BOOL)languageIsOSLanguage:(MWKLanguageLink*)language;


- (nullable MWKLanguageLink*)languageForSite:(MWKSite*)site;

@end

NS_ASSUME_NONNULL_END
