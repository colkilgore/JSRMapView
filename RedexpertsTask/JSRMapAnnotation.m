//
//  JSRMapAnnotation.m
//  RedexpertsTask
//
//  Created by Jan Skommer on 10.01.2014.
//  Copyright (c) 2014 Jan Skommer. All rights reserved.

#import "JSRMapAnnotation.h"

// Stale opisujace nazwy klucza | Constants for key name
NSString *const kAnnotationLocation    = @"location";
NSString *const kAnnotationLongitude   = @"longitude";
NSString *const kAnnotationLatitude    = @"latitude";
NSString *const kAnnotationImage       = @"image";
NSString *const kAnnotationText        = @"text";

@interface JSRMapAnnotation ()
// Slownik z pobrana informacja z ktorego wyciagamy potrzebne dane
@property NSDictionary *jsonObject;
@end

@implementation JSRMapAnnotation


+ (JSRMapAnnotation*)annotationForJSONObject:(NSDictionary*)jsonObject
{
    JSRMapAnnotation *newAnnotation = [JSRMapAnnotation new];
    if (jsonObject) {
        [newAnnotation setJsonObject:jsonObject];
        return newAnnotation;
    } else {
        // Jezeli przekazany obiekt jest pusty, zwracamy nil
        return nil;
    }
}


- (NSURL*)imageURL
{
    return [NSURL URLWithString:[self.jsonObject valueForKey:kAnnotationImage]];
}

#pragma mark - MKAnnotation Protocol;

- (NSString*)title
{
    return [self.jsonObject valueForKey:kAnnotationText];
}

- (CLLocationCoordinate2D)coordinate
{
    // Wyciagamy slownik z informacja o polozeniu
    NSDictionary *location = [self.jsonObject valueForKey:kAnnotationLocation];
    
    // Zwracamy polozenie
    CLLocationDegrees latitude = [[location valueForKey:kAnnotationLatitude] doubleValue];
    CLLocationDegrees longitude = [[location valueForKey:kAnnotationLongitude] doubleValue];
    return CLLocationCoordinate2DMake(latitude, longitude);
}

@end
