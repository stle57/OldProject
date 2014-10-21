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
#import "TDFindPeopleViewController.h"
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDFollowViewController ()

@property (nonatomic) BOOL gotFromServer;
@property (nonatomic) NSArray *followUsers;
@property (nonatomic) NSArray *suggestedUsers;
@property (nonatomic) NSMutableArray *filteredTDUsers;
@property (nonatomic) NSInteger currentRow;
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
    self.suggestedUsers = nil;
    self.followUsers = nil;
    self.filteredTDUsers = nil;
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
    

    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
}

- (void)viewWillAppear:(BOOL)animated {
     self.edgesForExtendedLayout = UIRectEdgeNone;

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self resizeTableView:self.followControllerType];
    
    origTableViewFrame = self.tableView.frame;
    
    debug NSLog(@"follow view controller table view frame=%@", NSStringFromCGRect( self.tableView.frame));
    [self loadDataFromServer];
}

- (void)loadDataFromServer {

    self.gotFromServer = NO;
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    if (self.followControllerType == kUserListType_Followers) {
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

    } else if (self.followControllerType == kUserListType_Following) {
        [[TDAPIClient sharedInstance] getFollowingSettings:self.profileUser.userId currentUserToken:[TDCurrentUser sharedInstance].authToken success:^(NSArray *users) {
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

    }
}
-(void)viewDidLayoutSubviews{
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
                    if (self.followUsers.count > 0) {
                        return self.followUsers.count;
                    } else {
                        return 1;
                    }
                }
                break;
                default:
                    return 1;
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
    if (tableView == self.tableView) {
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
            }
        } else {
            self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
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

    NSString *str = [NSString stringWithFormat:@"@%@", [object valueForKey:@"username"]];
    usernameAttStr = [TDViewControllerHelper makeParagraphedTextWithString:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
    
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
    cell.userImageView.image = nil;
    if ([object valueForKey:@"picture"] != [NSNull null] && ![[object valueForKey:@"picture"] isEqualToString:@"default"]) {
        [self downloadUserImage:[object valueForKeyPath:@"picture"] cell:cell];
    } else {
        cell.userImageView.image = [UIImage imageNamed:@"prof_pic_default"];
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

- (void)downloadUserImage:(NSString *)profileImage cell:(TDFollowProfileCell *)cell {
    cell.userImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", RSHost, profileImage]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:cell.userImageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        CGFloat width = cell.userImageView.frame.size.width * [UIScreen mainScreen].scale;
        image = [image scaleToSize:CGSizeMake(width, width)];
        if (![finalURL isEqual:cell.userImageURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cell.userImageView) {
                    cell.userImageView.image = image;
                }
            });
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
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
}

- (void)moveTableViewUp {
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.origin.y = tableViewFrame.origin.y;
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
        UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];

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
    TDFindPeopleViewController *vc = [[TDFindPeopleViewController alloc] initWithNibName:@"TDFindPeopleViewController" bundle:nil ];
    vc.profileUser = [TDCurrentUser sharedInstance].currentUserObject;
    [self.navigationController pushViewController:vc animated:NO];
}

@end
