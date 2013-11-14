//  Created by Monte Hurd on 10/26/13.

#import "MWNetworkOp.h"

@interface MWNetworkOp()

#pragma mark - Private properties

@property (nonatomic, assign, getter = isOperationStarted) BOOL operationStarted;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLResponse *response;
@property (copy, readwrite) NSNumber *bytesWritten;
@property (copy, readwrite) NSNumber *bytesExpectedToWrite;

@end

@implementation MWNetworkOp
{
    // In concurrent operations, we have to manage the operation's state
    BOOL executing_;
    BOOL finished_;
    BOOL runLoopRunningIndefinitely_;
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

    NSLog(@"NETWORK OP INIT'ED: TAG = %d, POINTER = %p", self.tag, self);

    if (self) {
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
        runLoopRunningIndefinitely_ = NO;
    }
    return self;
}

-(void)dealloc
{
    if (self.aboutToDealloc != nil) self.aboutToDealloc();

    // Easy check to see if this operation is cleaned up when its work is done
    NSLog(@"NETWORK OP DEALLOC'ED: TAG = %d, POINTER = %p", self.tag, self);    
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
    if(finished_ || [self isCancelled]) {
		[self finishWithError:@"Start method aborted early because op was marked finished or cancelled."];
		return;
	}

    // Don't start if *any* parent op failed or had an error.
    // "Dependent" for MWNetworkOp means dependent on its success!
    // This is so failures cascade automatically.
    for (id obj in self.dependencies) {
        if ([obj isMemberOfClass:[NSOperation class]]){
            NSOperation *op = (NSOperation *)obj;
            if ([op isCancelled]) {
                [self finishWithError:@"Start method aborted early because parent NSOperation had been cancelled."];
                return;
            }
        }else if ([obj isMemberOfClass:[MWNetworkOp class]]){
            MWNetworkOp *op = (MWNetworkOp *)obj;
            if (op.error || [op isCancelled]) {
                [self finishWithError:@"Start method aborted early because parent MWNetworkOp had been cancelled or had an error."];
                return;
            }
        }
    }

    if (self.aboutToStart != nil) self.aboutToStart();
    
    if (self.request == nil) {
        [self finish];
        return;
    }

    @autoreleasepool {

        //NSLog(@"STARTED: TAG = %d", self.tag);
        [self setOperationStarted:YES];  // See: http://stackoverflow.com/a/8152855/135557

        NSLog(@"NETWORK OP STARTED: TAG = %d, POINTER = %p", self.tag, self);

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

        CFRunLoopRun(); // Avoid thread exiting
        runLoopRunningIndefinitely_ = YES;
    }
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
    self.response = response;
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
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.bytesWritten = [NSNumber numberWithInteger:totalBytesWritten];
    self.bytesExpectedToWrite = [NSNumber numberWithInteger:totalBytesExpectedToWrite];
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
    // This needs to happen whether the operation started or not. Any dependencies retained
    // by this op can prevent this op from being dealloc'ed!
    for (id op in [self.dependencies copy]) {
        [self removeDependency:op];
    }
    self.request = nil;
    self.aboutToStart = nil;
    self.response = nil;

    //if (![self isOperationStarted]) return;

    NSLog(@"NETWORK OP FINISHED: TAG = %d, POINTER = %p, ERROR = %@", self.tag, self, self.error);

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
    if(self.completionBlock && self.isExecuting) self.completionBlock();
    self.completionBlock = nil;

	// Alert anyone that we are finished
	[self willChangeValueForKey:@"isExecuting"];
	executing_ = NO;
	[self didChangeValueForKey:@"isExecuting"];

	[self willChangeValueForKey:@"isFinished"];
	finished_  = YES;
	[self didChangeValueForKey:@"isFinished"];

    // Added extra runLoopSetToIndefinite_ check to ensure run loop is only stopped
    // if CFRunLoopRun() was actually called.
    if (runLoopRunningIndefinitely_) {
        // Now safe for the thread to exit - needed because of the @autoreleasepool
        // See: http://stackoverflow.com/a/1730053/135557 for more info
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

-(void)finishWithError:(NSString *)description
{
	// Code for being cancelled    
    self.error = [[NSError alloc] initWithDomain : @"MWNetworkOp.m"
                                            code : 555
                                        userInfo : @{
                                                   NSLocalizedDescriptionKey: NSLocalizedString([@"MWNetworkOp Error: " stringByAppendingString:description], nil)
                                                   }];
	[self finish];
}

@end
