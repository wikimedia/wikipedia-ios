@import Quick;
@import Nimble;

#import "LSNocilla+Quick.h"
#import "LSNocilla+AnyRequest.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "XCTestCase+PromiseKit.h"
#import "WMFBaseExploreSectionController.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import <AFNetworking/AFNetworking.h>

// Subclass for testing basic functionality
@interface WMFDummyExploreSectionController : WMFBaseExploreSectionController

@property (nonatomic, strong) AFHTTPSessionManager* manager;

@end

@implementation WMFDummyExploreSectionController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [[AFHTTPSessionManager alloc] init];
    }
    return self;
}

- (NSString*)description {
    // override description to prevent base explore section impl, which assumes conformance to WMFExploreSectionController
    return [NSString stringWithFormat:@"<%@ %p>", [self class], self];
}

- (NSString*)placeholderCellIdentifier {
    return [WMFArticlePlaceholderTableViewCell identifier];
}

- (UINib*)placeholderCellNib {
    return [WMFArticlePlaceholderTableViewCell wmf_classNib];
}

- (AnyPromise*)fetchData {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self.manager GET:@"https://test.io/foo" parameters:nil progress:NULL success:^(NSURLSessionDataTask* _Nonnull task, id _Nullable responseObject) {
            resolve([WMFDummyExploreSectionController dummyItems]);
        } failure:^(NSURLSessionDataTask* _Nullable task, NSError* _Nonnull error) {
            resolve(error);
        }];
    }];
}

+ (NSArray*)dummyItems {
    return @[@"foo", @"bar", @"baz"];
}

@end

QuickConfigurationBegin(WMFSharedSectionControllerTests)

+ (void)configure : (Configuration*)configuration {
    sharedExamples(@"a fetching section controller", ^(QCKDSLSharedExampleContext getContext) {
        __block FBKVOController* kvoController;
        __block NSMutableArray* itemsPerKVONotification;
        __block WMFBaseExploreSectionController* sectionController;
        __block NSArray* expectedSuccessItems;
        __block MWKDataStore* tempDataStore;

        startAndStopStubbingBetweenEach();

        beforeEach(^{
            tempDataStore = [MWKDataStore temporaryDataStore];
            kvoController = [[FBKVOController alloc] initWithObserver:self retainObserved:NO];
            itemsPerKVONotification = [NSMutableArray new];

            NSDictionary* context = getContext();
            Class SectionControllerClass = context[@"controllerClass"];
            sectionController = [[SectionControllerClass alloc] initWithDataStore:tempDataStore];
            expectedSuccessItems = context[@"expectedSuccessItems"];
            [kvoController observe:sectionController
                           keyPath:WMF_SAFE_KEYPATH(sectionController, items)
                           options:0
                             block:^(id observer, WMFBaseExploreSectionController* controller, NSDictionary* change) {
                [itemsPerKVONotification addObject:[controller items]];
            }];
        });

        afterEach(^{
            [tempDataStore removeFolderAtBasePath];
        });

        /*
            `expect()` takes a block—implicitly—which is repeatedly invoked to get the value of the given expression.
            therefore, we need to be smart about `expect`-ing the value of a promise returned by a function to prevent
            the function from being repeatedly invoked.
         */
                #define expectValueOfPromiseReturnedBySectionControllerCall(fetchMethod) \
    ^ { \
        AnyPromise* fetch = [sectionController fetchMethod]; \
        return expect(fetch.value); \
    } ()

        context(@"initial state", ^{
            it(@"should be filled with placeholders, if it supports placeholders", ^{
                NSUInteger numberOfPlaceholders = [sectionController numberOfPlaceholderCells];
                if (numberOfPlaceholders > 0
                    && [sectionController placeholderCellNib]
                    && [sectionController placeholderCellIdentifier]) {
                    expect(@([sectionController.items bk_all:^BOOL (id obj) {
                        return [obj isKindOfClass:[NSNumber class]];
                    }])).to(beTrue());
                    expect(@([sectionController containsPlaceholders])).to(beTrue());
                    expect(sectionController.items).to(haveCount(@(numberOfPlaceholders)));
                } else {
                    expect(sectionController.items).to(beEmpty());
                }
            });
        });

        context(@"previous request failed", ^{
            __block NSError* initialError;

            beforeEach(^{
                stubAnyRequest().andReturn(500);

                expectValueOfPromiseReturnedBySectionControllerCall(fetchDataIfNeeded)
                .withTimeout(10)
                .toEventually(beAKindOf([NSError class]));

                initialError = [[sectionController items] firstObject];

                expect(initialError).to(beAKindOf([NSError class]));

                expect(itemsPerKVONotification).to(equal(@[@[initialError]]));

                // restart nocilla stubbing to remove failure stub & fail on any unexpected requests
                [[LSNocilla sharedInstance] stop];
                [[LSNocilla sharedInstance] start];
            });

            it(@"should immediately yield an error when asked to fetch if needed", ^{
                expectValueOfPromiseReturnedBySectionControllerCall(fetchDataIfNeeded)
                .withTimeout(5)
                .toEventually(beIdenticalTo(initialError));

                expect(itemsPerKVONotification).to(haveCount(@1));
            });

            it(@"should retry when asked to fetch by user", ^{
                stubAnyRequest().andReturn(200);

                expectValueOfPromiseReturnedBySectionControllerCall(fetchDataUserInitiated)
                .withTimeout(5)
                .toEventually(equal(expectedSuccessItems));

                expect(@([sectionController containsPlaceholders])).to(beFalse());

                expect(sectionController.items).to(equal(expectedSuccessItems));
            });

            it(@"should retry when asked to fetch and ignore current error", ^{
                stubAnyRequest().andReturn(200);

                expectValueOfPromiseReturnedBySectionControllerCall(fetchDataIfError)
                .withTimeout(5)
                .toEventually(beAKindOf([NSArray class]));

                expect(@([sectionController containsPlaceholders])).to(beFalse());

                expect(sectionController.items).to(equal(expectedSuccessItems));
            });
        });

        // pending...

        xcontext(@"has items", ^{
            it(@"should only fetch if the user initiated it.", ^{
            });
        });

        xcontext(@"is fetching", ^{
            it(@"should not perform other fetches", ^{
            });
        });
    });
}

QuickConfigurationEnd

//TODO: renable - what is this doing?
//QuickSpecBegin(WMFBaseExploreSectionControllerTests)
//
//itBehavesLike(@"a fetching section controller", ^{
//    return @{@"controllerClass": [WMFDummyExploreSectionController class],
//             @"expectedSuccessItems": [WMFDummyExploreSectionController dummyItems]};
//});
//
//QuickSpecEnd
