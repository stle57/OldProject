//
//  TDFindPeopleViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFindPeopleController.h"
#import "UIActionSheet+Blocks.h"
#import "TDUserAPI.h"
#import "TDAPIClient.h"
#import "TDViewControllerHelper.h"
#import "TDInviteViewController.h"
#import "TDUserProfileViewController.h"

@implementation TDFindPeopleController
@synthesize filteredUsersArray;
@synthesize tdUsers;
@synthesize suggestedUsers;
@synthesize origNameLabelYAxis;
@synthesize origNameLabelFrame;
@synthesize inviteList;
@synthesize gotFromServer;
@synthesize currentRow;
@synthesize profileUser;

- (void)dealloc {
    self.tdUsers = nil;
    self.suggestedUsers = nil;
    self.filteredUsersArray = nil;
    self.inviteList = nil;
    self.labels = nil;
    self.profileUser = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        tdUsers = [[NSMutableArray alloc] init];
        inviteList = [[NSMutableArray alloc] init];
        self.labels = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.searchDisplayController.searchBar sizeToFit];
    
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    self.tableView.backgroundColor = [TDConstants darkBackgroundColor];
    self.view.backgroundColor = [TDConstants darkBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    [navigationBar setOpaque:YES];
    
    self.inviteButton.hidden = NO;
    self.inviteButton.titleLabel.font = [TDConstants fontRegularSized:18];
    self.inviteButton.titleLabel.textColor = [UIColor whiteColor];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.inviteButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    // Title
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];
    

    // Search Bar
    [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"e6e6e6_square.png"] forBarPosition:0 barMetrics:UIBarMetricsDefault]; // Sets the search bar to a solid color(no transparancy)
    self.searchDisplayController.searchBar.translucent = NO;
    self.searchDisplayController.searchResultsTableView.backgroundColor = [TDConstants darkBackgroundColor];
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchDisplayController.searchBar.layer.borderColor = [[TDConstants darkBorderColor] CGColor];
    self.searchDisplayController.searchBar.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.searchDisplayController.searchBar.clipsToBounds = YES;
    
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    // Load data from server
    [[TDUserAPI sharedInstance] getSuggestedUserList:^(BOOL success, NSArray *suggestedList) {
        if (success && suggestedList && suggestedList.count > 0) {
            self.suggestedUsers = [suggestedList copy];
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        } else {
            self.gotFromServer = NO;
            [self hideActivity];
        }
    }];
    
    [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSArray *returnList) {
        if (success && returnList && returnList.count > 0) {
            self.tdUsers = [returnList copy];
            self.filteredUsersArray = [NSMutableArray arrayWithCapacity:[self.tdUsers count]];
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        } else {
            self.gotFromServer = NO;
            [self hideActivity];
        }
    }];

    self.filteredUsersArray = [NSMutableArray arrayWithCapacity:[tdUsers count]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Title
    self.navLabel.text = @"Find People";
    self.suggestedLabel.hidden = NO;
    self.inviteButton.hidden = NO;
    self.suggestedLabel.hidden = NO;
    self.suggestedLabel.textColor = [TDConstants helpTextColor];
    self.suggestedLabel.font = [TDConstants fontRegularSized:13];
    self.suggestedLabel.backgroundColor = [TDConstants darkBackgroundColor];
    self.suggestedLabel.layer.borderColor = [[TDConstants lightBorderColor] CGColor];
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.width = SCREEN_WIDTH;
    tableViewFrame.origin.y = self.suggestedLabel.frame.size.height + self.searchDisplayController.searchBar.frame.size.height;
    self.tableView.frame = tableViewFrame;
    
    CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
    searchBarFrame.size.width = SCREEN_WIDTH;
    self.searchDisplayController.searchBar.frame = searchBarFrame;
   [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    //self.tableView.hidden = NO;
    if (self.searchDisplayController.isActive) {
        CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
        searchBarFrame.origin.y  = self.navigationController.navigationBar.frame.size.height;
        self.searchDisplayController.searchBar.frame = searchBarFrame;
        if (self.searchDisplayController.searchBar.hidden == YES) {
            debug NSLog(@"SEARCH BAR IS HIDDEN");
        }
        if (self.searchDisplayController.searchResultsTableView.hidden == YES) {
            debug NSLog(@"SEARCH TABLE VIEW IS HIDDEN");
        }
    debug NSLog(@"!!!!!!!!!search frame inside viewWillAppear:%@", NSStringFromCGRect(self.searchDisplayController.searchResultsTableView.frame));
    debug NSLog(@"searchbar frame = %@", NSStringFromCGRect(self.searchDisplayController.searchBar.frame));
        self.searchDisplayController.searchResultsTableView.hidden = NO;
        [self.searchDisplayController.searchResultsTableView.superview bringSubviewToFront:self.searchDisplayController.searchResultsTableView];
    } else {
        debug NSLog(@"search display is not active");
        debug NSLog(@"!!!!!!!!!table view frame = %@", NSStringFromCGRect(self.tableView.frame));
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
}

- (IBAction)backButtonHit:(id)sender {
    [self leave];
}

- (void) leave {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)inviteButtonHit:(id)sender {
    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.filteredUsersArray == nil || [self.filteredUsersArray count] == 0) {
            [self createLabels];
            UILabel *label = [self.labels objectAtIndex:0];
            UILabel *label2 = [self.labels objectAtIndex:1];
            return 30 + label.frame.size.height + 7 + label2.frame.size.height + 30 + [UIImage imageNamed:@"btn-invite-friends.png"].size.height;
        } else {
            // Calculate the height of the labels
            return 65.0;
        }
    } else {
        return 65.0;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.gotFromServer) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.gotFromServer) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            if ([filteredUsersArray count] > 0) {
                return [filteredUsersArray count];
            } else {
                return 1;
            }
            
        } else {
            return [suggestedUsers count];
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger current = indexPath.row;
    if (tableView == self.tableView) {
        NSArray *object = [self.suggestedUsers objectAtIndex:current];
        
        TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
        return cell;

    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (filteredUsersArray.count == 0) {
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
            
            cell.contentView.backgroundColor = [UIColor whiteColor];
            tableView.backgroundColor = [UIColor whiteColor];
            cell.noFollowLabel.text = @"No matches found";
            
            cell.findPeopleButton.hidden = YES;
            cell.findPeopleButton.enabled = NO;
            
            cell.invitePeopleButton.hidden = NO;
            cell.invitePeopleButton.enabled = YES;
            UILabel *descriptionLabel = [self.labels objectAtIndex:1];
            
            CGRect descripFrame = descriptionLabel.frame;
            descripFrame.origin.y = cell.noFollowLabel.frame.origin.y + cell.noFollowLabel.frame.size.height + 7;
            descripFrame.origin.x = SCREEN_WIDTH/2 - descripFrame.size.width/2;
            descriptionLabel.frame = descripFrame;
            [descriptionLabel setNumberOfLines:0];
            [cell addSubview:descriptionLabel];
            
            CGRect frame = cell.invitePeopleButton.frame;
            frame.origin.x = SCREEN_WIDTH/2 - cell.invitePeopleButton.frame.size.width/2;
            frame.origin.y = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 30;
            cell.invitePeopleButton.frame = frame;
            return cell;
        } else {
            self.searchDisplayController.searchResultsTableView.backgroundColor = [TDConstants darkBackgroundColor];
            NSArray *object = [self.filteredUsersArray objectAtIndex:indexPath.row];
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (tableView == self.tableView) {
//        // Get contact from contract array
//        TDContactInfo *contactPerson = tdUsers[indexPath.row];
//        [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];
//
//    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
//        TDContactInfo *contactPerson = filteredUsersArray[indexPath.row];
//        [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];
//    }
 //   [tableView deselectRowAtIndexPath:indexPath animated:NO];

}

- (TDFollowProfileCell*)createCell:(NSIndexPath*)indexPath tableView:(UITableView*)tableView object:(NSArray*)object{
    BOOL adjustHeightCell = NO;
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    
    cell.topLine.hidden = NO;
    cell.userId = [object valueForKey:@"id"];
    cell.row = indexPath.row;
    NSAttributedString *usernameAttStr = nil;
        NSString *str = [NSString stringWithFormat:@"%@", [object valueForKey:@"bio"]];
        if (str == nil || str.length == 0 || [[object valueForKey:@"bio"] isKindOfClass:[NSNull class]]) {
            str = [NSString stringWithFormat:@"@%@", [object valueForKey:@"username"]];
            usernameAttStr = [TDViewControllerHelper makeParagraphedTextWithString:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
        } else {
            // Need to adjust the height of label to accomodate for emojis in BIO
            adjustHeightCell = YES;
            usernameAttStr = [TDViewControllerHelper makeParagraphedTextForTruncatedBio:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
        }
    
    cell.descriptionLabel.attributedText = usernameAttStr;
    
    if (adjustHeightCell) {
        [cell.descriptionLabel sizeToFit];
        
        CGRect frame = cell.descriptionLabel.frame;
        frame.size.height = frame.size.height +5;
        frame.size.width = cell.descriptionLabelOrigWidth;
        cell.descriptionLabel.frame = frame;
    }
    
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:[object valueForKey:@"name"] font:[TDConstants fontSemiBoldSized:16] color:[TDConstants brandingRedColor] lineHeight:19.0];
    cell.nameLabel.attributedText = attString;
    
    cell.userImageView.hidden = NO;
    
    if ([object valueForKey:@"picture"] != [NSNull null] && ![[object valueForKey:@"picture"] isEqualToString:@"default"]) {
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.userImageView,
                                                 @"filename":[object valueForKeyPath:@"picture"],
                                                 @"width":[NSNumber numberWithInt:cell.userImageView.frame.size.width],
                                                 @"height":[NSNumber numberWithInt:cell.userImageView.frame.size.height]}];
    }
    
    BOOL following =[[object valueForKey:@"following"] boolValue];
    
    if (!following) {
        // Not follow - change action button
        UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
        [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];
        
        [cell.actionButton setTag:kFollowButtonTag];
    } else {
        UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
        [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
        [cell.actionButton setTag:kFollowingButtonTag];
    }
    
    if (cell.userId == [[TDCurrentUser sharedInstance] currentUserObject].userId) {
        cell.actionButton.hidden = YES;
    } else {
        cell.actionButton.hidden = NO;
    }
    return cell;
}

- (void)createLabels {
    
    NSString *text1 = @"No matches found";
    UILabel *noMatchesLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 30, SCREEN_WIDTH, 100)];
    noMatchesLabel.text = text1;
    noMatchesLabel.font = [TDConstants fontSemiBoldSized:16.0];
    noMatchesLabel.textColor = [TDConstants headerTextColor];
    [noMatchesLabel sizeToFit];
    
    [self.labels addObject:noMatchesLabel];
    
    NSString *text2 = @"Sorry, we weren't able to find the\nperson you're looking for.\n Invite them to join Throwndown!";
    
    UILabel *descriptionLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:text2 font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor] lineHeight:19.0 lineHeightMultipler:(19.0/15.0)];
    descriptionLabel.attributedText = attString;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel sizeToFit];
    [self.labels addObject:descriptionLabel];
    
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.view.backgroundColor = [TDConstants darkBackgroundColor];
    self.searchDisplayController.searchResultsTableView.backgroundColor = [TDConstants darkBackgroundColor];
    debug NSLog(@"TEXT BEGIN EDITING");
    debug NSLog(@"  !!!!!!!!!search frame inside viewWillAppear:%@", NSStringFromCGRect(self.searchDisplayController.searchResultsTableView.frame));
    debug NSLog(@"  searchbar frame = %@", NSStringFromCGRect(self.searchDisplayController.searchBar.frame));

    debug NSLog(@"  !!!!!!!!!table view frame = %@", NSStringFromCGRect(self.tableView.frame));
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    debug NSLog(@"TEXT END EDITING");
    debug NSLog(@"  !!!!!!!!!search frame inside viewWillAppear:%@", NSStringFromCGRect(self.searchDisplayController.searchResultsTableView.frame));
    debug NSLog(@"searchbar frame = %@", NSStringFromCGRect(self.searchDisplayController.searchBar.frame));
    debug NSLog(@"  !!!!!!!!!table view frame = %@", NSStringFromCGRect(self.tableView.frame));
}

