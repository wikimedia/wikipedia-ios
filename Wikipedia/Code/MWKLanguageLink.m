//
//  MWKLanguageLink.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKLanguageLink.h"
#import "NSObjectUtilities.h"
#import "MWKTitle.h"
#import "WikipediaAppUtils.h"

@interface MWKLanguageLink ()

@property (readwrite, copy, nonatomic) NSString* languageCode;
@property (readwrite, copy, nonatomic) NSString* pageTitleText;
@property (readwrite, copy, nonatomic) NSString* localizedName;
@property (readwrite, copy, nonatomic) NSString* name;

@end

NS_ASSUME_NONNULL_BEGIN

@implementation MWKLanguageLink

WMF_SYNTHESIZE_IS_EQUAL(MWKLanguageLink, isEqualToLanguageLink :)

- (instancetype)initWithLanguageCode:(NSString*)languageCode
                       pageTitleText:(NSString*)pageTitleText
                                name:(NSString*)name
                       localizedName:(NSString*)localizedName {
    self = [super init];
    if (self) {
        self.languageCode  = languageCode;
        self.pageTitleText = pageTitleText;
        self.name          = name;
        self.localizedName = localizedName;
    }
    return self;
}

- (BOOL)isEqualToLanguageLink:(MWKLanguageLink*)rhs {
    return WMF_RHS_PROP_EQUAL(languageCode, isEqualToString:)
           && WMF_RHS_PROP_EQUAL(pageTitleText, isEqualToString:)
           && WMF_RHS_PROP_EQUAL(name, isEqualToString:)
           && WMF_RHS_PROP_EQUAL(localizedName, isEqualToString:);
}

- (NSComparisonResult)compare:(MWKLanguageLink*)other {
    return [self.languageCode compare:other.languageCode];
}

- (NSUInteger)hash {
    return self.languageCode.hash
           ^ flipBitsWithAdditionalRotation(self.pageTitleText.hash, 1)
           ^ flipBitsWithAdditionalRotation(self.name.hash, 2)
           ^ flipBitsWithAdditionalRotation(self.localizedName.hash, 3);
}

- (NSString*)description {
    return [NSString stringWithFormat:
            @"%@ { \n"
            "\tlanguageCode: %@, \n"
            "\tpageTitleText: %@, \n"
            "\tname: %@, \n"
            "\tlocalizedName: %@ \n"
            "}", [super description], self.languageCode, self.pageTitleText, self.name, self.localizedName];
}

#pragma mark - Computed Properties

- (MWKTitle*)title {
    return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:self.pageTitleText fragment:nil];
}

- (MWKSite*)site {
    return [MWKSite siteWithLanguage:self.languageCode];
}

@end

NS_ASSUME_NONNULL_END
