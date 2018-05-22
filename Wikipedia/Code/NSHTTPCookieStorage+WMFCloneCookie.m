#import <WMF/NSHTTPCookieStorage+WMFCloneCookie.h>
#import <WMF/WMF-Swift.h>

@implementation NSHTTPCookieStorage (WMFCloneCookie)

- (void)wmf_recreateCookie:(NSString *)cookieToRecreate usingCookieAsTemplate:(NSString *)templateCookie {
    void (^cloneCookie)(NSString *, NSString *) = ^void(NSString *name1, NSString *name2) {
        NSUInteger (^getIndexOfCookie)(NSString *) = ^NSUInteger(NSString *name) {
            return [self.cookies indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                NSHTTPCookie *cookie = (NSHTTPCookie *)obj;
                if (cookie.properties[@"Name"]) {
                    if ([cookie.properties[@"Name"] isEqualToString:name]) {
                        *stop = YES;
                        return YES;
                    }
                }
                return NO;
            }];
        };

        NSUInteger indexCookie1 = getIndexOfCookie(name1);
        NSUInteger indexCookie2 = getIndexOfCookie(name2);

        if ((indexCookie1 != NSNotFound) && (indexCookie2 != NSNotFound)) {
            NSHTTPCookie *cookie1 = self.cookies[indexCookie1];
            NSHTTPCookie *cookie2 = self.cookies[indexCookie2];
            NSString *cookie1Name = cookie1.name;
            NSString *cookie1Value = cookie1.value;

            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie1];

            NSMutableDictionary *cookie2Props = [cookie2.properties mutableCopy];
            cookie2Props[@"Created"] = [NSDate date];
            cookie2Props[@"Name"] = cookie1Name;
            cookie2Props[@"Value"] = cookie1Value;
            NSHTTPCookie *newCookie = [NSHTTPCookie cookieWithProperties:cookie2Props];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:newCookie];
        }
    };

    cloneCookie(cookieToRecreate, templateCookie);
}

@end
