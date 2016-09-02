#import "WikipediaUnitTests-Swift.h"
@import Nimble;

NS_ASSUME_NONNULL_BEGIN

static inline NMBObjCMatcher *postNotificationFromCenter(NSString *named,
                                                         id _Nullable object,
                                                         NSNotificationCenter *center) {
    return [NMBObjCMatcher postNotificationMatcherForName:named object:object fromCenter:center];
}

static inline NMBObjCMatcher *postNotification(NSString *named, id _Nullable object) {
    return postNotificationFromCenter(named, object, [NSNotificationCenter defaultCenter]);
}

NS_ASSUME_NONNULL_END
