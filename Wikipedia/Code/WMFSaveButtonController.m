#import "WMFSaveButtonController.h"
#import "MWKSavedPageList.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "SavedPagesFunnel.h"
#import "PiwikTracker+WMFExtensions.h"

@interface WMFSaveButtonController ()

- (instancetype)initWithControl:(UIControl *)button
                  barButtonItem:(UIBarButtonItem *)barButtonItem
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) SavedPagesFunnel *savedPagesFunnel;

@end

@implementation WMFSaveButtonController

- (instancetype)initWithControl:(UIControl *)button
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url {
    return [self initWithControl:button barButtonItem:nil savedPageList:savedPageList url:url];
}

+ (UIImage *)saveImage {
    static dispatch_once_t onceToken;
    static UIImage *saveImage;
    dispatch_once(&onceToken, ^{
        saveImage = [UIImage imageNamed:@"save"];
    });
    return saveImage;
}

+ (UIImage *)unsaveImage {
    static dispatch_once_t onceToken;
    static UIImage *unsaveImage;
    dispatch_once(&onceToken, ^{
        unsaveImage = [UIImage imageNamed:@"save-filled"];
    });
    return unsaveImage;
}

- (void)dealloc {
    [self unobserveURL:self.url];
}

- (instancetype)initWithBarButtonItem:(UIBarButtonItem *)barButtonItem
                        savedPageList:(MWKSavedPageList *)savedPageList
                                  url:(NSURL *)url {
    return [self initWithControl:nil barButtonItem:barButtonItem savedPageList:savedPageList url:url];
}

- (instancetype)initWithControl:(UIControl *)button
                  barButtonItem:(UIBarButtonItem *)barButtonItem
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url {
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.control = button;
        self.barButtonItem = barButtonItem;
        self.url = url;
        self.savedPageList = savedPageList;
        [self updateSavedButtonState];
    }
    return self;
}

- (instancetype)init {
    return [self initWithControl:nil savedPageList:[[[SessionSingleton sharedInstance] dataStore] savedPageList] url:nil];
}

#pragma mark - Accessors

- (void)setSavedPageList:(MWKSavedPageList *)savedPageList {
    if (self.savedPageList == savedPageList) {
        return;
    }
    _savedPageList = savedPageList;
    [self updateSavedButtonState];
}

- (void)setUrl:(NSURL *)url {
    if (WMF_EQUAL(self.url, isEqual:, url)) {
        return;
    }
    [self unobserveURL:_url];
    _url = [url copy];
    [self observeURL:_url];
    [self updateSavedButtonState];
}

- (void)setControl:(UIButton *)button {
    [_control removeTarget:self
                    action:@selector(toggleSave:)
          forControlEvents:UIControlEventTouchUpInside];

    [button addTarget:self
                  action:@selector(toggleSave:)
        forControlEvents:UIControlEventTouchUpInside];

    _control = button;
    [self updateSavedButtonState];
}

- (void)setBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [_barButtonItem setTarget:nil];
    [_barButtonItem setAction:nil];
    _barButtonItem = barButtonItem;
    _barButtonItem.image = [WMFSaveButtonController saveImage];
    [_barButtonItem setTarget:self];
    [_barButtonItem setAction:@selector(toggleSave:)];
    [self updateSavedButtonState];
}

- (SavedPagesFunnel *)savedPagesFunnel {
    if (!_savedPagesFunnel) {
        _savedPagesFunnel = [[SavedPagesFunnel alloc] init];
    }
    return _savedPagesFunnel;
}

#pragma mark - Notifications

- (void)observeURL:(NSURL *)url {
    if (!url) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdatedWithNotification:) name:WMFArticleUpdatedNotification object:nil];
}

- (void)unobserveURL:(NSURL *)url {
    if (!url) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)itemWasUpdatedWithNotification:(NSNotification *)note {
    WMFArticle *article = [note object];
    NSString *articleKey = article.key;
    NSString *myDatabaseKey = self.url.wmf_articleDatabaseKey;
    if (articleKey && myDatabaseKey && [articleKey isEqual:myDatabaseKey]) {
         [self updateSavedButtonState];
    }
}

#pragma mark - Save State

- (void)updateSavedButtonState {
    if (self.barButtonItem == nil && self.control == nil) {
        return;
    }
    if (self.savedPageList == nil) {
        return;
    }
    if (self.url == nil) {
        self.control.selected = NO;
        self.barButtonItem.image = [WMFSaveButtonController saveImage];
        return;
    }
    BOOL isSaved = [self isSaved];
    self.control.selected = isSaved;
    self.control.accessibilityLabel = isSaved ? WMFLocalizedStringWithDefaultValue(@"unsave-action", nil, nil, @"Unsave", @"Accessibility action description for 'Unsave'") : WMFLocalizedStringWithDefaultValue(@"save-action", nil, nil, @"Save", @"Accessibility action description for 'Save'\n{{Identical|Save}}");
    self.barButtonItem.accessibilityLabel = isSaved ? WMFLocalizedStringWithDefaultValue(@"unsave-action", nil, nil, @"Unsave", @"Accessibility action description for 'Unsave'") : WMFLocalizedStringWithDefaultValue(@"save-action", nil, nil, @"Save", @"Accessibility action description for 'Save'\n{{Identical|Save}}");
    if (isSaved) {
        self.barButtonItem.image = [WMFSaveButtonController unsaveImage];
    } else {
        self.barButtonItem.image = [WMFSaveButtonController saveImage];
    }
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.url];
}

- (void)toggleSave:(id)sender {
    BOOL isSaved = [self.savedPageList toggleSavedPageForURL:self.url];

    if (isSaved) {
        [self.savedPagesFunnel logSaveNew];
        [[PiwikTracker sharedInstance] wmf_logActionSaveInContext:self contentType:self];
    } else {
        [self.savedPagesFunnel logDelete];
        [[PiwikTracker sharedInstance] wmf_logActionUnsaveInContext:self contentType:self];
    }
}

@end
