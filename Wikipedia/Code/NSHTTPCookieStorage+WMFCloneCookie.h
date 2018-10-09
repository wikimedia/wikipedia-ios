@import Foundation;

@interface NSHTTPCookieStorage (WMFCloneCookie)

// Pass it 2 cookie names. If they're both found, it will discard cookieToRecreate and
// recreate it using templateCookie as a template. All of templateCookie's properties
// will be used, except "Name", "Value" and "Created", which will come from the original
// cookieToRecreate.
- (void)wmf_recreateCookie:(NSString *)cookieToRecreate withDomain:(NSString *)domain usingCookieAsTemplate:(NSString *)templateCookie templateDomain:(NSString *)templateDomain;

- (void)wmf_createCookieWithName:(NSString *)cookieToCreateName newDomain:(NSString *)newDomain usingCookieAsTemplate:(NSString *)templateCookieName templateDomain:(NSString *)templateDomain;

@end
