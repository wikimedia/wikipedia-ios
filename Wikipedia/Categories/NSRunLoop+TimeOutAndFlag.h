// Based on example from: https://gist.github.com/n-b/2299695

@interface NSRunLoop (TimeOutAndFlag)

// Useful for using XCTest to test async code. See link above for details.
- (void)runUntilTimeout:(NSTimeInterval)delay orFinishedFlag:(BOOL*)finished;

@end
