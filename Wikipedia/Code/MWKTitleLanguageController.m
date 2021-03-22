#import "MWKTitleLanguageController.h"
@import WMF;
#import "MWKLanguageLinkFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitleLanguageController ()

@property (copy, nonatomic, readwrite) NSURL *articleURL;
@property (strong, nonatomic, readwrite) MWKLanguageLinkController *languageController;
@property (strong, nonatomic) MWKLanguageLinkFetcher *fetcher;
@property (copy, nonatomic) NSArray *availableLanguages;
@property (readwrite, copy, nonatomic) NSArray *allLanguages;
@property (readwrite, copy, nonatomic) NSArray *preferredLanguages;
@property (readwrite, copy, nonatomic) NSArray *otherLanguages;

@end

@implementation MWKTitleLanguageController

- (instancetype)initWithArticleURL:(NSURL *)url languageController:(MWKLanguageLinkController *)controller {
    self = [super init];
    if (self) {
        self.articleURL = url;
        self.languageController = controller;
    }
    return self;
}

- (MWKLanguageLinkFetcher *)fetcher {
    if (!_fetcher) {
        _fetcher = [[MWKLanguageLinkFetcher alloc] init];
    }
    return _fetcher;
}

- (void)fetchLanguagesWithSuccess:(dispatch_block_t)success
                          failure:(void (^__nullable)(NSError *__nonnull))failure {
    [self.fetcher fetchLanguageLinksForArticleURL:self.articleURL
        success:^(NSArray *languageLinks) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *adjustedLinks = [self.languageController articleLanguageLinksWithVariantsFromArticleURL:self.articleURL articleLanguageLinks:languageLinks];
                self.availableLanguages = adjustedLinks;
                if (success) {
                    success();
                }
            });
        }
        failure:^(NSError *_Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }];
}

- (void)setAvailableLanguages:(NSArray *)availableLanguages {
    _availableLanguages = availableLanguages;
    [self updateLanguageArrays];
}

- (void)updateLanguageArrays {
    self.otherLanguages = [[self.languageController.otherLanguages wmf_select:^BOOL(MWKLanguageLink *language) {
        return [self languageIsAvailable:language];
    }] wmf_map:^id(MWKLanguageLink *language) {
        return [self titleLanguageForLanguage:language];
    }];

    self.preferredLanguages = [[self.languageController.preferredLanguages wmf_select:^BOOL(MWKLanguageLink *language) {
        return [self languageIsAvailable:language];
    }] wmf_map:^id(MWKLanguageLink *language) {
        return [self titleLanguageForLanguage:language];
    }];

    self.allLanguages = [[self.languageController.allLanguages wmf_select:^BOOL(MWKLanguageLink *language) {
        return [self languageIsAvailable:language];
    }] wmf_map:^id(MWKLanguageLink *language) {
        return [self titleLanguageForLanguage:language];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKLanguageFilterDataSourceLanguagesDidChangeNotification object: self];
}

- (nullable MWKLanguageLink *)titleLanguageForLanguage:(MWKLanguageLink *)language {
    MWKLanguageLink *titleLanguage = [self.availableLanguages wmf_match:^BOOL(MWKLanguageLink *availableLanguage) {
        
        //Note: the langlinks endpoint returns "nb" for it's language code rather than "no", which messes up our matching with app language codes.
        //So here we are checking the altISOCode of our stored languages against the lanklinks language code for a match.
        //Currently "no.wikipedia.org" is the only MWKLanguageLink app language that has an altISOCode populated (see wikipedia-languages.json).
        //Fixes https://phabricator.wikimedia.org/T272193
        return [language.contentLanguageCode isEqualToString:availableLanguage.contentLanguageCode] ||
                                    (language.altISOCode &&
                                     [language.altISOCode isEqualToString:availableLanguage.contentLanguageCode]);
    }];

    //If match was found via altISOCode, replace the title language with the expected languageCode.
    //Without this, the title language VC will attempt to serve up a mobile-html page at https://nb.wikipedia.org/api/rest_v1/page/mobile-html/{title}, which fails as not found
    if ([titleLanguage.contentLanguageCode isEqualToString:language.altISOCode]) {
        return [[MWKLanguageLink alloc] initWithLanguageCode:language.languageCode pageTitleText:titleLanguage.pageTitleText name:titleLanguage.name localizedName:titleLanguage.localizedName languageVariantCode:titleLanguage.languageVariantCode altISOCode:language.altISOCode];
    }

    return titleLanguage;
}

- (BOOL)languageIsAvailable:(MWKLanguageLink *)language {
    return [self titleLanguageForLanguage:language] != nil;
}

@end

NS_ASSUME_NONNULL_END
