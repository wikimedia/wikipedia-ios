//  Created by Monte Hurd on 10/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@class MWNetworkOp;

@protocol NetworkOpDelegate <NSObject>
    @optional
        -(void)opStarted:(MWNetworkOp *)op;
        -(void)opFinished:(MWNetworkOp *)op;
        -(void)opProgressed:(MWNetworkOp *)op;
@end

@interface MWNetworkOp : NSOperation <NSURLConnectionDataDelegate>

/*
"aboutToStart" provides a nice bookend to the built-in NSOperation "completionBlock".
It allows dependent operations to incorporate some data produced by the operations on
which they depend (whose operation will be complete by the time aboutToStart is
invoked because of the dependency) *before* they start. Nice as it allows chained ops
to basically relay info to ops further down the dependency chain without requiring a
delegate or controller to marshal inter-op communications (although nothing about
"aboutToStart" prevents such an arrangement from being used).
*/
@property (copy, nonatomic) void(^aboutToStart)(void);

// For testing only. Try not to put things in this block which would cause this op to
// be retained.
@property (copy, nonatomic) void(^aboutToDealloc)(void);

// Do not use strong for delegate or the operation will not be released properly.
@property (weak) id <NetworkOpDelegate> delegate;

@property (copy) NSURLRequest *request;
@property (strong, nonatomic) NSURLResponse *response;

@property (copy, readonly) NSMutableData *dataRetrieved;
@property (nonatomic) NSUInteger dataRetrievedExpectedLength;

@property (copy, readonly) NSDictionary *jsonRetrieved;

@property (copy, readonly) NSNumber *bytesWritten;
@property (copy, readonly) NSNumber *bytesExpectedToWrite;

// Made the error readwrite so from within completionBlock it can be set conditionally
// to signify the operation didn't retrieve what was desired (checking retrieved json
// for example to see if login was a success for example). Child ops will then see
// their parent finished with an error so they won't even start. Because "copy" is used
// there should be no issue with unwanted retaining preventing the op from being
// dealloc'ed when it is finished.
@property (copy, readwrite) NSError *error;

@property (nonatomic) NSTimeInterval initializationTime;
@property (nonatomic) NSTimeInterval startedTime;
@property (nonatomic) NSTimeInterval finishedTime;

@property (nonatomic) NSUInteger tag;

// Dependency determines order of execution, but sometimes we want a child op to
// still execute even if its "parent" operation failed.
@property (nonatomic) BOOL cancelDependentOpsIfThisOpFails;

@end

