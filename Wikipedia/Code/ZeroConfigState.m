#import "ZeroConfigState.h"
//#import <Tweaks/FBTweakInline.h>

#import "WMFZeroMessage.h"
#import "WMFZeroMessageFetcher.h"
#import "MWKLanguageLinkController.h"
#import <WMFModel/WMFModel-Swift.h>

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
        BOOL previousDisposition = _disposition;
        _disposition = disposition;
        [self postNotificationIfDispositionHasChangedFromPreviousDisposition:previousDisposition];
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

/**
 *   This method does a few things:
 *
 * - Posts WMFZeroDispositionDidChange notification if the disposition has changed.
 *
 * - Fetches and sets self.zeroMessage to a WMFZeroMessage object containing carrier
 *   specific strings.
 *
 * - If the fetched zeroMessage has a nil "message" string, this means even though
 *   there was a header leading us to believe this network was Zero rated, it is
 *   not presently enabled. (It would be nice if the query fetching the zeroMessage
 *   returned an "enabled" key/value, but it doesn't - it nils out the values instead
 *   apparently.) So if we detect a nil message we need to flip the disposition back
 *   to "NO".
 */
- (void)postNotificationIfDispositionHasChangedFromPreviousDisposition:(BOOL)previousDisposition {
    
    // Note: don't nil out self.zeroMessage in this method
    // because if we do we can't show its exit message strings!

    BOOL const didEnter = _disposition;
    dispatch_async(dispatch_get_main_queue(), ^{
        @weakify(self);
        AnyPromise *promise = [AnyPromise promiseWithValue:nil];
        if (didEnter) {
            promise = [self fetchZeroMessage].then(^(WMFZeroMessage *zeroMessage) {
                @strongify(self);
                
                // If the config is not enabled its "message" will be nil, so if we detect a nil message
                // set the disposition to NO before we post the WMFZeroDispositionDidChange notification.
                if(zeroMessage.message == nil){
                    @synchronized(self) {
                        self->_disposition = NO;
                    }
                    // Reminder: don't nil out self.zeroMessage here or the carrier's exit message won't be available.
                }else{
                    self.zeroMessage = zeroMessage;
                }
                
            }).catch(^(NSError* error){
                @strongify(self);
                @synchronized(self) {
                    self->_disposition = NO;
                }
            });
        }

        promise.then(^{
            @strongify(self);

            if(self.disposition != previousDisposition){
                [[NSNotificationCenter defaultCenter] postNotificationName:WMFZeroDispositionDidChange object:self];
            }
            
        });
    });
}

- (AnyPromise *)fetchZeroMessage {
    [self.zeroMessageFetcher cancelAllFetches];
    return [self.zeroMessageFetcher fetchZeroMessageForSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL]];
}

@end

NS_ASSUME_NONNULL_END
