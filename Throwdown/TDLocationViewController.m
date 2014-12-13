//
//  TDLocationViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLocationViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDLocationCell.h"
#import "TDAPIClient.h"
#import "TDNoResultsCell.h"

@interface TDLocationViewController ()

@end

@implementation TDLocationViewController
static NSString *helpText = @"Please enter at least three characters.";

@synthesize filteredNearbyLocations;
@synthesize gotFromServer;
@synthesize searchingNearbyLocations;
@synthesize searchedLocationList;
@synthesize searchingExactLocation;
@synthesize nearbyLocations;
@synthesize searchStr;
@synthesize delegate;

- (void)dealloc {
    self.filteredNearbyLocations = nil;
    self.nearbyLocations = nil;
    self.searchedLocationList = nil;
    self.nearbyLocations = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.filteredNearbyLocations = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    [navigationBar setOpaque:YES];
    
    // Title
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];
    
    
    // Search Bar
    [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"f5f5f5_square.png"] forBarPosition:0 barMetrics:UIBarMetricsDefault]; // Sets the search bar to a solid color(no transparancy)
    self.searchBar.translucent = NO;
    self.searchBar.layer.borderColor = [[TDConstants darkBorderColor] CGColor];
    self.searchBar.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.searchBar.clipsToBounds = YES;
    self.searchButtonPressed = NO;

    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextAlignment:NSTextAlignmentLeft];
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 25)];
    UILabel *suggestedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, SCREEN_WIDTH/3, 25)];
    UILabel *fourSquareLabel = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-15) - SCREEN_WIDTH/3, 0, SCREEN_WIDTH/2, 25)];
    fourSquareLabel.text = @"Powered By Foursquare";
    fourSquareLabel.font = [TDConstants fontSemiBoldSized:13];
    fourSquareLabel.textColor = [TDConstants helpTextColor];
    [fourSquareLabel sizeToFit];
    CGRect labelFrame = fourSquareLabel.frame;
    labelFrame.origin.x = SCREEN_WIDTH - fourSquareLabel.frame.size.width -10;
    labelFrame.origin.y = fourSquareLabel.frame.size.height/2;
    fourSquareLabel.frame = labelFrame;
    
    suggestedLabel.text = @"NEARBY";
    suggestedLabel.font = [TDConstants fontSemiBoldSized:13.0];
    suggestedLabel.textColor = [TDConstants helpTextColor];
    
    [self.headerView addSubview:suggestedLabel];
    [self.headerView addSubview:fourSquareLabel];
    self.tableView.tableHeaderView = self.headerView;

    // Title
    self.navLabel.text = @"Select Nearby Place";
    
    self.filteredNearbyLocations = [NSMutableArray arrayWithCapacity:[self.nearbyLocations count]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    CGRect frame = self.searchBar.frame;
    frame.size.width = SCREEN_WIDTH;
    self.searchBar.frame = frame;
    [self.searchBar sizeToFit];
    
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.width = SCREEN_WIDTH;
    tableFrame.size.height = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height - self.searchBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    self.tableView.frame = tableFrame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [[TDLocationManager getSharedInstance]setDelegate:self];
    [[TDLocationManager getSharedInstance]startUpdating];
    
}

