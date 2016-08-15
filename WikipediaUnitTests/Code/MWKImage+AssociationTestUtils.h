//
//  MWKImage+AssociationTestUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage.h"
#import "MWKImageInfo.h"

@interface MWKImage (AssociationTestUtils)

+ (instancetype)imageAssociatedWithSourceURL:(NSString *)imageURL;

- (MWKImageInfo *)createAssociatedInfo;

+ (id)mappedFromInfoObjects:(id)infoObjects;

@end

@interface MWKImageInfo (AssociationTestUtils)

+ (instancetype)infoAssociatedWithSourceURL:(NSString *)imageURL;

- (MWKImage *)createAssociatedImage;

+ (id)mappedFromImages:(id)images;

@end
