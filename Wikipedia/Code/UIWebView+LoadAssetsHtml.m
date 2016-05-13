//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+LoadAssetsHtml.h"
#import "Wikipedia-Swift.h"

@implementation WKWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString*)fileName {
    [self loadFileURLFromPath:[[self getAssetsPath] stringByAppendingPathComponent:fileName]];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName {
    if (!string) {
        string = @"";
    }

    NSString* path = [[self getAssetsPath] stringByAppendingPathComponent:fileName];

    NSString* fileContents = [NSMutableString stringWithContentsOfFile:path
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];

    NSNumber* fontSize   = [[NSUserDefaults standardUserDefaults] wmf_readingFontSize];
    NSString* fontString = [NSString stringWithFormat:@"%ld%%", fontSize.integerValue];

    // index.html and preview.html have two "%@" subsitition markers. Replace both of these with actual content.
    NSString *templateAndContent = [NSString stringWithFormat:fileContents, fontString, string];
    
    // Get temp file name. For a fileName of "index.html" the temp file name would be "index.temp.html"
    NSString *tempFileName = [[[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"temp"] stringByAppendingPathExtension:[fileName pathExtension]];
    
    // Get path to tempFileName
    NSString *tempFilePath = [[[NSURL fileURLWithPath:path] URLByDeletingLastPathComponent] URLByAppendingPathComponent:tempFileName isDirectory:NO].absoluteString;
    
    // Remove "file://" from beginning of tempFilePath
    tempFilePath = [tempFilePath substringFromIndex:7];
    
    NSError* error = nil;
    [templateAndContent writeToFile:tempFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        [self loadFileURLFromPath:tempFilePath];
    }else{
        NSAssert(NO, @"\nTemp file could not be written: \n%@\n", tempFilePath);
    }
}

-(void)loadFileURLFromPath:(NSString*)filePath {
    //TODO: add iOS 8 fallback here...
    [self loadFileURL:[NSURL fileURLWithPath:filePath] allowingReadAccessToURL:[[NSURL fileURLWithPath:filePath] URLByDeletingLastPathComponent]];
}

- (NSString*)getAssetsPath {
    NSArray* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

@end
