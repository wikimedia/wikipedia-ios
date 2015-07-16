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
@property (readwrite, copy, nonatomic) MWKSite* site;
@property (readwrite, copy, nonatomic) NSString* mainPageTitleText;
@end

@implementation MWKSiteInfo

- (instancetype)initWithSite:(MWKSite*)site mainPageTitleText:(NSString*)mainPage {
    self = [super init];
    if (self) {
        self.site              = site;
        self.mainPageTitleText = mainPage;
    }
    return self;
}

- (instancetype)initWithSite:(MWKSite*)site exportedData:(NSDictionary*)data {
    return [self initWithSite:site mainPageTitleText:data[@"mainPage"]];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ {"
            "\t site: %@,\n"
            "\t mainPage: %@ \n"
            "}\n", [super description], self.site, self.mainPageTitleText];
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
    return WMF_EQUAL_PROPERTIES(self, site, isEqualToSite:, siteInfo)
           && WMF_EQUAL_PROPERTIES(self, mainPageTitleText, isEqualToString:, siteInfo);
}

- (NSUInteger)hash {
    return self.site.hash ^ flipBitsWithAdditionalRotation(self.mainPageTitleText.hash, 1);
}

#pragma mark - Computed Properties

- (MWKTitle*)mainPageTitle {
    return [self.site titleWithString:self.mainPageTitleText];
}

@end

NS_ASSUME_NONNULL_END
