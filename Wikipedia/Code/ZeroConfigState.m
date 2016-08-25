#import "ZeroConfigState.h"
//#import <Tweaks/FBTweakInline.h>

#import "WMFZeroMessage.h"
#import "WMFZeroMessageFetcher.h"
#import "MWKLanguageLinkController.h"

@import WMFKit;

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFZeroDispositionDidChange = @"WMFZeroDispositionDidChange";

NSString *const ZeroOnDialogShownOnce = @"ZeroOnDialogShownOnce";
NSString *const ZeroWarnWhenLeaving = @"ZeroWarnWhenLeaving";

@interface ZeroConfigState ()

@property (nonatomic, strong, readonly) WMFZeroMessageFetcher *zeroMessageFetcher;
@property (nonatomic, strong, nullable, readwrite) WMFZeroMessage *zeroMessage;

@end

@implementation ZeroConfigState
@synthesize disposition = _disposition;
@synthesize zeroMessageFetcher = _zeroMessageFetcher;

+ (void)load {
    [super load];
    //    FBTweakAction(@"Networking", @"Wikipedia Zero", @"Reset ZeroOnDialogShownOnce", ^{
    //        [[NSUserDefaults wmf_userDefaults] setBool:NO forKey:ZeroOnDialogShownOnce];
    //        [[NSUserDefaults wmf_userDefaults] synchronize];
    //    });
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

- (void)setWarnWhenLeaving:(BOOL)warnWhenLeaving {
    [[NSUserDefaults wmf_userDefaults] setObject:[NSNumber numberWithBool:warnWhenLeaving]
                                          forKey:ZeroWarnWhenLeaving];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (BOOL)warnWhenLeaving {
    return [[NSUserDefaults wmf_userDefaults] boolForKey:ZeroWarnWhenLeaving];
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
            });
        } else {
            self.zeroMessage = nil;
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

@end

NS_ASSUME_NONNULL_END
