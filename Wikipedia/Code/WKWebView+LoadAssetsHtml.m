//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WKWebView+LoadAssetsHtml.h"
#import "Wikipedia-Swift.h"
#import "NSString+WMFImageProxy.h"

@implementation WKWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment {
    if (!fileName) {
        DDLogError(@"attempted to load nil file");
        return;
    }
    NSURLComponents* components = [[NSURLComponents alloc] init];
    components.host     = @"localhost";
    components.port     = @(8080);
    components.scheme   = @"http";
    components.path     = [NSString pathWithComponents:@[@"/", fileName]];
    
    // If no fragment use "top" of document fragment keyword to fix bug sometimes causing new
    // page to load not scrolled to top. This keyword is specified by HTML5 according to:
    // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a#attr-href
    components.fragment = fragment ? fragment : @"top";

    NSURLRequest* request = [NSURLRequest requestWithURL:components.URL];
    [self loadRequest:request];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment topPadding:(NSUInteger)topPadding {
    if (!string) {
        string = @"";
    }

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* path = [[self getAssetsPath] stringByAppendingPathComponent:fileName];

    NSString* fileContents = [NSMutableString stringWithContentsOfFile:path
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];

    NSNumber* fontSize   = [[NSUserDefaults standardUserDefaults] wmf_readingFontSize];
    NSString* fontString = [NSString stringWithFormat:@"%ld%%", fontSize.integerValue];

    NSAssert([fileContents componentsSeparatedByString:@"%@"].count == (3 + 1), @"\nHTML template file does not have required number of percent-ampersand occurences (3).\nNumber of percent-ampersands must match number of values passed to  'stringWithFormat:'");

    // index.html and preview.html have three "%@" subsitition markers. Replace both of these with actual content.
    NSString* templateAndContent = [NSString stringWithFormat:fileContents, fontString, @(topPadding), string];

    // Get temp file name. For a fileName of "index.html" the temp file name would be "index.temp.html"
    NSString* tempFileName = [[[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"temp"] stringByAppendingPathExtension:[fileName pathExtension]];

    // Get path to tempFileName
    NSString* tempFilePath = [[[NSURL fileURLWithPath:path] URLByDeletingLastPathComponent] URLByAppendingPathComponent:tempFileName isDirectory:NO].absoluteString;

    // Remove "file://" from beginning of tempFilePath
    tempFilePath = [tempFilePath substringFromIndex:7];

    NSError* error = nil;
    [templateAndContent writeToFile:tempFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        [self loadHTMLFromAssetsFile:tempFileName scrolledToFragment:fragment];
    } else {
        NSAssert(NO, @"\nTemp file could not be written: \n%@\n", tempFilePath);
    }
}



- (NSString*)getAssetsPath {
    NSArray* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

@end