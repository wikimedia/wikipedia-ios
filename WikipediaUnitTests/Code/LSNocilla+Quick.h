@import Quick;
#import <Nocilla/LSNocilla.h>

static inline void startAndStopStubbingBetweenEach() {
    beforeEach(^{
      [[LSNocilla sharedInstance] start];
    });
    afterEach(^{
      [[LSNocilla sharedInstance] stop];
    });
}

static inline void whenOffline(QCKDSLEmptyBlock closure) {
    context(@"when offline", ^{
      beforeEach(^{
        stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@".*" options:0 error:nil])
            .andFailWithError([NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorNetworkConnectionLost
                                              userInfo:nil]);
      });
    });
}
