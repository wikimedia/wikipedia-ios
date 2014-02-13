//  Created by Adam Baso on 2/14/14.

#import "ZeroConfigState.h"

@implementation ZeroConfigState

-(void)setZeroOnDialogShownOnce
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES
                                              forKey:@"ZeroOnDialogShownOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)zeroOnDialogShownOnce
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroOnDialogShownOnce"];
}

-(void)setZeroOffDialogShownOnce
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES
                                              forKey:@"ZeroOffDialogShownOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)zeroOffDialogShownOnce
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroOffDialogShownOnce"];
}

-(void)toggleWarnWhenLeaving
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool: ![self warnWhenLeaving]]
                                              forKey:@"ZeroWarnWhenLeaving"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)warnWhenLeaving
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"];
}

-(void)toggleDevMode
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool: ![self devMode]]
                                              forKey:@"ZeroDevMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)devMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroDevMode"];
}

@end
