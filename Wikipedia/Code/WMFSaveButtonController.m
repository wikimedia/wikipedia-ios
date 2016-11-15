#import "WMFSaveButtonController.h"
#import "MWKSavedPageList.h"
#import "MWKDataStore.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "SavedPagesFunnel.h"
#import "PiwikTracker+WMFExtensions.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

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
    return [self initWithControl:nil savedPageList:[[[WMFDatabaseStack sharedInstance] userStore] savedPageList] url:nil];
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
    if ([note.userInfo[MWKURLKey] isEqual:self.url]) {
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
    self.control.accessibilityLabel = isSaved ? MWLocalizedString(@"unsave-action", nil) : MWLocalizedString(@"save-action", nil);
    self.barButtonItem.accessibilityLabel = isSaved ? MWLocalizedString(@"unsave-action", nil) : MWLocalizedString(@"save-action", nil);
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
        [[PiwikTracker sharedInstance] wmf_logActionUnsaveInContext:self contentType:self];
    } else {
        [self.savedPagesFunnel logSaveNew];
        [[PiwikTracker sharedInstance] wmf_logActionSaveInContext:self contentType:self];
    }

    [self.savedPageList toggleSavedPageForURL:self.url];
}

@end
