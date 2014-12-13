//
//  TDLocationManager.m
//  Throwdown
//
//  Created by Stephanie Le on 12/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//
#import "TDLocationManager.h"

static TDLocationManager *tdLocationManager = nil;

@implementation TDLocationManager
@synthesize delegate;

+(TDLocationManager*)getSharedInstance{
    static TDLocationManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDLocationManager alloc] init];
    });
    return _sharedInstance;
}

-(id)init{
    debug NSLog(@"init LocationManager");
    self = [super init];
    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.delegate = self;
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    return self;
}

-(void)startUpdating {
    [_locationManager startUpdatingLocation];
}

-(void)stopUpdating {
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    CLLocation *oldLocation;
    if (locations.count > 1) {
        oldLocation = [locations objectAtIndex:locations.count-2];
    } else {
        oldLocation = nil;
    }

    if ([self.delegate respondsToSelector:@selector(didUpdateToLocation:fromLocation:)])
    {
        [delegate didUpdateToLocation:newLocation
                              fromLocation:oldLocation];
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    if (error.code == kCLErrorDenied)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested"
                                                        message:@"To access your location,\nplease go to\niPhone Settings > Privacy\n> Location Services, and\nswitch Throwdown to\n \"While Using the App\"."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
@end
