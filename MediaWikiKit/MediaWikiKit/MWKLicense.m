//
//  MWKLicense.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKLicense.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

static NSString* const MWKLicenseCodeKey = @"code";
static NSString* const MWKLicenseShortDescKey = @"shortDescription";
static NSString* const MWKLicenseURLKey = @"URL";

@implementation MWKLicense

- (instancetype)initWithCode:(NSString*)code
            shortDescription:(NSString*)shortDescription
                         URL:(NSURL*)URL
{
    self = [super init];
    if (self) {
        _code = [code copy];
        _shortDescription = [shortDescription copy];
        _URL = URL;
    }
    return self;
}

+ (instancetype)licenseWithExportedData:(NSDictionary*)exportedData
{
    return [[MWKLicense alloc] initWithCode:exportedData[MWKLicenseCodeKey]
                           shortDescription:exportedData[MWKLicenseShortDescKey]
                                        URL:[NSURL URLWithString:exportedData[MWKLicenseURLKey]]];
}

- (id)dataExport
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict wmf_maybeSetObject:self.code forKey:MWKLicenseCodeKey];
    [dict wmf_maybeSetObject:self.shortDescription forKey:MWKLicenseShortDescKey];
    [dict wmf_maybeSetObject:self.URL.absoluteString forKey:MWKLicenseURLKey];
    return dict;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) { return YES; }
    else if ([object isKindOfClass:[MWKLicense class]]) { return [self isEqualToLicense:object]; }
    else { return NO; }
}

- (BOOL)isEqualToLicense:(MWKLicense*)other
{
    return [self.code isEqualToString:other.code];
}

- (NSUInteger)hash
{
    return [self.code hash];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.code, self.shortDescription];
}

@end
