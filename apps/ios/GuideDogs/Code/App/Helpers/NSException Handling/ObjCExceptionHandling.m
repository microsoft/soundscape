//
//  ObjCExceptionHandling.m
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

#import "ObjCExceptionHandling.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **) error {
    @try {
        tryBlock();
        return YES;
    } @catch (NSException *exception) {
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        
        [info setValue:exception.name forKey:NSLocalizedDescriptionKey];
        [info setValue:exception.reason forKey:NSLocalizedFailureReasonErrorKey];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];

        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:info];
        
        return NO;
    }
}

@end
