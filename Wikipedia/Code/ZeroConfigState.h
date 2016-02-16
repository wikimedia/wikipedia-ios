//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZeroConfigState : NSObject

@property (atomic, copy, nullable) NSString* partnerXcs;
@property (atomic) BOOL disposition;
@property (atomic) BOOL sentMCCMNC;

@property (nonatomic, readonly) BOOL zeroOnDialogShownOnce;
@property (nonatomic) BOOL warnWhenLeaving;
@property (nonatomic, readonly) BOOL fakeZeroOn;

- (void)setZeroOnDialogShownOnce;
- (void)toggleFakeZeroOn;

@end

NS_ASSUME_NONNULL_END
