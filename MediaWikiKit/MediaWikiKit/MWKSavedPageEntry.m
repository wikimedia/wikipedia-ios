//
//  MWKSavedPageEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

@interface MWKSavedPageEntry ()

@property (readwrite, strong, nonatomic) MWKTitle* title;

@end
@implementation MWKSavedPageEntry

- (instancetype)initWithTitle:(MWKTitle*)title {
    NSParameterAssert(title);
    self = [self initWithSite:title.site];
    if (self) {
        self.title = title;
    }
    return self;
}

- (id)initWithDict:(NSDictionary*)dict {
    // Is this safe to run things before init?
    NSString* domain   = [self requiredString:@"domain" dict:dict];
    NSString* language = [self requiredString:@"language" dict:dict];

    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        self.title = [self requiredTitle:@"title" dict:dict allowEmpty:NO];
    }
    return self;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:self.site.domain forKey:@"domain"];
    [dict wmf_maybeSetObject:self.site.language forKey:@"language"];
    [dict wmf_maybeSetObject:self.title.text forKey:@"title"];

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
