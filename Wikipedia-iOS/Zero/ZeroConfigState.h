//
//  ZeroConfigState.h
//  Wikipedia-iOS
//
//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZeroConfigState : NSObject

@property (strong, nonatomic) NSString *partnerXcs;
@property (nonatomic) BOOL disposition;
@property (nonatomic, readonly) BOOL zeroOnDialogShownOnce;
@property (nonatomic, readonly) BOOL zeroOffDialogShownOnce;
@property (nonatomic, readonly) BOOL warnWhenLeaving;
@property (nonatomic, readonly) BOOL devMode;

-(void)setZeroOnDialogShownOnce;
-(void)setZeroOffDialogShownOnce;
-(void)toggleWarnWhenLeaving;
-(void)toggleDevMode;

@end
