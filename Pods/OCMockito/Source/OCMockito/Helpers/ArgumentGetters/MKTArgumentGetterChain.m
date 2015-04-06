//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTArgumentGetterChain.h"

#import "MKTObjectArgumentGetter.h"
#import "MKTSelectorArgumentGetter.h"
#import "MKTClassArgumentGetter.h"
#import "MKTCharArgumentGetter.h"
#import "MKTBoolArgumentGetter.h"
#import "MKTIntArgumentGetter.h"
#import "MKTShortArgumentGetter.h"
#import "MKTLongArgumentGetter.h"
#import "MKTLongLongArgumentGetter.h"
#import "MKTUnsignedCharArgumentGetter.h"
#import "MKTUnsignedIntArgumentGetter.h"
#import "MKTUnsignedShortArgumentGetter.h"
#import "MKTUnsignedLongArgumentGetter.h"
#import "MKTUnsignedLongLongArgumentGetter.h"
#import "MKTFloatArgumentGetter.h"
#import "MKTDoubleArgumentGetter.h"
#import "MKTPointerArgumentGetter.h"
#import "MKTStructArgumentGetter.h"


MKTArgumentGetter *MKTArgumentGetterChain(void)
{
    static MKTArgumentGetter *chain = nil;
    if (!chain)
    {
        MKTArgumentGetter *structGetter = [[MKTStructArgumentGetter alloc] initWithSuccessor:nil];
        MKTArgumentGetter *pointerGetter = [[MKTPointerArgumentGetter alloc] initWithSuccessor:structGetter];
        MKTArgumentGetter *doubleGetter = [[MKTDoubleArgumentGetter alloc] initWithSuccessor:pointerGetter];
        MKTArgumentGetter *floatGetter = [[MKTFloatArgumentGetter alloc] initWithSuccessor:doubleGetter];
        MKTArgumentGetter *uLongLongGetter = [[MKTUnsignedLongLongArgumentGetter alloc] initWithSuccessor:floatGetter];
        MKTArgumentGetter *uLongGetter = [[MKTUnsignedLongArgumentGetter alloc] initWithSuccessor:uLongLongGetter];
        MKTArgumentGetter *uShortGetter = [[MKTUnsignedShortArgumentGetter alloc] initWithSuccessor:uLongGetter];
        MKTArgumentGetter *uIntGetter = [[MKTUnsignedIntArgumentGetter alloc] initWithSuccessor:uShortGetter];
        MKTArgumentGetter *uCharGetter = [[MKTUnsignedCharArgumentGetter alloc] initWithSuccessor:uIntGetter];
        MKTArgumentGetter *longLongGetter = [[MKTLongLongArgumentGetter alloc] initWithSuccessor:uCharGetter];
        MKTArgumentGetter *longGetter = [[MKTLongArgumentGetter alloc] initWithSuccessor:longLongGetter];
        MKTArgumentGetter *shortGetter = [[MKTShortArgumentGetter alloc] initWithSuccessor:longGetter];
        MKTArgumentGetter *intGetter = [[MKTIntArgumentGetter alloc] initWithSuccessor:shortGetter];
        MKTArgumentGetter *boolGetter = [[MKTBoolArgumentGetter alloc] initWithSuccessor:intGetter];
        MKTArgumentGetter *charGetter = [[MKTCharArgumentGetter alloc] initWithSuccessor:boolGetter];
        MKTArgumentGetter *classGetter = [[MKTClassArgumentGetter alloc] initWithSuccessor:charGetter];
        MKTArgumentGetter *selectorGetter = [[MKTSelectorArgumentGetter alloc] initWithSuccessor:classGetter];
        MKTArgumentGetter *objectGetter = [[MKTObjectArgumentGetter alloc] initWithSuccessor:selectorGetter];
        chain = objectGetter;
    }
    return chain;
}
