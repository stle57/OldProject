//
//  TDLocationFeedViewController.m
//  Throwdown
//
//  Created by Andrew C on 12/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLocationFeedViewController.h"
#import "TDViewControllerHelper.h"
#import "TDConstants.h"
#import "TDLocation.h"
#import "TDAnalytics.h"

@interface TDLocationFeedViewController () <MKMapViewDelegate>

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSNumber *nextStart;
@property (nonatomic) TDLocation *location;
@property (nonatomic) UIView *headerView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) UIView *viewOverlay;

@end

@implementation TDLocationFeedViewController

- (void)dealloc {
    self.locationId = nil;
    self.location = nil;
    self.headerView = nil;
    if (self.mapView) {
        self.mapView.delegate = nil;
    }
    self.mapView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];

    // Background
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];

    // Title
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    self.titleLabel.text = @"";
    [self.navigationItem setTitleView:self.titleLabel];

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    [self.view addSubview:self.tableView];

    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.y = -(navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shareButtonHit:(id)sender {
    [self showShareSheet];
}

#pragma mark - Posts

- (NSArray *)postsForThisScreen {
    return self.posts;
}

- (BOOL)hasMorePosts {
    return self.nextStart != nil;
}

- (TDPost *)postForRow:(NSInteger)row {
    if (row < self.posts.count) {
        return [self.posts objectAtIndex:row];
    } else {
        return nil;
    }
}

- (void)refreshControlUsed {
    [self fetchPosts];
}

- (void)fetchPosts {
    if (!self.locationId) {
        return;
    }
    [[TDPostAPI sharedInstance] fetchPostsForLocationId:self.locationId start:nil success:^(NSDictionary *response) {
        if ([response valueForKeyPath:@"location"]) {
            self.location = [[TDLocation alloc] initWithDictionary:[response valueForKeyPath:@"location"]];
            self.titleLabel.text = self.location.name;
            [self loadHeaderView];
        }
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:YES];
    } error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        self.errorLoading = YES;
        [self.tableView reloadData];
    }];
}

- (void)handleNextStart:(NSNumber *)start {
    // start can be [NSNull null] here
    if (start && [[start class] isSubclassOfClass:[NSNumber class]]) {
        self.nextStart = start;
    } else {
        self.nextStart = nil;
    }
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    self.loaded = YES;
    self.errorLoading = NO;

    if (start) {
        self.posts = nil;
    }

    NSMutableArray *newPosts;
    if (self.posts) {
        newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
    } else {
        newPosts = [[NSMutableArray alloc] init];
    }

    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]) {
        TDPost *post = [[TDPost alloc] initWithDictionary:postObject];
        [newPosts addObject:post];
    }

    self.posts = newPosts;
    [self refreshPostsList];
}

- (BOOL)fetchMorePostsAtBottom {
    if (![self hasMorePosts] || !self.locationId) {
        return NO;
    }
    [[TDPostAPI sharedInstance] fetchPostsForLocationId:self.locationId start:self.nextStart success:^(NSDictionary *response) {
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:NO];
    } error:^{
        self.errorLoading = YES;
    }];
    return YES;
}

#pragma mark - View delegate and event overrides

- (void)locationButtonPressedFromRow:(NSInteger)row {
    // Do nothing, this overrides the TDPostViewControllers method which would just open the same location
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"TDLocation";
    if ([annotation isKindOfClass:[TDLocation class]]) {

        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = NO;
            annotationView.image = [UIImage imageNamed:@"large_location_pin"];
        } else {
            annotationView.annotation = annotation;
        }

        return annotationView;
    }

    return nil;
}

- (void)loadHeaderView {
    if (self.headerView) {
        return;
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 165)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, width, 150)];
    self.mapView.delegate = self;
    [self.headerView addSubview:self.mapView];
    [self.tableView setTableHeaderView:self.headerView];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 150, width, 1 / [[UIScreen mainScreen] scale])];
    bottomLine.backgroundColor = [TDConstants darkBorderColor];
    [self.headerView addSubview:bottomLine];

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.location.coordinate, kMapDefaultDistance, kMapDefaultDistance);
    [self.mapView addAnnotation:self.location];
    [self.mapView setRegion:region animated:NO];

    UIButton *shareButton = [TDViewControllerHelper navShareButton];
    [shareButton addTarget:self action:@selector(shareButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    self.navigationItem.rightBarButtonItem = barButton;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self removeOverlay];
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // nothing
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self removeOverlay];
        [self openMaps];
    } else {
        [self openGoogleMaps];
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (id actionSubview in actionSheet.subviews) {
        if ([actionSubview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)actionSubview;
            button.titleLabel.textColor = [TDConstants headerTextColor];
        }
    }
}

- (void)removeOverlay {
    [self.viewOverlay removeFromSuperview];
}


#pragma mark - Open maps apps

- (void)showShareSheet {

    NSString *appleMaps = @"Open in Apple Maps";
    NSString *googleMaps = [self canOpenGoogleMaps] ? @"Open in Google Maps" : nil;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {

        self.viewOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        self.viewOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:appleMaps
                                                        otherButtonTitles:googleMaps, nil];

        [[TDAppDelegate appDelegate].window addSubview:self.viewOverlay];
        [actionSheet showInView:self.viewOverlay];

    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *appleMapsAction = [UIAlertAction actionWithTitle:appleMaps
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    [self openMaps];
                                                                }];
        [alert addAction:appleMapsAction];

        if ([self canOpenGoogleMaps]) {
            UIAlertAction *googleMapsAction =[UIAlertAction actionWithTitle:googleMaps
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        [self openGoogleMaps];
                                                                    }];
            [alert addAction:googleMapsAction];
        }

        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];

        [alert addAction:cancel];
        alert.view.tintColor = [TDConstants headerTextColor];

        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)openMaps {
    NSDictionary *launchOptions = @{
                                    MKLaunchOptionsMapCenterKey: [NSValue valueWithMKCoordinate:self.mapView.centerCoordinate],
                                    MKLaunchOptionsMapSpanKey: [NSValue valueWithMKCoordinateSpan:self.mapView.region.span],
                                    MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard],
                                    };

    [MKMapItem openMapsWithItems:@[[self.location mapItem]] launchOptions:launchOptions];
}

- (BOOL)canOpenGoogleMaps {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
}

- (void)openGoogleMaps {
    NSURL *url = [self googleMapsURL];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        NSLog(@"Can't use comgooglemaps://");
    }
}

- (NSURL *)googleMapsURL {
    NSString *name = TDURLEscapedString(self.location.name);
    return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?q=%f,%f(%@)", (double)self.location.coordinate.latitude, (double)self.location.coordinate.longitude , name]];
}

@end
