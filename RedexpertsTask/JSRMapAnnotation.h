//
//  JSRMapAnnotation.h
//  RedexpertsTask
//
//  Created by Jan Skommer on 10.01.2014.
//  Copyright (c) 2014 Jan Skommer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface JSRMapAnnotation : NSObject <MKAnnotation>

// Adres URL do obrazka ktory ma sie wyswietlic po tapnieciu
@property (readonly, strong) NSURL *imageURL;

// Zwraca obiekt konformujacy do protokolu MKAnnotation na podstawie przekazanego obiektu JSON
+ (JSRMapAnnotation*)annotationForJSONObject:(NSDictionary*)jsonObject;

@end
