//
//  MWKImage+AssociationTestUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage+AssociationTestUtils.h"
#import <BlocksKit/BlocksKit.h>
#import "MWKSite.h"
#import "MWKArticle.h"

@implementation MWKImage (AssociationTestUtils)

+ (instancetype)imageAssociatedWithSourceURL:(NSString*)imageURL {
    MWKTitle* title     = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:title dataStore:nil];
    return [[self alloc] initWithArticle:article sourceURLString:imageURL];
}

- (MWKImageInfo*)createAssociatedInfo {
    return [MWKImageInfo infoAssociatedWithSourceURL:self.sourceURLString];
}

+ (id)mappedFromInfoObjects:(id)infoObjectList {
    return [infoObjectList bk_map:^MWKImage*(MWKImageInfo* info) {
        return [info createAssociatedImage];
    }];
}

@end

@implementation MWKImageInfo (AssociationTestUtils)

+ (instancetype)infoAssociatedWithSourceURL:(NSString*)imageURL {
    return [[self alloc] initWithCanonicalPageTitle:imageURL
                                   canonicalFileURL:[NSURL URLWithString:imageURL]
                                   imageDescription:nil
                                            license:nil
                                        filePageURL:nil
                                      imageThumbURL:nil
                                              owner:nil
                                          imageSize:CGSizeZero
                                          thumbSize:CGSizeZero];
}

- (MWKImage*)createAssociatedImage {
    return [MWKImage imageAssociatedWithSourceURL:self.canonicalFileURL.absoluteString];
}

+ (id)mappedFromImages:(id)imageList {
    return [imageList bk_map:^MWKImageInfo*(MWKImage* img) {
        return [img createAssociatedInfo];
    }];
}

@end