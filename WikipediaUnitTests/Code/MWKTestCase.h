#import <XCTest/XCTest.h>

@interface MWKTestCase : XCTestCase

- (id)loadDataFile:(NSString *)name ofType:(NSString *)extension;
- (id)loadJSON:(NSString *)name;

@property (nonatomic, copy, readonly) NSString *allObamaHTML;
@property (nonatomic, copy, readonly) NSURL *obamaBaseURL;
@property (nonatomic, copy, readonly) NSURL *obamaLeadImageURL;

@end
