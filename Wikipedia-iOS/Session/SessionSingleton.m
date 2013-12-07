//  Created by Monte Hurd on 12/6/13.

#import "SessionSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "ArticleDataContextSingleton.h"

@implementation SessionSingleton

+ (SessionSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self dataSetup];
    }
    return self;
}

-(void)dataSetup
{
    ArticleDataContextSingleton *articleDataContext = [ArticleDataContextSingleton sharedInstance];

    // Make site available
    self.site = (Site *)[articleDataContext getEntityForName: @"Site" withPredicateFormat:@"name == %@", @"wikipedia.org"];

    // Make domain available
    self.domain = (Domain *)[articleDataContext getEntityForName: @"Domain" withPredicateFormat:@"name == %@", @"en"];
}

@end
