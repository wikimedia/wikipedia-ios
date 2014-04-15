//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface ZeroConfigState : NSObject

@property (strong, nonatomic) NSString *partnerXcs;
@property (nonatomic) BOOL disposition;
@property (nonatomic, readonly) BOOL zeroOnDialogShownOnce;
@property (nonatomic, readonly) BOOL zeroOffDialogShownOnce;
@property (nonatomic, readonly) BOOL warnWhenLeaving;
@property (nonatomic, readonly) BOOL fakeZeroOn;

-(void)setZeroOnDialogShownOnce;
-(void)setZeroOffDialogShownOnce;
-(void)toggleWarnWhenLeaving;
-(void)toggleFakeZeroOn;

@end
