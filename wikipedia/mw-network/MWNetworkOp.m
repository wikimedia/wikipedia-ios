//  Created by Monte Hurd on 10/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"
#import "WikipediaAppUtils.h"

@interface MWNetworkOp()

#pragma mark - Private properties

@property (strong, nonatomic) NSURLConnection *connection;
@property (copy, readwrite) NSNumber *bytesWritten;
@property (copy, readwrite) NSNumber *bytesExpectedToWrite;

@end

@implementation MWNetworkOp
{
    // In concurrent operations, we have to manage the operation's state
    BOOL executing_;
    BOOL finished_;
}

#pragma mark - Init / dealloc

- (void)setDataRetrieved:(NSMutableData *)thisData {
    _dataRetrieved = thisData;
}

-(NSDictionary *)jsonRetrieved
{
    NSError *jsonError = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.dataRetrieved options:0 error:&jsonError];
    return jsonError ? @{} : jsonDict;
}

-(id)init
{
    self = [super init];

    //NSLog(@"NETWORK OP INIT'ED: TAG = %d, POINTER = %p", self.tag, self);

    if (self) {
        self.cancelIfDependentOpsFailed = YES;
        self.error = nil;
        self.connection = nil;
        self.response = nil;
        self.dataRetrieved = [[NSMutableData alloc] init];
        self.request = nil;
        self.finishedTime = 0;
        self.startedTime = 0;
        self.initializationTime = [NSDate timeIntervalSinceReferenceDate];
        _bytesWritten = nil;
        _bytesExpectedToWrite = nil;
        finished_ = NO;
        executing_ = NO;
        self.aboutToStart = nil;
        self.aboutToDealloc = nil;
        self.tag = NSUIntegerMax;
        self.dataRetrievedExpectedLength = 0;
    }
    return self;
}

-(void)dealloc
{
    if (self.aboutToDealloc != nil) self.aboutToDealloc();

    // Easy check to see if this operation is cleaned up when its work is done
    //NSLog(@"NETWORK OP DEALLOC'ED: TAG = %d, POINTER = %p", self.tag, self);
}

#pragma mark - Overrides required for concurrency

/*
    If you are creating a concurrent operation, you need to override the following methods at a minimum:
        start
        isConcurrent
        isExecuting
        isFinished
*/

-(void)start
{

    if (self.cancelIfDependentOpsFailed) {
        // Don't start if *any* parent op failed or had an error.
        // "Dependent" for MWNetworkOp means dependent on its success!
        // This is so failures cascade automatically.
        for (id obj in self.dependencies) {
            if ([obj isKindOfClass:[MWNetworkOp class]]){
                MWNetworkOp *op = (MWNetworkOp *)obj;
                if (op.error || [op isCancelled]) {
                    [self finishWithError:@"Start method aborted early because parent MWNetworkOp had been cancelled or had an error."];
                    return;
                }
            }
        }
    }

    if(finished_ || [self isCancelled]) {
		[self finishWithError:@"Start method aborted early because op was marked finished or cancelled."];
		return;
	}

    if (self.aboutToStart != nil) self.aboutToStart();
    
    if (self.request == nil) {
		[self finishWithError:@"Start method aborted early because request was nil."];
        return;
    }

    self.startedTime = [NSDate timeIntervalSinceReferenceDate];
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(opStarted:)]){
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(opStarted:) withObject:self waitUntilDone:NO];
    }
    // The autoreleasepool is needed to keep the thread from exiting before NSURLConnection finishes
    // See: http://stackoverflow.com/q/1728631/135557 for more info
    
    // From this point on, the operation is officially executing--remember, isExecuting
    // needs to be KVO compliant!
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    // Create the NSURLConnection. Could have done so in init, but delayed until now in case the
    // operation was never enqueued or was cancelled before starting
    
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    //NSLog(@"self.request.HTTPBody = %@", [NSString stringWithCString:[self.request.HTTPBody bytes] encoding:NSUTF8StringEncoding]);

    // Keep the thread from exiting before the NSURLConnection finishes.
    NSDate *distantFutureDate = [NSDate distantFuture];
    while(!self.isFinished){[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:distantFutureDate];}
}

-(BOOL)isExecuting
{
	return executing_;
}

-(BOOL)isFinished
{
	return finished_;
}

-(BOOL)isConcurrent
{
	return YES;
}

#pragma mark - Other overrides

