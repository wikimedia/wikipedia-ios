#import "WMFSaveButtonController.h"
#import "MWKSavedPageList.h"
#import "MWKDataStore.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "MWKArticle.h"
#import "MWKDataStore+WMFDataSources.h"
#import "SavedPagesFunnel.h"
#import "PiwikTracker+WMFExtensions.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

@interface WMFSaveButtonController () <WMFDataSourceDelegate>

- (instancetype)initWithControl:(UIControl *)button
                  barButtonItem:(UIBarButtonItem *)barButtonItem
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@property(nonatomic, strong) SavedPagesFunnel *savedPagesFunnel;

@end

@implementation WMFSaveButtonController

- (instancetype)initWithControl:(UIControl *)button
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url {
    self = [self initWithControl:button barButtonItem:nil savedPageList:savedPageList url:url];
    return self;
}

- (instancetype)initWithBarButtonItem:(UIBarButtonItem *)barButtonItem
                        savedPageList:(MWKSavedPageList *)savedPageList
                                  url:(NSURL *)url {
    self = [self initWithControl:nil barButtonItem:barButtonItem savedPageList:savedPageList url:url];
    return self;
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
    _url = url;
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
    _barButtonItem.image = [UIImage imageNamed:@"save"];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdatedWithNotification:) name:MWKItemUpdatedNotification object:nil];
}

- (void)unobserveURL:(NSURL *)url {
    if (!url) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)itemWasUpdatedWithNotification:(NSNotification *)note {
    if ([note.object isEqual:[self.url absoluteString]]) {
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
        self.barButtonItem.image = [UIImage imageNamed:@"save"];
        return;
    }
    BOOL isSaved = [self isSaved];
    self.control.selected = isSaved;
    if (isSaved) {
        self.barButtonItem.image = [UIImage imageNamed:@"save-filled"];
    } else {
        self.barButtonItem.image = [UIImage imageNamed:@"save"];
    }
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.url];
}

- (void)toggleSave:(id)sender {
    BOOL isSaved = [self.savedPageList isSaved:self.url];

    if (isSaved) {
        [self.savedPagesFunnel logDelete];
        [[PiwikTracker wmf_configuredInstance] wmf_logActionUnsaveInContext:self.analyticsContext contentType:self.analyticsContentType];
    } else {
        [self.savedPagesFunnel logSaveNew];
        [[PiwikTracker wmf_configuredInstance] wmf_logActionSaveInContext:self.analyticsContext contentType:self.analyticsContentType];
    }

    [self.savedPageList toggleSavedPageForURL:self.url];
}

@end