#pragma mark Content Filtering
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Update the filtered array based on the search text and scope.
    
    // Remove all objects from the filtered search array
    [self.filteredUsersArray removeAllObjects];
    
    // Filter the arraphy using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    NSArray *tempArray = [self.tdUsers filteredArrayUsingPredicate:predicate];
    
    self.filteredUsersArray = [NSMutableArray arrayWithArray:tempArray];
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - TDFollowCellProfileDelegate
- (void)removeFromInviteList:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
    
    debug NSLog(@"removing contact at row=%ld", (long)indexPath.row);
    
    // Remove from invite list on
    if (self.inviteList[indexPath.row] != nil) {
        [self.inviteList removeObjectAtIndex:indexPath.row];
        
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
            TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
            revertedCell.actionButton.hidden = YES;
            revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            revertedCell.descriptionLabel.hidden = YES;
            CGRect frame = revertedCell.nameLabel.frame;
            frame.origin.y = MIDDLE_CELL_Y_AXIS;
            revertedCell.nameLabel.frame = frame;
            revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
        }
    }
}


- (void)reformatCellToUnselected:(UITableViewCell*)cell {
    if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
        TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
        revertedCell.actionButton.hidden = YES;
        revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        revertedCell.descriptionLabel.hidden = YES;
        CGRect frame = revertedCell.nameLabel.frame;
        frame.origin.y = MIDDLE_CELL_Y_AXIS;
        revertedCell.nameLabel.frame = frame;
        revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
    }
}

