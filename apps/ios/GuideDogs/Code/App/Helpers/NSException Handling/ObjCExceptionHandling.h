//
//  ObjCExceptionHandling.h
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

#ifndef ObjCExceptionHandling_h
#define ObjCExceptionHandling_h

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **) error;

@end

#endif /* ObjCExceptionHandling_h */
