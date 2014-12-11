//
//  TDLocation.m
//  Throwdown
//
//  Created by Andrew C on 12/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLocation.h"
#import <AddressBook/AddressBook.h>

@implementation TDLocation

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _locationId     = [dict objectForKey:@"id"];
        _name           = [dict objectForKey:@"name"];
        _address        = [self nullcheck:[dict objectForKey:@"address"]];
        _city           = [self nullcheck:[dict objectForKey:@"city"]];
        _state          = [self nullcheck:[dict objectForKey:@"state"]];
        _country        = [self nullcheck:[dict objectForKey:@"country"]];
        _cc             = [self nullcheck:[dict objectForKey:@"cc"]];

        NSNumber *lat = [dict objectForKey:@"lat"];
        NSNumber *lon = [dict objectForKey:@"lon"];

        CLLocationCoordinate2D coordinate;
        coordinate.latitude = lat.doubleValue;
        coordinate.longitude = lon.doubleValue;
        _coordinate = coordinate;
    }
    return self;
}

- (MKMapItem *)mapItem {
    NSDictionary *addressDict = self.address ? @{(NSString *)kABPersonAddressStreetKey : self.address} : @{};

    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.coordinate addressDictionary:addressDict];

    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.name;

    return mapItem;
}

- (id)nullcheck:(id)object {
    return (object && ![object isKindOfClass:[NSNull class]] ? object : nil);
}

@end