-(void)cancel
{
    // Make it safe to call cancel more than once.
    if (self.isCancelled) return;
    
    // Ensures isCancelled is YES before finishWithError is called (in case any callbacks invoked in finishWithError
    // call cancel - the isCancelled check above would then prevent recursion)
    [super cancel];
    
    [self finishWithError:@"Cancel method was called."];
}

#pragma mark - NSURLConnectionDataDelegate methods

-(void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse *)response
{
    self.dataRetrievedExpectedLength = (NSUInteger)[response expectedContentLength];

    self.response = response;
}

-(void)setResponse:(NSURLResponse *)response
{
    _response = response;
    
    [self failIfBadHTTPStatusCode];
}

-(void)failIfBadHTTPStatusCode
{
    if (!self.response) return;
    
    // If the response is a server or client error finish with an error.
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.response;
    NSInteger code = httpResponse.statusCode;
    if ((code >= 400) && (code <= 499)) {
        [self finishWithError:[NSString stringWithFormat:@"Client error. HTTP Status Code %ld", (long)code]];
    }else if ((code >= 500) && (code <= 599)) {
        [self finishWithError:[NSString stringWithFormat:@"Server error. HTTP Status Code %ld", (long)code]];
    }
    //NSLog(@"responseStatusCode = %ld", (long)code);
    //NSLog(@"allHeaderFields = %@", httpResponse.allHeaderFields);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if([self isCancelled]) {
        [self finishWithError:@"connectionDidFinishLoading: method saw the op was cancelled."];
    }else{
        [self finish];
    }
}

-(void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    if([self isCancelled]) {
        [self finishWithError:@"connection:didReceiveData: method saw the op was cancelled."];
    }else{
        [self.dataRetrieved appendData: data];
        // Enable inspection of the progress of the data being received
        [self reportProgress];
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.bytesWritten = [NSNumber numberWithInteger:totalBytesWritten];
    self.bytesExpectedToWrite = [NSNumber numberWithInteger:totalBytesExpectedToWrite];
    // Enable inspection of the progress of the data being sent
    [self reportProgress];
}

#pragma mark - Progress

-(void)reportProgress
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(opProgressed:)]){
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(opProgressed:) withObject:self waitUntilDone:NO];
    }
}

#pragma mark - NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    [self finish];
}

#pragma mark - Finishers

-(void)finish
{
    //NSLog(@"NETWORK OP FINISHED: TAG = %d, POINTER = %p, ERROR = %@", self.tag, self, self.error);

    self.finishedTime = [NSDate timeIntervalSinceReferenceDate];

    if(self.connection) {
        [self.connection cancel];
        // Don't nil self.connection here - it needs to call its delegates to wrap things up
    }

    if ([(NSObject *)self.delegate respondsToSelector:@selector(opFinished:)]){
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(opFinished:) withObject:self waitUntilDone:NO];
    }

    // Ensure completionBlock reliably fires before child op's aboutToStart.
    // Normally an NSOperation setting its "finished" property to YES triggers its "completionBlock" to fire, but
    // the problem with this behavior is the same action triggers any dependent operations to start, and this is
    // a problem because the ops that start are started in async fashion just as the completionBlock is, and
    // sometimes the dependent op starts before completionBlock does! This is bad as it means completionBlock can't
    // be reliably used to influence dependent ops (in their "aboutToStart" block for example.) To get around this
    // manually fire completionBlock() before this op signals via KVO that it's finished, then nil out the completion
    // block so when the op tries to fire it in the normal fashion *after* it's marked finished nothing will happen.
    
    // Checking self.isExecuting ensures completionBlocks are not called for ops that never started. Can't complete
    // something if you never started it!
    BOOL actuallyStarted = self.isExecuting;
    if(self.completionBlock && actuallyStarted) self.completionBlock();
    self.completionBlock = nil;

	// Alert anyone that we are finished
	[self willChangeValueForKey:@"isExecuting"];
	executing_ = NO;
	[self didChangeValueForKey:@"isExecuting"];

    if (actuallyStarted) { // <-- This prevents iOS 6 "went isFinished=YES without being started by the queue it is in" bug
        [self willChangeValueForKey:@"isFinished"];
        finished_  = YES;
        [self didChangeValueForKey:@"isFinished"];
    }

}

-(void)finishWithError:(NSString *)description
{
	// Code for being cancelled    
    self.error = [[NSError alloc] initWithDomain : @"MWNetworkOp.m"
                                            code : 555
                                        userInfo : @{
                                                   NSLocalizedDescriptionKey: MWLocalizedString([@"MWNetworkOp Error: " stringByAppendingString:description], nil)
                                                   }];
	[self finish];
}

@end
