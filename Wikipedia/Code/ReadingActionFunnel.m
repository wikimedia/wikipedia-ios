#import <WMF/ReadingActionFunnel.h>

@implementation ReadingActionFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppReadingAction
    self = [super initWithSchema:@"MobileWikiAppReadingAction" version:8233801];
    if (self) {
        self.appInstallID = [self persistentUUID:@"ReadingAction"];
    }
    return self;
}

- (void)logSomethingHappened {
    NSNumber *number = [NSNumber numberWithLong:time(NULL)];
    [self log:@{@"appInstallReadActionID": self.appInstallID,
                @"clientSideTS": (number ? number : @"")}];
}

@end
