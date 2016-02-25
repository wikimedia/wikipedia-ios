//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ZeroConfigState.h"

@implementation ZeroConfigState

- (void)setZeroOnDialogShownOnce {
    [[NSUserDefaults standardUserDefaults] setObject:@YES
                                              forKey:@"ZeroOnDialogShownOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroOnDialogShownOnce"];
}

- (void)setWarnWhenLeaving:(BOOL)warnWhenLeaving {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:warnWhenLeaving]
                                              forKey:@"ZeroWarnWhenLeaving"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)warnWhenLeaving {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"];
}

@end
