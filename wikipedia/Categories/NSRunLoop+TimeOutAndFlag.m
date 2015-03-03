#import "NSRunLoop+TimeOutAndFlag.h"

// Based on example from: https://gist.github.com/n-b/2299695

@implementation NSRunLoop (TimeOutAndFlag)

- (void)runUntilTimeout:(NSTimeInterval)delay orFinishedFlag:(BOOL*)finished;
{
    NSDate* endDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    do {
        [self runMode:NSDefaultRunLoopMode beforeDate:nil];
    } while (!*finished && [endDate compare:[NSDate date]] == NSOrderedDescending);
}

@end