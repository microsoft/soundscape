//
//  GDAJSONObject.m
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

#import "GDAJSONObject.h"

// GDAJSONObject (Internal) interface.
@interface GDAJSONObject (Internal)

// Returns the object of the specified class for the specified path, or nil.
- (nullable id)objectOfClass:(Class)class
                     forPath:(NSString *)path;

@end

// GDAJSONObject implementation.
@implementation GDAJSONObject
{
@private
}

- (NSString *)jsonString
{
    if (_object == nil) {
        return @"";
    }
    
    NSError * error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:_object
                                                        options:0
                                                          error:&error];
    
    if (error || !jsonData) {
        if (_isArray) {
            return @"[]";
        }
        
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

// Class initializer.
- (nullable instancetype)initWithData:(nonnull NSData *)data
{
    NSError * error;
    id jsonDeseralized = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&error];
    if (error)
    {
        return nil;
    }
    
    // Initialize superclass.
    self = [self initWithObject:jsonDeseralized];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

// Class initializer.
- (nullable instancetype)initWithObject:(id)object
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _object = object;
    _isArray = [_object isKindOfClass:[NSArray class]];
    
    // Done.
    return self;
}

- (nullable instancetype)initWithString:(nonnull NSString *)string
{
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    self = [self initWithData:data];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Done.
    return self;
}

// Returns the array at the specified path, or nil.
- (nullable NSArray *)arrayAtPath:(NSString *)path
{
    return [self objectOfClass:[NSArray class]
                       forPath:path];
}

// Returns the string object at the specified path, or nil.
- (nullable NSString *)stringAtPath:(NSString *)path
{
    return [self objectOfClass:[NSString class]
                       forPath:path];
}

// Returns the number object at the specified path, or nil.
- (nullable NSNumber *)numberAtPath:(NSString *)path
{
    return [self objectOfClass:[NSNumber class]
                       forPath:path];
}

// Returns the JSONObjectAtPath at the specified path, or nil.
- (nullable instancetype)objectAtPath:(NSString *)path
{
    NSDictionary * object = (NSDictionary *)[self objectOfClass:[NSDictionary class]
                                                        forPath:path];
    if (!object)
    {
        return nil;
    }
    else
    {
        return [[GDAJSONObject alloc] initWithObject:object];
    }
}

// Returns the first array element with the specified property name equal to the specified property value.
- (nullable instancetype)firstArrayElementWithPropertyName:(nonnull NSString *)propertyName
                                      equalToPropertyValue:(nonnull id)propertyValue
{
    // Only NSString values are supported at this time.
    if (![propertyValue isKindOfClass:[NSString class]])
    {
        return nil;
    }
    
    // If the object isn't an array, the operation is invalid, so return nil.
    if (![self isArray])
    {
        return nil;
    }
    
    // Enumerate the array.
    for (id arrayEntry in (NSArray *)_object)
    {
        // Process the array entry.
        if ([arrayEntry isKindOfClass:[NSDictionary class]])
        {
            // If the array entry has a property with the specified name, and it matches, process it.
            id arrayEntryPropertyValue = ((NSDictionary *)arrayEntry)[propertyName];
            if ([arrayEntryPropertyValue isKindOfClass:[NSString class]])
            {
                if ([propertyValue isKindOfClass:[NSString class]])
                {
                    if ([arrayEntryPropertyValue isEqualToString:propertyValue])
                    {
                        return [[GDAJSONObject alloc] initWithObject:arrayEntry];
                    }
                }
            }
        }
    }
    
    // Done.
    return nil;
}

@end

// GDAJSONObject (Internal) implementation.
@implementation GDAJSONObject (Internal)

// Returns the object of the specified class for the specified path, or nil.
- (nullable id)objectOfClass:(Class)class
                     forPath:(NSString *)path
{
    // If there is nothing in the path, then return nil.
    if (![path length])
    {
        return [_object isKindOfClass:class] ? _object : nil;
    }
    
    // Navigate the path.
    id object = _object;
    NSArray<NSString *> * pathSegments = [path componentsSeparatedByString:@"."];
    for (NSUInteger i = 0; object && i < [pathSegments count]; i++)
    {
        // Access the path segment.
        NSString * pathSegment = pathSegments[i];
        
        // If the path segment is an integer, process an array at the path segment. Otherwise,
        // process an object at the path segment.
        if ([pathSegment isInteger])
        {
            // Proceed with object at index if it exits, otherwise return nil.
            NSInteger pathIndex = [pathSegment integerValue];
            if (pathIndex < 0)
            {
                return nil;
            }
            if (path >= 0 && [object isKindOfClass:[NSArray class]])
            {
                NSArray * array = (NSArray *)object;
                if (pathIndex < [array count])
                {
                    object = array[pathIndex];
                }
                else
                {
                    return nil;
                }
            }
            else
            {
                return nil;
            }
        }
        else
        {
            object = [object isKindOfClass:[NSDictionary class]] ? object[pathSegment] : nil;
        }
        
        // Switch from NSNull to nil, if the object is NSNull.
        object = [object nilWhenNSNull];
    }
    
    // If we have an object, and it's of the right type, return it.
    if (object && [object isKindOfClass:class])
    {
        return object;
    }
    
    // We didn't find an object of the specified class at the specified path.
    return nil;
}

@end

// NSObject (Extensions) implementation.
@implementation NSObject (Extensions)

// Converts a NSNull to a nil.
- (id)nilWhenNSNull
{
    id me = self;
    if ([me isKindOfClass:[NSNull class]])
    {
        return nil;
    }
    else
    {
        return self;
    }
}

@end

// NSString (Extensions) implementation.
@implementation NSString (Extensions)

// Returns YES if the NSString is an integer; otherwise; NO.
- (BOOL)isInteger
{
    NSScanner* scan = [NSScanner scannerWithString:self];
    return [scan scanInt:NULL] && [scan isAtEnd];
}

@end
