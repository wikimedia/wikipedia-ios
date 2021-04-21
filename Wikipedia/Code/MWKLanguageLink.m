#import <WMF/MWKLanguageLink.h>
#import <WMF/WMFComparison.h>
#import <WMF/WMFHashing.h>
#import <WMF/NSURL+WMFLinkParsing.h>

@interface MWKLanguageLink ()

@property (readwrite, copy, nonatomic, nonnull) NSString *languageCode;
@property (readwrite, copy, nonatomic, nonnull) NSString *pageTitleText;
@property (readwrite, copy, nonatomic, nonnull) NSString *localizedName;
@property (readwrite, copy, nonatomic, nonnull) NSString *name;
@property (readwrite, copy, nonatomic, nullable) NSString *languageVariantCode;
@property (readwrite, copy, nonatomic, nullable) NSString *altISOCode;

@end

NS_ASSUME_NONNULL_BEGIN

@implementation MWKLanguageLink

- (instancetype)initWithLanguageCode:(nonnull NSString *)languageCode
                       pageTitleText:(nonnull NSString *)pageTitleText
                                name:(nonnull NSString *)name
                       localizedName:(nonnull NSString *)localizedName
                 languageVariantCode:(nullable NSString *)languageVariantCode
                          altISOCode:(nullable NSString *)altISOCode {
    self = [super init];
    if (self) {
        self.languageCode = languageCode;
        self.pageTitleText = pageTitleText;
        self.name = name;
        self.localizedName = localizedName;
        self.languageVariantCode = languageVariantCode;
        self.altISOCode = altISOCode;
    }
    return self;
}

WMF_SYNTHESIZE_IS_EQUAL(MWKLanguageLink, isEqualToLanguageLink:)

- (BOOL)isEqualToLanguageLink:(MWKLanguageLink *)rhs {
    return WMF_RHS_PROP_EQUAL(languageCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(pageTitleText, isEqualToString:) && WMF_RHS_PROP_EQUAL(name, isEqualToString:) && WMF_RHS_PROP_EQUAL(localizedName, isEqualToString:) && WMF_RHS_PROP_EQUAL(languageVariantCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(altISOCode, isEqualToString:);
}

- (NSComparisonResult)compare:(MWKLanguageLink *)other {
    return [self.contentLanguageCode compare:other.contentLanguageCode];
}

- (NSUInteger)hash {
    return self.languageCode.hash ^ flipBitsWithAdditionalRotation(self.pageTitleText.hash, 1) ^ flipBitsWithAdditionalRotation(self.name.hash, 2) ^ flipBitsWithAdditionalRotation(self.localizedName.hash, 3) ^ flipBitsWithAdditionalRotation(self.languageVariantCode.hash, 4) ^ flipBitsWithAdditionalRotation(self.altISOCode.hash, 4); // When languageVariantCode or altISOCode is nil, the XOR flips the bits
}

- (NSString *)description {
    return [NSString stringWithFormat:
                         @"%@ { \n"
                          "\tlanguageCode: %@, \n"
                          "\tlanguageVariantCode: %@, \n"
                          "\taltISOCode: %@, \n"
                          "\tpageTitleText: %@, \n"
                          "\tname: %@, \n"
                          "\tlocalizedName: %@ \n"
                          "}",
                         [super description], self.languageCode, self.languageVariantCode, self.altISOCode, self.pageTitleText, self.name, self.localizedName];
}

#pragma mark - Computed Properties

- (NSString *)contentLanguageCode {
    return (self.languageVariantCode == nil || [self.languageVariantCode isEqualToString:@""]) ? [self.languageCode copy] : [self.languageVariantCode copy];
}

- (NSURL *)siteURL {
    NSURL *siteURL = [NSURL wmf_URLWithDefaultSiteAndLanguageCode:self.languageCode];
    siteURL.wmf_languageVariantCode = self.languageVariantCode;
    return siteURL;
}

- (NSURL *)articleURL {
    NSURL *articleURL = [[self siteURL] wmf_URLWithTitle:self.pageTitleText];
    articleURL.wmf_languageVariantCode = self.languageVariantCode;
    return articleURL;
}

- (MWKLanguageLink *)languageLinkWithPageTitleText:(NSString *)pageTitleText {
    return [[MWKLanguageLink alloc] initWithLanguageCode:self.languageCode
                                           pageTitleText:pageTitleText
                                                    name:self.name
                                           localizedName:self.localizedName
                                     languageVariantCode:self.languageVariantCode
                                              altISOCode:self.altISOCode];
}

@end

NS_ASSUME_NONNULL_END
