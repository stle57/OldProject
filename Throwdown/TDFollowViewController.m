//
//  TDFollowViewController.m
//  Throwdown
//
//  Created by Stephanie on 9/12/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFollowViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDUserAPI.h"
#import "NBPhoneNumberUtil.h"
#import "UIImage+Resizing.h"
#import "UIImage+Rotating.h"
#import "TDAPIClient.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDUserPushNotificationsEditViewController.h"
#import "TDSocialNetworksViewController.h"
#import "TDInviteViewController.h"
#import "TDUserProfileViewController.h"

@interface TDFollowViewController ()

@property (nonatomic) BOOL gotFromServer;
@property (nonatomic) NSArray *followUsers;
@property (nonatomic) NSMutableArray *filteredTDUsers;
@property (nonatomic) NSInteger currentRow;
@property (nonatomic) UITextField *searchBarTextField;
@end

@implementation TDFollowViewController

@synthesize profileUser;
@synthesize name;
@synthesize username;
@synthesize pictureFileName;
@synthesize editedProfileImage;
@synthesize tempFlyInImageView;
@synthesize followControllerType;

- (void)dealloc {
    self.profileUser = nil;
    self.name = nil;
    self.username = nil;
    self.pictureFileName = nil;
    self.editedProfileImage = nil;
    self.tempFlyInImageView = nil;
    self.labels = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //debug NSLog(@"EditUserProfile:%@", self.profileUser);
    
    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];
    self.labels = [[NSMutableArray alloc] init];
    
    if (self.followControllerType == kUserListType_Followers) {
        self.titleLabel.text = @"Followers";
        [self resizeTableView:self.followControllerType];
    } else if (self.followControllerType == kUserListType_Following){
        self.titleLabel.text = @"Following";
        [self resizeTableView:self.followControllerType];
    } else if (self.followControllerType == kUserListType_TDUsers) {
        self.titleLabel.text = @"Find People";
        [self resizeTableView:self.followControllerType];
    }
    
    // Title
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBarStyle:UIBarStyleBlack];
    navigationBar.translucent = NO;
    
    // Buttons
    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    self.tableView.contentInset = UIEdgeInsetsMake(-35.0f, 0.0f, 0.0f, 0.0f);
    
    self.searchDisplayController.searchBar.layer.borderColor = [[TDConstants darkBorderColor] CGColor];
    self.searchDisplayController.searchBar.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.searchDisplayController.searchBar.clipsToBounds = YES;

    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextAlignment:NSTextAlignmentLeft];

    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Changes the "search for people" font and text color
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];

    self.tableView.backgroundColor = [TDConstants darkBackgroundColor];
    self.view.backgroundColor = [TDConstants darkBackgroundColor];
    
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    self.suggestedLabel.hidden = YES;
    if (self.followControllerType == kUserListType_Following){
        self.searchDisplayController.searchBar.hidden = YES;
        [[TDAPIClient sharedInstance] getFollowingSettings:self.profileUser.userId currentUserToken:[TDCurrentUser sharedInstance].authToken success:^(NSArray *users) {
            if ([users isKindOfClass:[NSArray class]]) {
                self.followUsers = users;
            }
            else {
                debug NSLog(@"not a dictionary");
            }
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];

        } failure:^{
            self.gotFromServer = NO;
            [self.tableView reloadData];
            [self hideActivity];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't load users"
                                                        message:@"Please close and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
            [alert show];
        }];
    } else if (self.followControllerType == kUserListType_Followers) {
        self.searchDisplayController.searchBar.hidden = YES;
        [[TDAPIClient sharedInstance] getFollowerSettings:self.profileUser.userId currentUserToken:[TDCurrentUser sharedInstance].authToken success:^(NSArray *users) {
            if ([users isKindOfClass:[NSArray class]]) {
                self.followUsers = users;
            }
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        } failure:^{
            self.gotFromServer = NO;
            [self.tableView reloadData];
            [self hideActivity];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't load users"
                                                            message:@"Please close and try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    } else if (self.followControllerType == kUserListType_TDUsers) {
        self.searchDisplayController.searchBar.hidden = NO;
        [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"e6e6e6_square.png"] forBarPosition:0 barMetrics:UIBarMetricsDefault]; // Sets the search bar to a solid color(no transparancy)
        self.searchDisplayController.searchBar.translucent = NO;
        
        self.suggestedLabel.hidden = NO;
        self.suggestedLabel.textColor = [TDConstants helpTextColor];
        self.suggestedLabel.font = [TDConstants fontRegularSized:13];
        self.suggestedLabel.backgroundColor = [TDConstants darkBackgroundColor];
        self.suggestedLabel.layer.borderColor = [[TDConstants lightBorderColor] CGColor];
        
        self.inviteButton.hidden = NO;
        self.inviteButton.titleLabel.font = [TDConstants fontRegularSized:18];
        self.inviteButton.titleLabel.textColor = [UIColor whiteColor];
        UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.inviteButton];
        self.navigationItem.rightBarButtonItem = rightBarButton;
        
        // Load data from server
        [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSArray *returnList) {
            if (success && returnList && returnList.count > 0) {
                self.followUsers = [returnList copy];
                self.filteredTDUsers = [NSMutableArray arrayWithCapacity:[self.followUsers count]];
                self.gotFromServer = YES;
                [self.tableView reloadData];
                [self hideActivity];
            } else {
                self.gotFromServer = NO;
            }
        }];

    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.gotFromServer) {
        [self showActivity];
    }
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self resizeTableView:self.followControllerType];
    
    origTableViewFrame = self.tableView.frame;
    
    if (self.gotFromServer) {
        [self hideActivity];
    }
}

