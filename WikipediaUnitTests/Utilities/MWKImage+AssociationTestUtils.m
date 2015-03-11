//
//  MWKImage+AssociationTestUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage+AssociationTestUtils.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKImage (AssociationTestUtils)

+ (instancetype)imageAssociatedWithSourceURL:(NSString*)imageURL {
    return [[self alloc] initWithArticle:nil sourceURL:imageURL];
}

- (MWKImageInfo*)createAssociatedInfo {
    return [MWKImageInfo infoAssociatedWithSourceURL:self.sourceURL];
}

+ (id)mappedFromInfoObjects:(id)infoObjectList {
    return [infoObjectList bk_map:^MWKImage*(MWKImageInfo* info) {
        return [info createAssociatedImage];
    }];
}

@end

@implementation MWKImageInfo (AssociationTestUtils)

+ (instancetype)infoAssociatedWithSourceURL:(NSString*)imageURL {
    return [[self alloc] initWithCanonicalPageTitle:nil
                                   canonicalFileURL:nil
                                   imageDescription:nil
                                            license:nil
                                        filePageURL:nil
                                           imageURL:[NSURL URLWithString:imageURL]
                                      imageThumbURL:nil
                                              owner:nil
                                          imageSize:CGSizeZero
                                          thumbSize:CGSizeZero];
}

- (MWKImage*)createAssociatedImage {
    return [MWKImage imageAssociatedWithSourceURL:self.imageURL.absoluteString];
}

+ (id)mappedFromImages:(id)imageList {
    return [imageList bk_map:^MWKImageInfo*(MWKImage* img) {
        return [img createAssociatedInfo];
    }];
}

@end