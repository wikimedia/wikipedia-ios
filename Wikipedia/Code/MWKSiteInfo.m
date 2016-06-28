//
//  MWKSiteInfo.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteInfo.h"
#import "NSObjectUtilities.h"
#import "MediaWikiKit.h"

typedef NS_ENUM (NSUInteger, MWKSiteInfoNSCodingSchemaVersion) {
    MWKSiteInfoNSCodingSchemaVersion_1 = 1
};

static NSString* const MWKSiteInfoNSCodingSchemaVersionKey = @"siteInfoSchemaVersion";

NS_ASSUME_NONNULL_BEGIN

@interface MWKSiteInfo ()
@property (readwrite, copy, nonatomic) NSURL* domainURL;
@property (readwrite, copy, nonatomic) NSString* mainPageTitleText;
@end

@implementation MWKSiteInfo

- (instancetype)initWithDomainURL:(NSURL*)domainURL
                mainPageTitleText:(NSString*)mainPage {
    self = [super init];
    if (self) {
        self.domainURL         = [domainURL wmf_domainURL];
        self.mainPageTitleText = mainPage;
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ {"
            "\t site: %@,\n"
            "\t mainPage: %@ \n"
            "}\n", [super description], self.domainURL, self.mainPageTitleText];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKSiteInfo class]]) {
        return [self isEqualToSiteInfo:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToSiteInfo:(MWKSiteInfo*)siteInfo {
    return WMF_EQUAL_PROPERTIES(self, domainURL, isEqual:, siteInfo)
           && WMF_EQUAL_PROPERTIES(self, mainPageTitleText, isEqualToString:, siteInfo);
}

- (NSUInteger)hash {
    return self.domainURL.hash ^ flipBitsWithAdditionalRotation(self.mainPageTitleText.hash, 1);
}

#pragma mark - Computed Properties

- (NSURL*)mainPageURL {
    return [self.domainURL wmf_URLWithTitle:self.mainPageTitleText];
}

@end

NS_ASSUME_NONNULL_END
