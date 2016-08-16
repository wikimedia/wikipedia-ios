
#import "WMFArticleListTableViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFSearch.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "PiwikTracker+WMFExtensions.h"
#import "UIViewController+WMFHideKeyboard.h"

@interface WMFArticleListTableViewController ()<UIViewControllerPreviewingDelegate>

@property (nonatomic, weak) id<UIViewControllerPreviewing> previewingContext;

@end

@implementation WMFArticleListTableViewController

#pragma mark - UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.extendedLayoutIncludesOpaqueBars     = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;

    self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];

    self.tableView.backgroundColor    = [UIColor wmf_articleListBackgroundColor];
    self.tableView.separatorColor     = [UIColor wmf_lightGrayColor];
    self.tableView.estimatedRowHeight = 64.0;
    self.tableView.rowHeight          = UITableViewAutomaticDimension;

    //HACK: this is the only way to force the table view to hide separators when the table view is empty.
    //See: http://stackoverflow.com/a/5377805/48311
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self registerForPreviewingIfAvailable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSParameterAssert(self.dataStore);
    [self updateEmptyAndDeleteState];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection*)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForPreviewingIfAvailable];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:NULL];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:nil];
    [self wmf_hideKeyboard];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSURL* url = [self urlAtIndexPath:indexPath];
    if (self.delegate) {
        [self.delegate listViewController:self didSelectArticleURL:url];
        return;
    }
    [self wmf_pushArticleWithURL:url dataStore:self.dataStore animated:YES];
}

#pragma mark - Previewing

- (void)registerForPreviewingIfAvailable {
    [self wmf_ifForceTouchAvailable:^{
        [self unregisterPreviewing];
        self.previewingContext = [self registerForPreviewingWithDelegate:self
                                                              sourceView:self.tableView];
    } unavailable:^{
        [self unregisterPreviewing];
    }];
}

- (void)unregisterPreviewing {
    if (self.previewingContext) {
        [self unregisterForPreviewingWithContext:self.previewingContext];
        self.previewingContext = nil;
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

- (nullable UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                      viewControllerForLocation:(CGPoint)location {
    NSIndexPath* previewIndexPath = [self.tableView indexPathForRowAtPoint:location];
    if (!previewIndexPath) {
        return nil;
    }

    previewingContext.sourceRect = [self.tableView cellForRowAtIndexPath:previewIndexPath].frame;

    NSURL* url                                       = [self urlAtIndexPath:previewIndexPath];
    id<WMFAnalyticsContentTypeProviding> contentType = nil;
    if ([self conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
        contentType = (id<WMFAnalyticsContentTypeProviding>)self;
    }
    [[PiwikTracker wmf_configuredInstance] wmf_logActionPreviewInContext:self contentType:contentType];

    if (self.delegate) {
        return [self.delegate listViewController:self viewControllerForPreviewingArticleURL:url];
    } else {
        return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UINavigationController*)viewControllerToCommit {
    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:nil];
    if (self.delegate) {
        [self.delegate listViewController:self didCommitToPreviewedViewController:viewControllerToCommit];
    } else {
        [self wmf_pushArticleViewController:(WMFArticleViewController*)viewControllerToCommit animated:YES];
    }
}

#pragma mark - Delete Button

- (void)updateDeleteButton {
    if ([self showsDeleteAllButton]) {
        if (self.navigationItem.leftBarButtonItem == nil) {
            @weakify(self);
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:[self deleteButtonText] style:UIBarButtonItemStylePlain handler:^(id sender) {
                @strongify(self);
                UIAlertController* sheet = [UIAlertController alertControllerWithTitle:[self deleteAllConfirmationText] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                [sheet addAction:[UIAlertAction actionWithTitle:[self deleteText] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* _Nonnull action) {
                    [self deleteAll];
                    [self.tableView reloadData];
                }]];
                [sheet addAction:[UIAlertAction actionWithTitle:[self deleteCancelText] style:UIAlertActionStyleCancel handler:NULL]];
                sheet.popoverPresentationController.barButtonItem = sender;
                sheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                [self presentViewController:sheet animated:YES completion:NULL];
            }];
        }

        if ([self numberOfItems] > 0) {
            self.navigationItem.leftBarButtonItem.enabled = YES;
        } else {
            self.navigationItem.leftBarButtonItem.enabled = NO;
        }
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

#pragma mark - Empty State

- (void)updateEmptyState {
    if (self.view.superview == nil) {
        return;
    }

    if ([self numberOfItems] > 0) {
        [self wmf_hideEmptyView];
    } else {
        [self wmf_showEmptyViewOfType:[self emptyViewType]];
    }
}

#pragma mark - Subclasses

- (NSString*)analyticsContext {
    return @"Generic Article List";
}

- (WMFEmptyViewType)emptyViewType {
    return WMFEmptyViewTypeNone;
}

- (BOOL)showsDeleteAllButton {
    return NO;
}

- (NSString*)deleteButtonText {
    return nil;
}

- (NSString*)deleteAllConfirmationText {
    return nil;
}

- (NSString*)deleteText {
    return nil;
}

- (NSString*)deleteCancelText {
    return nil;
}

- (void)deleteAll {
}

- (NSInteger)numberOfItems {
    return 0;
}

- (NSURL*)urlAtIndexPath:(NSIndexPath*)indexPath {
    return nil;
}

- (void)updateEmptyAndDeleteState {
    [self updateDeleteButton];
    [self updateEmptyState];
}

@end
