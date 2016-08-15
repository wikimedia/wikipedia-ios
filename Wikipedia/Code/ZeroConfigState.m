#import "ZeroConfigState.h"
#import "Wikipedia-Swift.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <Tweaks/FBTweakInline.h>

#import "WMFZeroMessage.h"
#import "WMFZeroMessageFetcher.h"
#import "MWKLanguageLinkController.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFZeroDispositionDidChange = @"WMFZeroDispositionDidChange";

NSString *const ZeroOnDialogShownOnce = @"ZeroOnDialogShownOnce";
NSString *const ZeroWarnWhenLeaving = @"ZeroWarnWhenLeaving";

@interface ZeroConfigState ()

@property(nonatomic, strong, readonly) WMFZeroMessageFetcher *zeroMessageFetcher;
@property(nonatomic, strong, nullable, readwrite) WMFZeroMessage *zeroMessage;

@end

@implementation ZeroConfigState
@synthesize disposition = _disposition;
@synthesize zeroMessageFetcher = _zeroMessageFetcher;

+ (void)load {
  [super load];
  FBTweakAction(@"Networking", @"Wikipedia Zero", @"Reset ZeroOnDialogShownOnce", ^{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:ZeroOnDialogShownOnce];
    [[NSUserDefaults standardUserDefaults] synchronize];
  });
}

- (WMFZeroMessageFetcher *)zeroMessageFetcher {
  if (!_zeroMessageFetcher) {
    _zeroMessageFetcher = [[WMFZeroMessageFetcher alloc] init];
  }
  return _zeroMessageFetcher;
}

- (void)setDisposition:(BOOL)disposition {
  @synchronized(self) {
    if (_disposition == disposition) {
      return;
    }
    _disposition = disposition;
    [self postNotification];
  }
}

- (BOOL)disposition {
  BOOL disposition;
  @synchronized(self) {
    disposition = _disposition;
  }
  return disposition;
}

- (void)setZeroOnDialogShownOnce {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ZeroOnDialogShownOnce];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
  return [[NSUserDefaults standardUserDefaults] boolForKey:ZeroOnDialogShownOnce];
}

- (void)setWarnWhenLeaving:(BOOL)warnWhenLeaving {
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:warnWhenLeaving]
                                            forKey:ZeroWarnWhenLeaving];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)warnWhenLeaving {
  return [[NSUserDefaults standardUserDefaults] boolForKey:ZeroWarnWhenLeaving];
}

#pragma mark - Banner Updates

- (void)postNotification {
  BOOL const didEnter = _disposition;
  dispatch_async(dispatch_get_main_queue(), ^{
    @weakify(self);
    AnyPromise *promise = [AnyPromise promiseWithValue:nil];
    if (didEnter) {
      promise = [self fetchZeroMessage].then(^(WMFZeroMessage *zeroMessage) {
        @strongify(self);
        self.zeroMessage = zeroMessage;
        [self showFirstTimeZeroOnAlertIfNeeded];
      });
    } else {
      self.zeroMessage = nil;
      [self showZeroOffAlert];
    }

    promise.then(^{
      @strongify(self);
      [[NSNotificationCenter defaultCenter] postNotificationName:WMFZeroDispositionDidChange object:self];
    });
  });
}

- (AnyPromise *)fetchZeroMessage {
  [self.zeroMessageFetcher cancelAllFetches];
  WMF_TECH_DEBT_TODO(fall back to default zero warning on fetch error);
  return [self.zeroMessageFetcher fetchZeroMessageForSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL]];
}

#pragma mark - Prompts

- (void)showFirstTimeZeroOnAlertIfNeeded {
  if ([self zeroOnDialogShownOnce]) {
    return;
  }

  [self setZeroOnDialogShownOnce];

  UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:self.zeroMessage.message
                                                   message:MWLocalizedString(@"zero-learn-more", nil)
                                                  delegate:nil
                                         cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                                         otherButtonTitles:MWLocalizedString(@"zero-learn-more-learn-more", nil), nil];

  [dialog bk_setHandler:^{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:MWLocalizedString(@"zero-webpage-url", nil)]];
  }
       forButtonAtIndex:dialog.firstOtherButtonIndex];

  [dialog show];
}

- (void)showZeroOffAlert {
  UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"zero-charged-verbiage", nil)
                                                   message:MWLocalizedString(@"zero-charged-verbiage-extended", nil)
                                                  delegate:nil
                                         cancelButtonTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil)
                                         otherButtonTitles:nil];
  [dialog show];
}

@end

NS_ASSUME_NONNULL_END
