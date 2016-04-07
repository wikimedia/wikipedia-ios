//
//  WEWeakReference.h
//  WEPopover
//
//  Created by Werner Altewischer on 25/02/16.
//  Copyright © 2016 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WEWeakReference : NSObject

@property (nonatomic, weak) id object;

+ (instancetype)weakReferenceWithObject:(id)object;

@end
