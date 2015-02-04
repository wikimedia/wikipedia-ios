//
//  MWKImageInfo+MWKImageComparison.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfo+MWKImageComparison.h"
#import "MWKImage.h"
#import "WikipediaAppUtils.h"

NSString* const MWKImageAssociationKeyPath = @"canonicalFilename";

@implementation MWKImageInfo (MWKImageComparison)

- (id)imageAssociationValue
{
    return self.canonicalFilename;
}

- (BOOL)isAssociatedWithImage:(MWKImage *)image
{
    return [self.canonicalFilename isEqualToString:image.canonicalFilename];
}

@end

@implementation MWKImage (MWKImageInfoComparison)

- (id)infoAssociationValue
{
    return self.canonicalFilename;
}

- (BOOL)isAssociatedWithInfo:(MWKImageInfo *)info
{
    return [info isAssociatedWithImage:self];
}

@end
