//  Created by Monte Hurd on 12/10/13.

#import "URLCache.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "NSString+Extras.h"

@interface URLCache (){
    ArticleDataContextSingleton *articleDataContext_;
}

//@property (strong, nonatomic) NSData *debuggingPlaceHolderImageData;

@end

@implementation URLCache

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path];
    if (self) {
        articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        //self.debuggingPlaceHolderImageData = UIImagePNGRepresentation([UIImage imageNamed:@"w@2x.png"]);
    }
    return self;
}

-(BOOL)isMIMETypeRerouted:(NSString *)type
{
    if  ([type isEqualToString:@"image/jpeg"]) return YES;
    if  ([type isEqualToString:@"image/png"]) return YES;
    if  ([type isEqualToString:@"image/gif"]) return YES;
    return NO;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
    __block BOOL interceptedStore = NO;

    [articleDataContext_.workerContext performBlockAndWait:^(){
        //NSLog(@"[NSThread isMainThread] = %d", [NSThread isMainThread]);

        //NSLog(@"cachedResponse.response.MIMEType = %@", cachedResponse.response.MIMEType);
        
        if([self isMIMETypeRerouted:cachedResponse.response.MIMEType]){
            interceptedStore = YES;
            // Save image to articleData store instead of default NSURLCache store.
            NSURL *url = cachedResponse.response.URL;
            NSString *urlStr = [url absoluteString];
            
            // Strip "http:" or "https:"
            urlStr = [urlStr getUrlWithoutScheme];
            
            NSData *imageDataToUse = cachedResponse.data;
            
            NSArray *images = [articleDataContext_.workerContext getEntitiesForName: @"Image" withPredicateFormat:@"sourceUrl == %@", urlStr];
            
            Image *image = (images) ? (Image *)images[0] : nil;
            
            if (!image) {
                image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:articleDataContext_.workerContext];
                
                /*
                 // Quick debugging filter which makes image blue before saving them to our articleData store.
                 // (locks up occasionally - probably not thread safe - only for testing so no worry for now)
                 CIImage *inputImage = [[CIImage alloc] initWithData:cachedResponse.data];
                 
                 CIFilter *colorMonochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
                 [colorMonochrome setDefaults];
                 [colorMonochrome setValue: inputImage forKey: @"inputImage"];
                 [colorMonochrome setValue: [CIColor colorWithRed:0.6f green:0.6f blue:1.0f alpha:1.0f] forKey: @"inputColor"];
                 
                 CIImage *outputImage = [colorMonochrome valueForKey:@"outputImage"];
                 CIContext *context = [CIContext contextWithOptions:nil];
                 UIImage *outputUIImage = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
                 imageDataToUse = UIImagePNGRepresentation(outputUIImage);
                */
                
                // Another quick debugging indicator which caches a "W" logo image instead of the real image.
                // (This one has no thread safety issues.)
                //imageDataToUse = self.debuggingPlaceHolderImageData;
                
            }
            
            image.data = imageDataToUse;
            image.fileName = [url lastPathComponent];
            image.extension = [url pathExtension];
            image.imageDescription = nil;
            image.sourceUrl = urlStr;
            image.dateRetrieved = [NSDate date];
            image.dateLastAccessed = [NSDate date];
            UIImage *img = [UIImage imageWithData:imageDataToUse];
            image.width = @(img.size.width);
            image.height = @(img.size.height);
            image.mimeType = cachedResponse.response.MIMEType;
            
            NSError *error = nil;
            [articleDataContext_.workerContext save:&error];
            if (error) {
                NSLog(@"Error re-routing image to articleData store: %@", error);
            }
        }
        
        //NSString *responseData = [[NSString alloc] initWithData:cachedResponse.data encoding:NSUTF8StringEncoding];
        //NSLog(@"caching request: \nrequest = %@\ncachedResponse.data.length = %d\nmime type = %@", request, cachedResponse.data.length, cachedResponse.response.MIMEType);
    }];
    
    if (!interceptedStore) {
        [super storeCachedResponse:cachedResponse forRequest:request];
    }
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    /*
    NSData *imgData = UIImagePNGRepresentation([UIImage imageNamed:@"w@2x.png"]);
    NSURLResponse *r = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"image/jpeg" expectedContentLength:imgData.length textEncodingName:nil];
    NSCachedURLResponse *d = [[NSCachedURLResponse alloc] initWithResponse:r data:imgData];
    return d;
    */

    //NSLog(@"Default Cache.db usage:\n\tcurrentDiskUsage: %lu\n\tdiskCapacity = %lu\n\tcurrentMemoryUsage = %lu\n\tmemoryCapacity = %lu", (unsigned long)self.currentDiskUsage, (unsigned long)self.diskCapacity, (unsigned long)self.currentMemoryUsage, (unsigned long)self.memoryCapacity);

    __block NSCachedURLResponse *cachedResponse = nil;
    [articleDataContext_.workerContext performBlockAndWait:^(){
        //NSLog(@"[NSThread isMainThread] = %d", [NSThread isMainThread]);
        NSString *imageURL = request.URL.absoluteString;

        // Strip "http:" or "https:"
        imageURL = [imageURL getUrlWithoutScheme];

        NSArray *dbImages = [articleDataContext_.workerContext getEntitiesForName: @"Image" withPredicateFormat:@"sourceUrl == %@", imageURL];

        Image *imageFromDB = (dbImages) ? (Image *)dbImages[0] : nil;

        // If a core data Image was found, but its data length is zero, the Image record was probably
        // created when the section html was parsed to create sectionImage records, in which case
        // a request needs to actually be made, so set cachedResponse to nil so this happens.
        // NSLog(@"imageFromDB.data = %@", imageFromDB.data);
        if (imageFromDB && (imageFromDB.data.length == 0)) {
            cachedResponse = nil;
            return;
        }

        if (imageFromDB && [self isMIMETypeRerouted:imageFromDB.mimeType]) {
            //NSLog(@"CACHED IMAGE FOUND!!!!!! request.URL = %@", imageURL);
            NSData *imgData = imageFromDB.data;
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:imageFromDB.mimeType expectedContentLength:imgData.length textEncodingName:nil];
            cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:imgData];
            
            imageFromDB.dateLastAccessed = [NSDate date];
            
            NSError *error = nil;
            [articleDataContext_.workerContext save:&error];
            if (error) {
                NSLog(@"Error updating image dateLastAccessed in articleData store: %@", error);
            }
        }
    }];

    if (cachedResponse) return cachedResponse;

    //NSLog(@"CACHED IMAGE NOT FOUND!!!!! request.URL = %@", imageURL);
    return [super cachedResponseForRequest:request];
}

@end
