//
//  UICollectionViewFlowLayout+NSCopying.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UICollectionViewFlowLayout+NSCopying.h"

@implementation UICollectionViewFlowLayout (NSCopying)

- (instancetype)copyWithZone:(NSZone *)zone
{
    UICollectionViewFlowLayout *copy = [[self class] new];
    copy.scrollDirection = self.scrollDirection;
    copy.minimumInteritemSpacing = self.minimumInteritemSpacing;
    copy.sectionInset = self.sectionInset;
    copy.minimumLineSpacing = self.minimumLineSpacing;
    copy.itemSize = self.itemSize;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        copy.estimatedItemSize = self.estimatedItemSize;
    }
    copy.headerReferenceSize = self.headerReferenceSize;
    copy.footerReferenceSize = self.footerReferenceSize;
    return copy;
}

@end
