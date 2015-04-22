//
//  MWKTestCase.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"
#import "WMFTestFixtureUtilities.h"

@implementation MWKTestCase

- (NSData*)loadDataFile:(NSString*)name ofType:(NSString*)extension {
    return [[self wmf_bundle] wmf_dataFromContentsOfFile:name ofType:extension];
}

- (id)loadJSON:(NSString*)name {
    return [[self wmf_bundle] wmf_jsonFromContentsOfFile:name];
}

@end
