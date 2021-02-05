#import <WMF/MWKLanguageFilter.h>
#import <WMF/WMFPreferredLanguageCodesProviding.h>
@import UIKit.UIView;
@class NSManagedObjectContext;
@class MWKLanguageLink;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFPreferredLanguagesDidChangeNotification;

extern NSString *const WMFAppLanguageDidChangeNotification;

// User info keys for WMFPreferredLanguagesDidChangeNotification
extern NSString *const WMFPreferredLanguagesLastChangedLanguageKey; // An MWKLanguageLink instance
extern NSString *const WMFPreferredLanguagesChangeTypeKey;          // An NSNumber containing a WMFPreferredLanguagesChangeType value

typedef NS_ENUM(NSInteger, WMFPreferredLanguagesChangeType) {
    WMFPreferredLanguagesChangeTypeAdd = 1,
    WMFPreferredLanguagesChangeTypeRemove,
    WMFPreferredLanguagesChangeTypeReorder
};

@interface MWKLanguageLinkController : NSObject <MWKLanguageFilterDataSource, WMFPreferredLanguageCodesProviding>

/// Initializes `MWKLanguageLinkController` with the `NSManagedObjectContext` used for storage
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;

/**
 * Returns all languages of the receiver, sorted by name, minus unsupported languages.
 *
 * Observe this property to be notifified of changes to the list of languages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *allLanguages;

/**
 * Returns the user's 1st preferred language - used as the "App Language".
 */
@property (readonly, copy, nonatomic, nullable) MWKLanguageLink *appLanguage;

/**
 * Returns the user's preferred languages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *preferredLanguages;

/**
 * Returns the user's preferred site URLs.
 */
@property (readonly, copy, nonatomic) NSArray<NSURL *> *preferredSiteURLs;

/**
 * All the languages in the receiver minus @c preferredLanguages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *otherLanguages;

/**
 *  Uniquely appends a new preferred language. The new language will be the last preferred language.
 *
 *  @param language the language to append
 */
- (void)appendPreferredLanguage:(MWKLanguageLink *)language;

/**
 *  Reorders a preferred language to the index given. The language must already exist in a user's preferred languages
 *
 *  @param language the language to reorder
 *  @param newIndex the new index of the langage
 */
- (void)reorderPreferredLanguage:(MWKLanguageLink *)language toIndex:(NSInteger)newIndex;

/**
 *  Removes a preferred language.
 *
 *  @param language the language to remove
 */
- (void)removePreferredLanguage:(MWKLanguageLink *)language;

- (nullable MWKLanguageLink *)languageForContentLanguageCode:(NSString *)contentLanguageCode;

+ (void)migratePreferredLanguagesToManagedObjectContext:(NSManagedObjectContext *)moc;

@end

/// This category is specific to processing MWKLanguageLink instances that represent articles
@interface MWKLanguageLinkController (ArticleLanguageLinkVariants)

/// Given an article URL and an array of language links for that article in different languages, this method does the following:
///
/// - If any of the provided article language links is of a language that supports variants, the single language element is replaced by an article language link for each language variant
///   e.g. If Chinese 'zh' is in the array, it will be replaced by article language links for Chinese, Simplified; Chinese, Traditional; Malaysian Simplified; etc.
///   This allows users to view the corresponding article in a particular variant.
///
/// - If the provided articleURL has a language variant, an article language link for the remaining language variants is appended to the returned array
///   e.g. If the displayed article is shown in Serbian, Cyrillic an article language link for the remaining variant for that language; Serbian, Latin; will be added to the array.
///   This allows users to choose to view the currently displayed article in a different variant of the same language.
- (NSArray<MWKLanguageLink *> *)articleLanguageLinksWithVariantsFromArticleURL:(NSURL *)articleURL articleLanguageLinks:(NSArray<MWKLanguageLink *> *)articleLanguageLinks;

@end

/// Methods moved from the deprecated MWKLanguageInfo class. Potential for additional refactoring.
@interface MWKLanguageLinkController (MWLanguageInfoAdditions)

/// Returns whether the language represented by the @c contentLanguageCode displays right-to-left.
/// Returns NO if @c contentLangaugeCode is nil.
+ (BOOL)isLanguageRTLForContentLanguageCode:(nullable NSString *)contentLanguageCode;

/// Returns either "rtl" or "ltr" depending whether the language represented by the @c contentLanguageCode displays right-to-left.
/// Returns "ltr" if @c contentLangaugeCode is nil.
+ (NSString *)layoutDirectionForContentLanguageCode:(nullable NSString *)contentLanguageCode;

+ (UISemanticContentAttribute)semanticContentAttributeForWMFLanguage:(nullable NSString *)language;
+ (NSSet *)rtlLanguages;
@end

NS_ASSUME_NONNULL_END
