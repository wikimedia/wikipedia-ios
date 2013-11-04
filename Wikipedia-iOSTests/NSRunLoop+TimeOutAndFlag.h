// quickie copied from https://gist.github.com/n-b/2299695
//
// NSRunLoop+TimeOutAndFlag.h
//
//

@interface NSRunLoop (TimeOutAndFlag)

- (void)runUntilTimeout:(NSTimeInterval)delay orFinishedFlag:(BOOL*)finished;

@end