//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WKWebView+LoadAssetsHtml.h"
#import "Wikipedia-Swift.h"

@implementation WKWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment {
    [self loadFileURLFromPath:[[self getAssetsPath] stringByAppendingPathComponent:fileName] scrolledToFragment:fragment];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment topPadding:(NSUInteger)topPadding {
    if (!string) {
        string = @"";
    }

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
        [self loadFileURLFromPath:tempFilePath scrolledToFragment:fragment];
    } else {
        NSAssert(NO, @"\nTemp file could not be written: \n%@\n", tempFilePath);
    }
}

- (void)loadFileURLFromPath:(NSString*)filePath scrolledToFragment:(NSString*)fragment {
    // TODO: add iOS 8 fallback here...

    if (!fragment) {
        fragment = @"";
    }

    NSAssert([fragment rangeOfString:@" "].location == NSNotFound, @"Fragment cannot contain spaces before it is passed to 'fileURLWithPath:'!");
    fragment = [fragment stringByReplacingOccurrencesOfString:@" " withString:@"_"];

    // Attach hash fragment to file url. http://stackoverflow.com/a/7218674/135557
    // This, in combination with "loadFileURL:", will cause the web view to load
    // automatically scrolled to "fragment" section.
    NSURL* fileUrlWithHashFragment =
        [NSURL URLWithString:[[[NSURL fileURLWithPath:filePath].absoluteString stringByAppendingString:@"#"] stringByAppendingString:fragment]];

    [self loadFileURL:fileUrlWithHashFragment allowingReadAccessToURL:[fileUrlWithHashFragment URLByDeletingLastPathComponent]];
}

- (NSString*)getAssetsPath {
    NSArray* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

@end