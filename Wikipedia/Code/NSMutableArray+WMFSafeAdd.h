//
//  NSMutableArray+WMFMaybeAdd.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray<ObjectType> (WMFMaybeAdd)

- (BOOL)wmf_safeAddObject:(nullable ObjectType)object;

@end

NS_ASSUME_NONNULL_END