-(void)viewDidLayoutSubviews{
    if (self.followControllerType == kUserListType_TDUsers) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = TABLEVIEW_POSITION_UNDER_SEARCHBAR;
        self.tableView.frame = tableViewFrame;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)backButtonHit:(id)sender {
    [self leave];
}

- (IBAction)inviteButtonHit:(id)sender {
    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (NSString *)buildStringFromErrors:(NSArray *)array baseString:(NSString *)baseString {
    NSMutableString *returnString = [NSMutableString string];
    for (NSString *string in array) {
        [returnString appendFormat:@"%@ %@. ", baseString, string];
    }
    return returnString;
}

- (void)leave {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.gotFromServer) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.gotFromServer) {
        if (tableView == self.tableView) {
            switch (section) {
                case 0: // follow/following user list
                {
                    if(self.followUsers.count > 0)
                    {
                        return self.followUsers.count;
                    }
                    else{
                        return 1;
                    }
                }
                break;
                default:
                    return 1;
                    break;
            }
        } else if (tableView == self.searchDisplayController.searchResultsTableView) {
            switch (section) {
                case 0: // follow/following user list
                {
                    if(self.filteredTDUsers.count > 0)
                    {
                        return self.filteredTDUsers.count;
                    }
                    else{
                        return 1;
                    }
                }
                break;
                default:
                    return 0;
                    break;
            }
        }
    } else {
        return 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
      NSInteger currentRow = indexPath.row;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.filteredTDUsers == nil || self.filteredTDUsers.count == 0) {
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
            NSArray *object = [self.filteredTDUsers objectAtIndex:indexPath.row];
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
        }
    } else if (tableView == self.tableView) {
        
        if (self.followUsers == nil || self.followUsers.count == 0) {
            self.tableView.backgroundColor = [UIColor whiteColor];
            
            if (self.followControllerType == kUserListType_Followers) {
                TDNoFollowProfileCell* cell = [self createNoFollowCell:indexPath tableView:tableView text:@"No followers yet" hideFindButton:YES hideInviteButton:YES];
                
                return cell;
            } else if (self.followControllerType == kUserListType_Following){
                if (self.profileUser.userId == [TDCurrentUser sharedInstance].currentUserObject.userId) {
                    TDNoFollowProfileCell *cell = [self createNoFollowCell:indexPath tableView:tableView text:@"Not following anyone" hideFindButton:NO hideInviteButton:NO];
                    
                    return cell;
                } else {
                    // Only allow the invite and find button for the current device/user that is in operation.
                    TDNoFollowProfileCell *cell = [self createNoFollowCell:indexPath tableView:tableView text:@"Not following anyone" hideFindButton:YES hideInviteButton:YES];
                    
                    return cell;
                }
            } else if (self.followControllerType == kUserListType_TDUsers) {
                TDNoFollowProfileCell *cell = [self createNoFollowCell:indexPath tableView:tableView text:@"No followers yet" hideFindButton:NO hideInviteButton:NO];
                
                return cell;
            }
        } else {
            NSArray *object = [self.followUsers objectAtIndex:currentRow];
            
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
        }
    }
    return nil;
}

