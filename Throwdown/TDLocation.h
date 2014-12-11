//
//  TDLocation.h
//  Throwdown
//
//  Created by Andrew C on 12/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TDLocation : NSObject <MKAnnotation>

@property (strong, nonatomic, readonly) NSNumber *locationId;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *address;
@property (strong, nonatomic, readonly) NSString *city;
@property (strong, nonatomic, readonly) NSString *state;
@property (strong, nonatomic, readonly) NSString *country;
@property (strong, nonatomic, readonly) NSString *cc;
@property (nonatomic, assign, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithDictionary:(NSDictionary *)dict;
- (MKMapItem *)mapItem;

@end
