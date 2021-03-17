#import <WMF/MWKLanguageFilter.h>

@class MWKLanguageLinkController;
@class MWKLanguageLink;

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitleLanguageController : NSObject <MWKLanguageFilterDataSource>

- (instancetype)initWithArticleURL:(NSURL *)url languageController:(MWKLanguageLinkController *)controller;

@property (copy, nonatomic, readonly) NSURL *articleURL;
@property (strong, nonatomic, readonly) MWKLanguageLinkController *languageController;

- (void)fetchLanguagesWithSuccess:(dispatch_block_t)success
                          failure:(void (^__nullable)(NSError *__nonnull))failure;

/**
 * Returns all languages of the receiver, with preferred languages listed first.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *allLanguages;

/**
 * Returns the user's preferred languages.
 * Preferred languages will always contain the user's OS preferred languages, even if they are removed.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *preferredLanguages;

/**
 * All the languages in the receiver minus @c preferredLanguages.
 */
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *otherLanguages;
@end

NS_ASSUME_NONNULL_END