#pragma mark - TDFollowCellProfileDelegate

- (void)showActivity {
    self.backButton.enabled = NO;
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

#pragma mark - TDNoFollowCellProfileDelegate
- (void)inviteButtonPressed {
    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)userProfilePressedWithId:(NSNumber *)userId {
    [self showUserProfile:userId];
}

- (void)showUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TDFollowCellProfileDelegate
- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber *)userId{
    debug NSLog(@"TDFollowViewControllerDelegate: action button pressed with tag=%tu and row=%ld", tag, (long)row);
    debug NSLog(@"follow/unfollow--");
    self.currentRow = row;
    
    //    NSNumber *userId = nil;
    //    if(self.followUsers != nil) {
    //        userId = [[self.followUsers objectAtIndex:row] valueForKeyPath:@"id"];
    //        debug NSLog(@"going to follow user w/ id=%@", userId);
    //    }
    
    if (tag == kFollowButtonTag) {
        TDFollowProfileCell * cell;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell * modifyCell = nil;
        if (self.filteredUsersArray.count == 0){
            modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
        } else {
            modifyCell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        }
        
        if(modifyCell != nil) {
            cell = (TDFollowProfileCell*)modifyCell;
            // Got the cell, change the button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
            [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
            [cell.actionButton setTag:kFollowingButtonTag];
            
        }
        // Send follow user to server
        [[TDUserAPI sharedInstance] followUser:userId callback:^(BOOL success) {
            if (success) {
                // Send notification to update user profile stat button-add
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[[TDCurrentUser sharedInstance] currentUserObject].userId userInfo:@{TD_INCREMENT_STRING: @1}];
            } else {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                // Switch button back
                if (cell != nil) {
                    // Got the cell, change the button
                    UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
                    [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
                    [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
                    [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];
                    [cell.actionButton setTag:kFollowButtonTag];
                }
            }
        }];
    } else if (tag == kFollowingButtonTag) {
        NSString *reportText = [NSString stringWithFormat:@"Unfollow @%@", [[self.tdUsers objectAtIndex:row] valueForKeyPath:@"username"]];
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:reportText
                                                         otherButtonTitles:nil, nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSNumber *userId = nil;
    if(self.tdUsers != nil) {
        userId = [[self.tdUsers objectAtIndex:self.currentRow] valueForKeyPath:@"id"];
    }
    
    TDFollowProfileCell * cell;
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // If confirmed, switch the button
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentRow inSection:0];
        UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
        if(modifyCell != nil) {
            cell = (TDFollowProfileCell*)modifyCell;
            // Got the cell, change the button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
            [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];
            [cell.actionButton setTag:kFollowButtonTag];
            
        }
        
        // Send unfollow user to server
        [[TDUserAPI sharedInstance] unFollowUser:userId callback:^(BOOL success) {
            if (success) {
                debug NSLog(@"Successfully unfollwed user=%@", userId);
                // send notification to update user follow count-subtract
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[[TDCurrentUser sharedInstance] currentUserObject].userId userInfo:@{TD_DECREMENT_STRING: @1}];
            } else {
                debug NSLog(@"could not follow user=%@", userId);
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                debug NSLog(@"could not follow user=%@", userId);
                //TODO: Display toast saying error processing, TRY AGAIN
                // Switch button back to cell
                UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
                [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
                [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
                [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
                [cell.actionButton setTag:kFollowingButtonTag];
            }
        }];
    }
    
}

@end
