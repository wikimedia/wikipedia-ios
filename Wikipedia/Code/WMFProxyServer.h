#import <Foundation/Foundation.h>

@interface WMFProxyServer : NSObject

+ (WMFProxyServer*)sharedProxyServer;

- (NSString*)localFilePathForRelativeFilePath:(NSString*)relativeFilePath;   //path for writing files to the file proxy's server

- (NSURL*)proxyURLForRelativeFilePath:(NSString*)relativeFilePath fragment:(NSString*)fragment;    //returns the proxy url for a given relative path

- (NSString*)stringByReplacingImageURLsWithProxyURLsInHTMLString:(NSString*)HTMLstring;   //replaces image URLs in an HTML string with URLs that will be routed through this proxy

@end
