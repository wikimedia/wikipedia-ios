#import "WMFTrendingViewController.h"
#import "WMFArticlePreviewDataSource.h"
#import "MWKArticle.h"
#import "WMFArticlePreviewFetcher.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKDataStore.h"
#import "MWKTitle.h"
#import "WMFTrendingFetcher.h"
#import "NSDate+Utilities.h"

@interface WMFTrendingViewController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) NSDate* date;

@end

@implementation WMFTrendingViewController

- (instancetype)initWithSite:(MWKSite*)site date:(NSDate*)date dataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.site                 = site;
        self.date                 = date;
        self.dataStore            = dataStore;
        self.dataSource.tableView = self.tableView;
    }
    return self;
}

- (NSString*)title {
    //TODO: localize
    return @"Trending Articles";
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self getTrendingTitles];
}

- (NSArray<NSString*>*)titleExclusions {
    return @[
        @"Main_Page",       // TODO: exclude name of main page for site language
        @"-",
        @"Test_card",
        @"XHamster",
        @"Web_scraping"
    ];
}

- (NSArray<NSString*>*)titlePrefixExclusions {
    return @[
        @"User:",           // maybe just exclude if title has a ":"
        @"Special:",        // Are these prefixes the same in every lang?
        @"File:"            //
    ];
}

- (BOOL)isTitleExcluded:(NSString*)title {
    for (NSString* excludedPrefix in [self titlePrefixExclusions]) {
        if ([title hasPrefix:excludedPrefix]) {
            return YES;
        }
    }
    return [[self titleExclusions] containsObject:title];
}

- (void)getTrendingTitles {
    // Try to first fetch trending for today's date.
    [[[WMFTrendingFetcher alloc] init] fetchTrendingForSite:self.site date:self.date]
    .then(^(NSArray* results) {
        return results;
    })
    .catch(^(NSError* error){
        // If a "today" fetch failed, try to fetch yesterday's trending data.
        // Needed because trending data is compiled once daily, and local date may or
        // may not be +1 days from last trending compilation date (think times zones).
        if ([self.date isToday]) {
            return [[[WMFTrendingFetcher alloc] init] fetchTrendingForSite:self.site date:[NSDate dateYesterday]].then(^(NSArray* results) {
                return results;
            })
            .catch(^(NSError* error){
                NSLog(@"Error = %@", error);
                return error;
            });
        } else {
            return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
                resolve(error);
            }];
        }
    })
    .catch(^(NSError* error){
        NSLog(@"Error = %@", error);
        return error;
    })
    .then(^(NSArray* results){
        return [self getMWKTitlesFromResults:results];
    })
    .then(^(NSArray<MWKTitle*>* titles){
        return [self getArticlePreviewDataSourceForTitles:titles];
    })
    .catch(^(NSError* error){
        NSLog(@"Error = %@", error);
        return error;
    })
    .then(^(WMFArticlePreviewDataSource* previewsDataSource){
        self.dataSource = previewsDataSource;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    });
}

- (AnyPromise*)getMWKTitlesFromResults:(NSArray*)results {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSArray<MWKTitle*>* titles = [[results bk_select:^BOOL (NSDictionary* result) {
            return ![self isTitleExcluded:result[@"article"]];
        }] bk_map:^id (NSDictionary* result) {
            return [[MWKTitle alloc] initWithString:result[@"article"] site:self.site];
        }];
        resolve(titles);
    }];
}

- (AnyPromise*)getArticlePreviewDataSourceForTitles:(NSArray<MWKTitle*>*)titles {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        WMFArticlePreviewDataSource* previewsDataSource =
            [[WMFArticlePreviewDataSource alloc] initWithTitles:titles site:self.site fetcher:[[WMFArticlePreviewFetcher alloc] init]];

        [((WMFArticlePreviewDataSource*)previewsDataSource) fetch]
        .then(^(NSArray<MWKSearchResult*>* searchResults){
            resolve(previewsDataSource);
        })
        .catch(^(NSError* error){
            resolve(error);
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    @weakify(self);
    UIBarButtonItem* xButton = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self.presentingViewController dismissViewControllerAnimated : YES completion : nil];
    }];
    self.navigationItem.leftBarButtonItem  = xButton;
    self.navigationItem.rightBarButtonItem = nil;
}

@end
