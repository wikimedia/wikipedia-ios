//
//  SSBaseCollectionReusableView.m
//  SSDataSources
//
//  Created by Jonathan Hersh on 8/8/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSDataSources.h"

@implementation SSBaseCollectionReusableView

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

+ (instancetype)supplementaryViewForCollectionView:(UICollectionView *)cv
                                              kind:(NSString *)kind
                                         indexPath:(NSIndexPath *)indexPath {
    
    return [cv dequeueReusableSupplementaryViewOfKind:kind
                                  withReuseIdentifier:[self identifier]
                                         forIndexPath:indexPath];
}

@end
