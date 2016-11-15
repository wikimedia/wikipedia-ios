
#import "WMFDatabaseStack.h"
#import "YapDatabase+WMFExtensions.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKDataStore.h"
#import "WMFContentGroupDataStore.h"

@interface WMFDatabaseStack ()

@property (nonatomic, strong, readwrite) YapDatabase *database;
@property (nonatomic, strong, readwrite) MWKDataStore *userStore;
@property (nonatomic, strong, readwrite) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong, readwrite) WMFContentGroupDataStore *contentStore;
@property (nonatomic, strong, readwrite) WMFContentGroupDataStore *exploreUIContentStore;

@end

@implementation WMFDatabaseStack

+ (WMFDatabaseStack *)sharedInstance {
    static dispatch_once_t onceToken;
    static WMFDatabaseStack *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.database = [YapDatabase wmf_databaseWithDefaultConfiguration];
        self.database.maxConnectionPoolCount = 0;
    }
    return self;
}

- (void)tearDownStack {
    self.previewStore = nil;
    self.contentStore = nil;
    self.userStore = nil;
    self.exploreUIContentStore = nil;
}

- (void)setupStack {
    self.previewStore = [[WMFArticlePreviewDataStore alloc] initWithDatabase:self.database];
    self.contentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:self.database];
    self.userStore = [[MWKDataStore alloc] initWithDatabase:self.database];
    WMFContentGroupDataStore *uiStore = [[WMFContentGroupDataStore alloc] initWithDatabase:self.database];
    uiStore.databaseSyncingEnabled = NO;
    self.exploreUIContentStore = uiStore;
}

@end
