//
//  TDLocationManager.h
//  Throwdown
//
//  Created by Stephanie Le on 12/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "TDLocationManager.h"

@protocol TDLocationManagerHandlerDelegate<NSObject>
@optional
-(void) didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation;
@end

@interface TDLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonatomic, weak) id <TDLocationManagerHandlerDelegate> delegate;
@property (nonatomic) CLLocationManager *locationManager;

+(TDLocationManager*)getSharedInstance;
-(void) startUpdating;
-(void) stopUpdating;

@end