- (TDNoFollowProfileCell*)createNoFollowCell:(NSIndexPath*)indexPath tableView:(UITableView*)tableView text:(NSString*)text hideFindButton:(BOOL)hideFindButton hideInviteButton:(BOOL)hideInviteButton {
    TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }

    cell.noFollowLabel.text = text;
    cell.findPeopleButton.hidden = hideFindButton;
    cell.invitePeopleButton.hidden = hideFindButton;
    if (hideInviteButton == NO) {
        cell.findPeopleButton.enabled = !hideInviteButton;
    } else {
        cell.findPeopleButton.enabled = !hideInviteButton;
    }
    
    if (hideFindButton == NO) {
        cell.invitePeopleButton.enabled = !hideFindButton;
    } else {
        cell.invitePeopleButton.enabled = !hideFindButton;
    }
    
    return cell;
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
    if (self.followControllerType == kUserListType_TDUsers) {
        NSString *str = [NSString stringWithFormat:@"%@", [object valueForKey:@"bio"]];
        if (str == nil || str.length == 0 || [[object valueForKey:@"bio"] isKindOfClass:[NSNull class]]) {
            str = [NSString stringWithFormat:@"@%@", [object valueForKey:@"username"]];
            usernameAttStr = [TDViewControllerHelper makeParagraphedTextWithString:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
        } else {
            // Need to adjust the height of label to accomodate for emojis in BIO
            adjustHeightCell = YES;
            usernameAttStr = [TDViewControllerHelper makeParagraphedTextForTruncatedBio:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
        }
    } else {
        NSString *str = [NSString stringWithFormat:@"@%@", [object valueForKey:@"username"]];
        usernameAttStr = [TDViewControllerHelper makeParagraphedTextWithString:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.filteredTDUsers == nil || self.filteredTDUsers.count == 0) {
            [self createLabels];
            UILabel *label = [self.labels objectAtIndex:0];
            UILabel *label2 = [self.labels objectAtIndex:1];
            return 30 + label.frame.size.height + 7 + label2.frame.size.height + 30 + [UIImage imageNamed:@"btn-invite-friends.png"].size.height;
        } else {
            return TD_FOLLOW_CELL_HEIGHT;
        }
    } else if (tableView == self.tableView) {
        if (self.followUsers == nil || self.followUsers.count == 0) {
            return TD_NOFOLLOWCELL_HEIGHT; // For the no following/no followers cell
        } else {
            return TD_FOLLOW_CELL_HEIGHT;
        }
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.followControllerType == kUserListType_TDUsers) {
        if (!self.suggestedLabel.hidden) {
            self.suggestedLabel.hidden = YES;
            [self moveTableViewUp];
        }
    }
}

- (void)moveTableViewUp {
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.origin.y = tableViewFrame.origin.y - self.suggestedLabel.frame.size.height;
    self.tableView.frame = tableViewFrame;
}

- (void)resizeTableView:(kUserListType)followViewControllerType {
    if (followViewControllerType == kUserListType_Followers) {
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 0;
        tableViewFrame.size.height = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height;
        self.tableView.frame = tableViewFrame;
    } else if (followViewControllerType == kUserListType_Following){
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 0;
        tableViewFrame.size.height = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height;
        self.tableView.frame = tableViewFrame;
    } else if (followViewControllerType == kUserListType_TDUsers) {
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = TABLEVIEW_POSITION_UNDER_SEARCHBAR - self.searchDisplayController.searchBar.frame.size.height;
        self.tableView.frame = tableViewFrame;
    }
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
    
    NSString *text2 = @"Sorry we weren't able to find the\nperson you're looking for.\n Invite them to join Throwndown.";

    UILabel *descriptionLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:text2 font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor] lineHeight:19.0 lineHeightMultipler:(19.0/15.0)];
    descriptionLabel.attributedText = attString;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel sizeToFit];
    [self.labels addObject:descriptionLabel];

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
        if (self.filteredTDUsers.count == 0){
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
        NSString *reportText = [NSString stringWithFormat:@"Unfollow @%@", [[self.followUsers objectAtIndex:row] valueForKeyPath:@"username"]];
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
    if(self.followUsers != nil) {
        userId = [[self.followUsers objectAtIndex:self.currentRow] valueForKeyPath:@"id"];
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

- (void)userProfilePressedWithId:(NSNumber *)userId {
    [self showUserProfile:userId];
}

- (void)showUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
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
- (void)findButtonPressed {
    TDFollowViewController *vc = [[TDFollowViewController alloc] initWithNibName:@"TDFollowViewController" bundle:nil ];
    vc.followControllerType = kUserListType_TDUsers;
    vc.profileUser = self.profileUser;
    [self.navigationController pushViewController:vc animated:YES];

}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.suggestedLabel.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    self.suggestedLabel.hidden = NO;
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	// Update the filtered array based on the search text and scope.
	
    // Remove all objects from the filtered search array
	[self.filteredTDUsers removeAllObjects];
    
	// Filter the arraphy using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    NSArray *tempArray = [self.followUsers filteredArrayUsingPredicate:predicate];
    
    self.filteredTDUsers = [NSMutableArray arrayWithArray:tempArray];
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
@end
