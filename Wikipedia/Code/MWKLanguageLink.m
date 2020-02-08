#import <WMF/MWKLanguageLink.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFHashing.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/MWKDataStore.h>
#import <WMF/WMFExploreFeedContentController.h>

@interface MWKLanguageLink ()

@property (readwrite, copy, nonatomic, nonnull) NSString *languageCode;
@property (readwrite, copy, nonatomic, nonnull) NSString *pageTitleText;
@property (readwrite, copy, nonatomic, nonnull) NSString *localizedName;
@property (readwrite, copy, nonatomic, nonnull) NSString *name;
@property (readonly, copy, nonatomic) WMFExploreFeedContentController *feedContentController;
@property (readwrite, copy, nonatomic, nullable) NSDictionary<NSString *, WMFLanguageLinkNamespace *> *namespaces;

@end

NS_ASSUME_NONNULL_BEGIN

@implementation MWKLanguageLink

WMF_SYNTHESIZE_IS_EQUAL(MWKLanguageLink, isEqualToLanguageLink:)

- (instancetype)initWithLanguageCode:(nonnull NSString *)languageCode
                       pageTitleText:(nonnull NSString *)pageTitleText
                                name:(nonnull NSString *)name
                       localizedName:(nonnull NSString *)localizedName {
    self = [super init];
    if (self) {
        self.languageCode = languageCode;
        self.pageTitleText = pageTitleText;
        self.name = name;
        self.localizedName = localizedName;
    }
    return self;
}

- (BOOL)isEqualToLanguageLink:(MWKLanguageLink *)rhs {
    return WMF_RHS_PROP_EQUAL(languageCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(pageTitleText, isEqualToString:) && WMF_RHS_PROP_EQUAL(name, isEqualToString:) && WMF_RHS_PROP_EQUAL(localizedName, isEqualToString:) && [self.namespaces isEqualToDictionary:rhs.namespaces];
}

- (NSComparisonResult)compare:(MWKLanguageLink *)other {
    return [self.languageCode compare:other.languageCode];
}

- (NSUInteger)hash {
    return self.languageCode.hash ^ flipBitsWithAdditionalRotation(self.pageTitleText.hash, 1) ^ flipBitsWithAdditionalRotation(self.name.hash, 2) ^ flipBitsWithAdditionalRotation(self.localizedName.hash, 3) ^ flipBitsWithAdditionalRotation(self.namespaces.hash, 4);
}

- (NSString *)description {
    return [NSString stringWithFormat:
                         @"%@ { \n"
                          "\tlanguageCode: %@, \n"
                          "\tpageTitleText: %@, \n"
                          "\tname: %@, \n"
                          "\tlocalizedName: %@ \n"
                          "\tnamespaces: %@ \n"
                          "}",
                         [super description], self.languageCode, self.pageTitleText, self.name, self.localizedName, self.namespaces];
}

#pragma mark - Computed Properties

- (NSURL *)siteURL {
    return [NSURL wmf_URLWithDefaultSiteAndlanguage:self.languageCode];
}

- (NSURL *)articleURL {
    return [[self siteURL] wmf_URLWithTitle:self.pageTitleText];
}

#pragma Explore feed preferences

- (WMFExploreFeedContentController *)feedContentController {
    return MWKDataStore.shared.feedContentController;
}

- (BOOL)isInFeed {
    return [self.feedContentController anyContentGroupsVisibleInTheFeedForSiteURL:self.siteURL];
}

- (BOOL)isInFeedForContentGroupKind:(WMFContentGroupKind)contentGroupKind {
    return [[self.feedContentController languageCodesForContentGroupKind:contentGroupKind] containsObject:self.languageCode];
}

@end

NS_ASSUME_NONNULL_END
