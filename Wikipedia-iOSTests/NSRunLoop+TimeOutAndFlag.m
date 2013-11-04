//
// NSRunLoop+TimeOutAndFlag.m
//
//

#import "NSRunLoop+TimeOutAndFlag.h"

@implementation NSRunLoop (TimeOutAndFlag)

- (void)runUntilTimeout:(NSTimeInterval)delay orFinishedFlag:(BOOL*)finished;
{
    NSDate * endDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    do {
        [self runMode:NSDefaultRunLoopMode beforeDate:nil];
    } while (!*finished && [endDate compare:[NSDate date]]==NSOrderedDescending);
}

@end