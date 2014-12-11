//
//  TDLocationViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "TDActivityIndicator.h"
@protocol TDLocationViewControllerDelegate <NSObject>
@optional
//- (void)locationAdded:(NSString*)locationName;
- (void)locationAdded:(NSDictionary *)data;
@end

@interface TDLocationViewController : UIViewController<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) id <TDLocationViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (nonatomic) NSArray *nearbyLocations;
@property (nonatomic) NSMutableArray *searchedLocationList;
@property (nonatomic) NSMutableArray *filteredNearbyLocations;
@property (nonatomic) CLLocationManager *locationManager;

@property (retain) UIView *headerView;
@property (nonatomic) BOOL gotFromServer;
@property (nonatomic) BOOL searchingNearbyLocations;
@property (nonatomic) BOOL searchingExactLocation;
@property (nonatomic) NSString *searchStr;
@property (nonatomic) BOOL searchButtonPressed;
@property (nonatomic, retain) CLLocation* currentLocation;

- (IBAction)closeButtonHit:(id)sender;

- (void)hideActivity;
- (void)showActivity;
@end