- (void) loadNearbyPlaces {
    self.gotFromServer = NO;
    NSString *latLon;
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    // Load data from server foursquare after getting coordinates
    if (self.currentLocation != nil) {
        latLon = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
        [[TDAPIClient sharedInstance] loadNearbyLocations:latLon callback:^(BOOL success, NSArray *locations) {
            if (success && locations && locations.count > 0) {
                self.nearbyLocations = [locations copy];
                [self.tableView reloadData];
                [self hideActivity];
                self.gotFromServer = YES;
            } else {
                self.gotFromServer = NO;
                [self hideActivity];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not load locations."
                                                                message:@"Please close and try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];

    }
}

- (void) loadLocation {
    self.gotFromServer = NO;
    self.searchingExactLocation = YES;
    NSString *latLon;
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    // Load data from server foursquare after getting coordinates
    if (self.currentLocation != nil) {
        latLon = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
        [[TDAPIClient sharedInstance] searchForLocation:latLon searchString:self.searchStr callback:^(BOOL success, NSArray *locations) {
            if (success && locations && locations.count > 0) {
                self.searchedLocationList = [locations mutableCopy];
                [self.tableView reloadData];
                [self hideActivity];
                self.gotFromServer = YES;
            } else if (success && locations.count == 0){
                self.gotFromServer = NO;
                [self.tableView reloadData];
                [self hideActivity];
            } else {
                self.gotFromServer = NO;
                [self hideActivity];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not load locations."
                                                                message:@"Please close and try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
        
    }
}

-(void)viewDidLayoutSubviews{
    [self.searchBar setShowsCancelButton:NO animated:NO];
}

- (IBAction)closeButtonHit:(id)sender {
    [self leave];
}

- (void) leave {
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchingExactLocation && self.searchedLocationList.count == 0) {
        return SCREEN_HEIGHT - self.searchBar.frame.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height ;
    }
    
    return 65.5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.searchingNearbyLocations || [self.searchStr isEqual:@""] || !self.searchStr.length) {
        return [self.nearbyLocations count];
    }
    else if (self.searchingExactLocation){
        if (self.searchedLocationList.count) {
            return self.searchedLocationList.count;
        } else {
            return 1;
        }
    
    } else if ([filteredNearbyLocations count] > 0) {
        return [filteredNearbyLocations count] + 1; // Add a row for the search row
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((!self.searchingNearbyLocations) || [self.searchStr isEqual:@""] || !self.searchStr.length) {
        self.tableView.tableHeaderView = self.headerView;

        UITableViewCell *cell = [self createCell:indexPath data:self.nearbyLocations[indexPath.row]];
        
        return cell;
    } else if( self.searchingExactLocation && self.searchedLocationList.count){
        // We need to load the view with different data
        UITableViewCell *cell = [self createCell:indexPath data:self.searchedLocationList[indexPath.row]];
        
        return cell;
    } else if (self.searchingExactLocation && !self.searchedLocationList.count) {
        self.tableView.tableHeaderView = nil;
        
        TDNoResultsCell * cell = (TDNoResultsCell*)[tableView dequeueReusableCellWithIdentifier:@"TDNoResultsCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoResultsCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        NSString *noMatchesString = @"No matches found";
        NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:noMatchesString font:[TDConstants fontSemiBoldSized:16.0] color:[TDConstants headerTextColor] lineHeight:19 lineHeightMultipler:(19/16.0)];
        cell.noMatchesLabel.attributedText = attString;

        CGRect descripFrame = cell.noMatchesLabel.frame;
        descripFrame.origin.y = descripFrame.origin.y + descripFrame.size.height + 7;
        
        cell.descriptionLabel.frame = CGRectMake(0, descripFrame.origin.y, SCREEN_WIDTH, 57);
        CGFloat lineHeight = 19;
        NSString *text = @"Sorry, we weren't able to find\nthe location you're looking for.";
        attString = [TDViewControllerHelper makeParagraphedTextWithString:text font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/15.0)];
        cell.descriptionLabel.attributedText = attString;
        cell.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        cell.userInteractionEnabled = NO;
        return cell;

    } else if (self.searchStr.length && filteredNearbyLocations.count == 0) {
        self.tableView.tableHeaderView = self.headerView;
        UITableViewCell *cell = [self createCell:indexPath data:nil];
    
        return cell;
            
    } else {
        self.tableView.tableHeaderView = self.headerView;
        UITableViewCell *cell;
        if (indexPath.row == self.filteredNearbyLocations.count) {
            cell = [self createCell:indexPath data:nil];
        } else {
            cell = [self createCell:indexPath data:self.filteredNearbyLocations[indexPath.row]];
        }
        return cell;
    }
    return nil;
}

- (UITableViewCell*)createCell:(NSIndexPath*)indexPath data:(NSDictionary*)data {
    TDLocationCell *cell = (TDLocationCell*)[self.tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TD_LOCATION];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_TD_LOCATION owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    cell.topLine.hidden = indexPath.row != 0;
    
    CGRect topLineFrame = cell.topLine.frame;
    topLineFrame.origin.y = .5;
    cell.topLine.frame = topLineFrame;
    
    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                       cell.bottomLine.frame.origin.y,
                                       cell.bottomLine.frame.size.width,
                                       cell.bottomLine.frame.size.height);
    
    if (data) {
        NSString *locationString = [data objectForKey:@"name"];
        cell.locationName.text = locationString;
        
        // Format the address.
        NSString *address = nil;
        NSDictionary *locationData = [data objectForKey:@"location"];
        
        if (![[locationData objectForKey:@"address"] isEqual:@""] ||
            [locationData objectForKey:@"address"] != nil) {
            address = [locationData objectForKey:@"address"];
        }
        
        NSString *city =[locationData objectForKey:@"city"];
        NSString *state = [locationData objectForKey:@"state"];
        
        if ( city != nil && city.length) {
            if (address.length) {
                address = [NSString stringWithFormat:@"%@ %@",address, city];
            } else {
                address = [NSString stringWithFormat:@"%@", city];
            }
        }
        
        if (state != nil && state.length) {
            if (address.length) {
                address = [NSString stringWithFormat:@"%@, %@", address, state];
            } else {
                address = [NSString stringWithFormat:@"%@", state];
            }
        }
        
        if(address.length) {
            cell.descriptionLabel.text = address;
            cell.descriptionLabel.hidden = NO;
        } else {
            // Move the location label to the middle if there is no address
            cell.descriptionLabel.hidden = YES;
            CGRect locationFrame = cell.locationName.frame;
            locationFrame.origin.y = cell.frame.size.height/2 - locationFrame.size.height/2;
            cell.locationName.frame = locationFrame;
        }
    } else {
        NSString *label;
        if (self.searchButtonPressed) {
            label = helpText;
            self.searchButtonPressed = NO;
        } else if (self.searchStr.length){
            label = [NSString stringWithFormat:@"%@\"\%@\"", @"Search for ", self.searchStr];
        }
        cell.locationName.text = label;
        cell.descriptionLabel.hidden = YES;
        cell.locationName.textColor = [TDConstants brandingRedColor];
        cell.locationName.font = [TDConstants fontSemiBoldSized:16];
        CGRect frame = cell.locationName.frame;
        frame.origin.y = cell.frame.size.height/2 - cell.locationName.frame.size.height/2;
        cell.locationName.frame = frame;
        cell.tag = 1000;
    }
    
    return cell;
}

- (void)showActivity {
    self.closeButton.enabled = NO;
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.closeButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchButtonPressed = NO;
    self.searchingNearbyLocations = YES;
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchStr = searchText;
    if (self.searchingExactLocation) {
        // clear out the data and show the nearby list view
        self.searchingExactLocation = NO;
        [self.searchedLocationList removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    
    if (self.searchingNearbyLocations) {
        // If we got here, we are filtering the nearby locations
        [self filterContentForSearchText:searchText scope:nil];
        [self.tableView reloadData];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchBar isFirstResponder] && [touch view] != self.searchBar)
    {
        [self.searchBar resignFirstResponder];
        
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.searchStr = self.searchBar.text;
    if (self.searchStr.length) {
        self.searchingNearbyLocations = YES;
        self.searchingExactLocation = NO;
    } else {
        self.searchingNearbyLocations = NO;
        self.searchingExactLocation = NO;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchStr = self.searchBar.text;
    if (searchBar.text.length < 3) {
        debug NSLog(@"need more characters here");
        self.searchButtonPressed = YES;
        [self.filteredNearbyLocations removeAllObjects];
        [self.tableView reloadData];
    }
    else {
        // Do search stuff here
        [self.searchBar resignFirstResponder];
        [self loadLocation];
    }
}
#pragma mark Content Filtering
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Update the filtered array based on the search text and scope.
    self.searchStr = searchText;
    // Remove all objects from the filtered search array
    [self.filteredNearbyLocations removeAllObjects];
    
    // Filter the arraphy using NSPredicate
    NSString *regexString = [NSString stringWithFormat:@".*\\B%@.*", searchText];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name matches[c] %@)", regexString, regexString];
    NSArray *tempArray = [self.nearbyLocations filteredArrayUsingPredicate:predicate];
    
    self.filteredNearbyLocations = [NSMutableArray arrayWithArray:tempArray];
}

#pragma mark - Keyboard / Textfield

- (void)keyboardWillHide:(NSNotification *)notification {
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    TDLocationCell *cell = (TDLocationCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    if (self.searchingExactLocation && self.searchedLocationList.count) {
        NSDictionary *data = self.searchedLocationList[indexPath.row];
        [self sendLocationDatatoPost:data];
    } else if (self.searchingNearbyLocations && (cell.tag == 1000)) {
        // User hit the last row, to search for exact location
        if (self.searchStr.length > 2) {
            [self.searchBar resignFirstResponder];
            [self loadLocation];
        } else {
            cell.locationName.text = helpText;
        }
    } else if (self.searchingNearbyLocations && self.filteredNearbyLocations.count ) {
        NSDictionary *data = self.filteredNearbyLocations[indexPath.row];
        [self sendLocationDatatoPost:data];
    }
    else {
        NSDictionary *data = self.nearbyLocations[indexPath.row];
        [self sendLocationDatatoPost:data];
    }
}

- (void) sendLocationDatatoPost:(NSDictionary*)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationAdded:)]) {
        [delegate locationAdded:(data)];
        [self leave];
    }
}


-(void) didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    self.currentLocation = newLocation;
    [[TDLocationManager getSharedInstance]stopUpdating];
    [self loadNearbyPlaces];
}

@end
