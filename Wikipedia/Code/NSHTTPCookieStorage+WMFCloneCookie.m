#import <WMF/NSHTTPCookieStorage+WMFCloneCookie.h>
#import <WMF/WMF-Swift.h>

@implementation NSHTTPCookieStorage (WMFCloneCookie)

- (void)wmf_recreateCookie:(NSString *)cookieToRecreateName withDomain:(NSString *)domain usingCookieAsTemplate:(NSString *)templateCookieName templateDomain:(NSString *)templateDomain {
    void (^cloneCookie)(NSString *, NSString *) = ^void(NSString *cookieToRecreateName, NSString *templateCookieName) {
        NSUInteger indexCookie1 = [self getIndexOfCookieWithName:cookieToRecreateName domain:domain];
        NSUInteger indexCookie2 = [self getIndexOfCookieWithName:templateCookieName domain:templateDomain];

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
            if (domain) {
                cookie2Props[@"Domain"] = domain;
            }
            NSHTTPCookie *newCookie = [NSHTTPCookie cookieWithProperties:cookie2Props];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:newCookie];
        }
    };

    cloneCookie(cookieToRecreateName, templateCookieName);
}

- (NSUInteger)getIndexOfCookieWithName:(NSString *)name domain:(NSString *)domain {
    return [self.cookies indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSHTTPCookie *cookie = (NSHTTPCookie *)obj;
        if (cookie.properties[@"Name"] && cookie.properties[@"Domain"]) {
            if ([cookie.properties[@"Name"] isEqualToString:name] && [cookie.properties[@"Domain"] isEqualToString:domain]) {
                *stop = YES;
                return YES;
            }
        }
        return NO;
    }];
}

- (void)wmf_createCookieWithName:(NSString *)cookieToCreateName newDomain:(NSString *)newDomain usingCookieAsTemplate:(NSString *)templateCookieName templateDomain:(NSString *)templateDomain {
    void (^cloneCookie)(NSString *, NSString *) = ^void(NSString *cookieToCreateName, NSString *templateCookieName) {
        NSUInteger cookieToCreateIndex = [self getIndexOfCookieWithName:cookieToCreateName domain:newDomain];
        NSUInteger templateCookieIndex = [self getIndexOfCookieWithName:templateCookieName domain:templateDomain];

        if ((cookieToCreateIndex == NSNotFound) && (templateCookieIndex != NSNotFound)) {
            NSHTTPCookie *templateCookie = self.cookies[templateCookieIndex];

            NSMutableDictionary *newCookieProps = [templateCookie.properties mutableCopy];
            newCookieProps[@"Name"] = cookieToCreateName;
            newCookieProps[@"Domain"] = newDomain;
            newCookieProps[@"Created"] = [NSDate date];
            newCookieProps[@"Value"] = templateCookie.value;
            NSHTTPCookie *newCookie = [NSHTTPCookie cookieWithProperties:newCookieProps];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:newCookie];
        }
    };

    cloneCookie(cookieToCreateName, templateCookieName);
}

@end
