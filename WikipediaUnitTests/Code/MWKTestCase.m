#import "MWKTestCase.h"
#import "WMFTestFixtureUtilities.h"

@implementation MWKTestCase

- (NSData *)loadDataFile:(NSString *)name ofType:(NSString *)extension {
    return [[self wmf_bundle] wmf_dataFromContentsOfFile:name ofType:extension];
}

- (id)loadJSON:(NSString *)name {
    return [[self wmf_bundle] wmf_jsonFromContentsOfFile:name];
}

- (NSString *)allObamaHTML {
    return [[[self loadJSON:@"Obama"][@"mobileview"][@"sections"] wmf_map:^NSString *(NSDictionary *section) {
        return section[@"text"];
    }] componentsJoinedByString:@""];
}

- (NSURL *)obamaBaseURL {
    return [NSURL URLWithString:@"https://en.m.wikipedia.org/wiki/Barack_Obama"];
}

- (NSURL *)obamaLeadImageURL {
    return [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/816px-BarackObamaportrait.jpg"];
}

@end
