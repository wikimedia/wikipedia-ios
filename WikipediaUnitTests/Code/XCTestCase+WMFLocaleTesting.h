#import <XCTest/XCTest.h>

typedef void (^WMFLocaleTest)(NSLocale *locale, XCTestExpectation *e);

@interface XCTestCase (WMFLocaleTesting)

- (void)wmf_runParallelTestsWithLocales:(NSArray *)localeIdentifiers block:(WMFLocaleTest)block;

- (void)wmf_runParallelTestsWithLocales:(NSArray *)localeIdentifiers
                                timeout:(NSTimeInterval)timeout
                                  block:(WMFLocaleTest)block;

@end
