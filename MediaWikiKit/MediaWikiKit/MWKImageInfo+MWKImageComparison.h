//
//  MWKImageInfo+MWKImageComparison.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfo.h"
#import "MWKImage.h"

FOUNDATION_EXPORT NSString* const MWKImageAssociationKeyPath;

@interface MWKImageInfo (MWKImageComparison)

- (id)imageAssociationValue;

- (BOOL)isAssociatedWithImage:(MWKImage*)image;

@end

@interface MWKImage (MWKImageInfoComparison)

- (id)infoAssociationValue;

- (BOOL)isAssociatedWithInfo:(MWKImageInfo*)info;

@end