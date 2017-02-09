#import "MWKLanguageLink.h"

@interface MWKLanguageLink ()

@property (readwrite, copy, nonatomic) NSString *languageCode;
@property (readwrite, copy, nonatomic) NSString *pageTitleText;
@property (readwrite, copy, nonatomic) NSString *localizedName;
@property (readwrite, copy, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_BEGIN

@implementation MWKLanguageLink

WMF_SYNTHESIZE_IS_EQUAL(MWKLanguageLink, isEqualToLanguageLink:)

- (instancetype)initWithLanguageCode:(NSString *)languageCode
                       pageTitleText:(NSString *)pageTitleText
                                name:(NSString *)name
                       localizedName:(NSString *)localizedName {
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
    return WMF_RHS_PROP_EQUAL(languageCode, isEqualToString:) && WMF_RHS_PROP_EQUAL(pageTitleText, isEqualToString:) && WMF_RHS_PROP_EQUAL(name, isEqualToString:) && WMF_RHS_PROP_EQUAL(localizedName, isEqualToString:);
}

- (NSComparisonResult)compare:(MWKLanguageLink *)other {
    return [self.languageCode compare:other.languageCode];
}

- (NSUInteger)hash {
    return self.languageCode.hash ^ flipBitsWithAdditionalRotation(self.pageTitleText.hash, 1) ^ flipBitsWithAdditionalRotation(self.name.hash, 2) ^ flipBitsWithAdditionalRotation(self.localizedName.hash, 3);
}

- (NSString *)description {
    return [NSString stringWithFormat:
                         @"%@ { \n"
                          "\tlanguageCode: %@, \n"
                          "\tpageTitleText: %@, \n"
                          "\tname: %@, \n"
                          "\tlocalizedName: %@ \n"
                          "}",
                         [super description], self.languageCode, self.pageTitleText, self.name, self.localizedName];
}

#pragma mark - Computed Properties

- (NSURL *)siteURL {
    return [NSURL wmf_URLWithDefaultSiteAndlanguage:self.languageCode];
}

- (NSURL *)articleURL {
    return [[self siteURL] wmf_URLWithTitle:self.pageTitleText];
}

@end

NS_ASSUME_NONNULL_END
