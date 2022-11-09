//
//  GDAJSONObject.h
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnullability-completeness"
#pragma GCC diagnostic ignored "-Wdocumentation"
#pragma GCC diagnostic ignored "-Wstrict-prototypes"

#import <Foundation/Foundation.h>

// GDAJSONObject interface.
@interface GDAJSONObject : NSObject

// Properties.
@property (nonatomic, readonly) BOOL isArray;
@property (nonatomic, readonly, nonnull) NSString * jsonString;

// Properties.
@property (nonnull, nonatomic, readonly) id object;

// Class initializer.
- (nullable instancetype)initWithData:(nonnull NSData *)data;

// Class initializer.
- (nullable instancetype)initWithObject:(nonnull id)object;

// Class initializer.
- (nullable instancetype)initWithString:(nonnull NSString *)string;

// Returns the array object at the specified path, or nil.
- (nullable NSArray *)arrayAtPath:(nonnull NSString *)path;

// Returns the string object at the specified path, or nil.
- (nullable NSString *)stringAtPath:(nonnull NSString *)path;

// Returns the number object at the specified path, or nil.
- (nullable NSNumber *)numberAtPath:(nonnull NSString *)path;

// Returns the GDAJSONObject at the specified path, or nil.
- (nullable instancetype)objectAtPath:(nonnull NSString *)path;

// Returns the first array element with the specified property name equal to the specified property value.
- (nullable instancetype)firstArrayElementWithPropertyName:(nonnull NSString *)propertyName
                                      equalToPropertyValue:(nonnull id)propertyValue;

@end

// NSObject (Extensions) interface.
@interface NSObject (Extensions)

// Converts a NSNull to a nil.
- (id)nilWhenNSNull;

@end

// NSString (Extensions) interface.
@interface NSString (Extensions)

// Returns YES if the NSString is an integer; otherwise; NO.
- (BOOL)isInteger;

@end

#pragma GCC diagnostic pop
