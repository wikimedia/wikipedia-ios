#import "ToCInteractionFunnel.h"

static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kTimestampKey = @"ts";

@implementation ToCInteractionFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppToCInteraction
    self = [super initWithSchema:@"MobileWikiAppToCInteraction"
                         version:18071228];
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kTimestampKey] = self.timestamp;
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)logOpen {
    [self log:@{@"action": @"open"}];
}

- (void)logClose {
    [self log:@{@"action": @"close"}];
}

- (void)logClick {
    [self log:@{@"action": @"click"}];
}

@end
