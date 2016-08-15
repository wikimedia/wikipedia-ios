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

@implementation MWKImageInfo (MWKImageComparison)

- (BOOL)isAssociatedWithImage:(MWKImage *)image {
    return [self.imageAssociationValue isEqual:image.infoAssociationValue];
}

@end

@implementation MWKImage (MWKImageInfoComparison)

- (id)infoAssociationValue {
    return self.fileNameNoSizePrefix;
}

- (BOOL)isAssociatedWithInfo:(MWKImageInfo *)info {
    return [info isAssociatedWithImage:self];
}

@end
