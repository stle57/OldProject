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
static NSInteger const kInviteButtonTag = 20001;
static NSInteger const kFollowButtonTag = 20002;
static NSInteger const kFollowingButtonTag = 20003;

@interface TDFollowViewController ()

@property (nonatomic) BOOL hasLoaded;
@property (nonatomic) NSArray *followUsers;
@property (nonatomic) NSInteger currentRow;
@end

@implementation TDFollowViewController

//@synthesize profileUser;
@synthesize name;
@synthesize username;
//@synthesize phone;
//@synthesize email;
//@synthesize password;
//@synthesize bio;
@synthesize pictureFileName;
@synthesize editedProfileImage;
@synthesize tempFlyInImageView;
@synthesize followControllerType;

- (void)dealloc {
  //  self.profileUser = nil;
    self.name = nil;
    self.username = nil;
//    self.phone = nil;
//    self.email = nil;
//    self.password = nil;
//    self.bio = nil;
    self.pictureFileName = nil;
    self.editedProfileImage = nil;
    self.tempFlyInImageView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //debug NSLog(@"EditUserProfile:%@", self.profileUser);
    
    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Title
    if (self.followControllerType == kUserListType_Followers) {
        self.titleLabel.text = @"Followers";
    } else {
        self.titleLabel.text = @"Following";
    }
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    debug NSLog(@"user edit bg color=%@", self.tableView.backgroundColor);
    self.tableView.backgroundColor = [TDConstants tableViewBackgroundColor];
    debug NSLog(@"  bg after color=%@", self.tableView.backgroundColor);
    // Buttons
//    self.saveButton.titleLabel.font = [TDConstants fontRegularSized:18.0];
//    UIBarButtonItem *saveBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.saveButton];
//    self.navigationItem.rightBarButtonItem = saveBarButton;

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    self.tableView.contentInset = UIEdgeInsetsMake(-40.0f, 0.0f, 0.0f, 0.0f);

    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    if (self.followControllerType == kUserListType_Following){
        
        [[TDAPIClient sharedInstance] getFollowingSettings:[TDCurrentUser sharedInstance].authToken success:^(NSArray *users) {
            self.hasLoaded = YES;
            debug NSLog(@"Following %lu users", (unsigned long)users.count);
            if ([users isKindOfClass:[NSArray class]]) {
                self.followUsers = users;
            }
            else {
                debug NSLog(@"not a dictionary");
            }
            //[self checkForSaveButton];
            [self.tableView reloadData];
            [self hideActivity];
        } failure:^{
            self.hasLoaded = NO;
            [self.tableView reloadData];
            [self hideActivity];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't load profile"
                                                        message:@"Please close and re-open settings to be able to make changes."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
            [alert show];
        }];
    } else if (self.followControllerType == kUserListType_Followers) {
        [[TDAPIClient sharedInstance] getFollowerSettings:[TDCurrentUser sharedInstance].authToken success:^(NSArray *users) {
            self.hasLoaded = YES;
            debug NSLog(@"%lu followers", (unsigned long)users.count);
            if ([users isKindOfClass:[NSArray class]]) {
                self.followUsers = users;
            }
            //[self checkForSaveButton];
            debug NSLog(@"follow call is calling reloadData on tableView");
            [self.tableView reloadData];
            [self hideActivity];
        } failure:^{
            self.hasLoaded = NO;
            [self.tableView reloadData];
            [self hideActivity];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't load profile"
                                                            message:@"Please close and re-open settings to be able to make changes."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    origTableViewFrame = self.tableView.frame;

    if (self.hasLoaded) {
        //[self checkForSaveButton];
        [self hideActivity];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadComplete:) name:TDAvatarUploadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFailed:) name:TDAvatarUploadFailedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//- (IBAction)saveButtonHit:(id)sender {
//    [self hideKeyboard];
//    [self showActivity];
//    if (self.editedProfileImage) {
//        self.activityIndicator.text.text = @"Uploading photo";
//        [self uploadNewAvatarImage];
//    } else {
//        [self sendToTheServer];
//    }
//}

- (void)backButtonHit:(id)sender {
    [self leave];
}

- (NSString *)buildStringFromErrors:(NSArray *)array baseString:(NSString *)baseString {
    NSMutableString *returnString = [NSMutableString string];
    for (NSString *string in array) {
        [returnString appendFormat:@"%@ %@. ", baseString, string];
    }
    return returnString;
}

- (void)leave {
    switch (followControllerType) {
        case kUserListType_Followers:
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        break;
        case kUserListType_Following:
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        break;

        default:
        break;
    }
}

#pragma mark - Keyboard / Textfield

- (void)updateFieldsForTextField:(UITextField *)textfield text:(NSString *)text {
    // 800+(10*indexPath.section)+indexPath.row;
    switch (textfield.tag) {
        case (800+10*0+1):
            self.name = text;
            break;
        case (800+10*0+2):
            self.username = text;
            break;
//        case (800+10*1+0):
//            self.phone = text;
//            break;
//        case (800+10*1+1):
//            self.email = text;
//            break;
//        case (800+10*1+2):
//            self.password = text;
//            break;
        default:
            break;
    }

    //[self checkForSaveButton];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateFieldsForTextField:textField text:textField.text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self updateFieldsForTextField:textField text:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    //[self checkForSaveButton];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateFieldsForTextField:textField text:textField.text];
}

- (IBAction)textFieldDidChange:(id)sender {
   // [self checkForSaveButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //[self checkForSaveButton];
    return YES;
}

- (void)keyboardWillHide:(NSNotification *)n {
    if (!keybdUp) {
        return;
    }

    // resize the table
    [UIView animateWithDuration: 0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{

                         self.tableView.frame = origTableViewFrame;
                     }
                     completion:^(BOOL done) {

                         if (done)
                         {
                             keybdUp = NO;
                         }
                     }];
}

- (void)keyboardWillShow:(NSNotification *)n {
    if (keybdUp) {
        return;
    }

    NSDictionary* userInfo = [n userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the table
    CGRect tableViewNewFrame = origTableViewFrame;
    tableViewNewFrame.size.height -= (keyboardSize.height);

    [UIView animateWithDuration: 0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{

                         self.tableView.frame = tableViewNewFrame;
                     }
                     completion:^(BOOL done) {

                         if (done)
                         {
                             keybdUp = YES;
                         }
                     }];
}

- (void)hideKeyboard {
    for (TDUserEditCell *cell in self.tableView.visibleCells) {
        if ([cell.textField isFirstResponder]) {
            [cell.textField resignFirstResponder];
            self.tableView.frame = origTableViewFrame;
            keybdUp = NO;
        }
    }
}

#pragma mark - Check Save Button
- (BOOL)checkIfChanged {
    if (!self.hasLoaded) {
        // Don't allow saving if server failed
        return NO;
    }
//    if ([self.phone length] > 0 && ![self validatePhone]) {
//        return NO;
//    }

//    NSString *currentBio = [self.settings objectForKey:@"bio"];
//    if (self.editedProfileImage != nil ||
//        ([self.name length] > 0 && ![self.name isEqualToString:[self.settings objectForKey:@"name"]]) ||
//        ([self.username length] > 0 && ![self.username isEqualToString:[self.settings objectForKey:@"username"]]) ||
//        ([self.phone length] > 0 && ![self.phone isEqualToString:[self.settings objectForKey:@"displayed_phone_number"]]) ||
//        (![self.bio isEqualToString:(currentBio ? currentBio :  @"")]) ||
//        ([self.email length] > 0 && ![self.email isEqualToString:[self.settings objectForKey:@"displayed_email"]]))
//    {
//        return YES;
//    }

    return NO;
}

//- (void)checkForSaveButton {
//    if ([self checkIfChanged]) {
//        self.saveButton.enabled = YES;
//    } else {
//        self.saveButton.enabled = NO;
//    }
//}

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if (section == 1) {
//        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 40)];
//        UILabel *sectionHeaderLabel = [[UILabel alloc] initWithFrame:headerView.layer.frame];
//        sectionHeaderLabel.text = @"PRIVATE INFORMATION";
//        sectionHeaderLabel.font = [UIFont fontWithName:TDFontProximaNovaSemibold size:15.0];
//        sectionHeaderLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
//        CGRect headerLabelFrame = sectionHeaderLabel.frame;
//        headerLabelFrame.origin.x = 12.0;
//        headerLabelFrame.origin.y += 8;
//        sectionHeaderLabel.frame = headerLabelFrame;
//        [headerView addSubview:sectionHeaderLabel];
//        return headerView;
//    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    debug NSLog(@"inside numberOfRowsInSection");
    switch (section) {
        case 0: // follow/following user list
        {
            if(self.followUsers.count > 0)
            {
                debug NSLog(@"  returning %lu rows", self.followUsers.count);
                return self.followUsers.count;
            }
            else{
                debug NSLog(@"  returning 1 row");
                return 1;
            }
        }
        break;
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"inside cellForRowAtIndexPath");
      NSInteger currentRow = indexPath.row;
    
    if (self.followUsers == nil || self.followUsers.count == 0) {
        if (self.followControllerType == kUserListType_Followers) {
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
        
            cell.noFollowLabel.text = @"No followers yet";
            cell.findPeopleButton.hidden = NO;
            cell.invitePeopleButton.hidden = NO;
            cell.findPeopleButton.enabled = YES;
            cell.invitePeopleButton.enabled = YES;

            return cell;
        } else if (self.followControllerType == kUserListType_Following){
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
            
            cell.noFollowLabel.text = @"Not following anyone";
            cell.invitePeopleButton.hidden = YES;
            cell.findPeopleButton.hidden = YES;
            debug NSLog(@"hide invite/find button");
            
            return cell;
        }
    } else {
        TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];

        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
            cell.userId = [[self.followUsers objectAtIndex:currentRow] valueForKey:@"id"];
            cell.row = indexPath.row;
        }
        NSString *usernameStr = [NSString stringWithFormat:@"@%@", [[self.followUsers objectAtIndex:currentRow] valueForKey:@"username"] ];
        //TODO: Set line height for usernameLabel(16)/nameLabel(19)
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:16.0];
        NSDictionary *attributes = @{NSParagraphStyleAttributeName:style};
        NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:usernameStr attributes:attributes];
        cell.usernameLabel.attributedText = attributedString;
        
        
        usernameStr = [[self.followUsers objectAtIndex:currentRow] valueForKey:@"name"];
        [style setLineSpacing:19.0];
        NSDictionary *attributes2= @{NSParagraphStyleAttributeName:style};
        NSAttributedString * attributedString2 = [[NSAttributedString alloc] initWithString:usernameStr attributes:attributes2];
        cell.nameLabel.attributedText = attributedString2;
        
        cell.userImageView.hidden = YES;
        cell.topLine.hidden = YES;
        cell.userImageView.hidden = NO;
        debug NSLog(@"userImageView: x=%f, y=%f", cell.userImageView.frame.origin.x, cell.userImageView.frame.origin.y);
        debug NSLog(@"userImageView width:%f, height:%f", cell.userImageView.frame.size.width, cell.userImageView.frame.size.height);
        debug NSLog(@"cell rowHeight=%f", cell.frame.size.height);
        if ([[self.followUsers objectAtIndex:currentRow] valueForKey:@"picture"] != [NSNull null] && ![[[self.followUsers objectAtIndex:currentRow] valueForKey:@"picture"] isEqualToString:@"default"]) {
            [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.userImageView,
                                                 @"filename":[[self.followUsers objectAtIndex:currentRow] valueForKeyPath:@"picture"],
                                                 @"width":[NSNumber numberWithInt:cell.userImageView.frame.size.width],
                                                 @"height":[NSNumber numberWithInt:cell.userImageView.frame.size.height]}];
        }
    
        BOOL following =[[[self.followUsers objectAtIndex:currentRow] valueForKey:@"following"] boolValue];
        
        if (!following) {
            debug NSLog(@"not following %@", [[self.followUsers objectAtIndex:currentRow] valueForKeyPath:@"username"]);
            // Not follow - change action button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
            [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];

            [cell.actionButton setTag:kFollowButtonTag];
        } else {
            debug NSLog(@"yes following %@", [[self.followUsers objectAtIndex:currentRow] valueForKeyPath:@"username"]);
            UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
            [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
            [cell.actionButton setTag:kFollowingButtonTag];
        }
        
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.followUsers == nil || self.followUsers.count == 0) {
        return 120.0; // For the no following/no followers cell
    } else {
        return 65.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Notifications

- (void)uploadComplete:(NSNotification*)notification {
    debug NSLog(@"ProfileEdit-upload Complete");
    self.editedProfileImage = nil;
   // [self sendToTheServer];
}

- (void)uploadFailed:(NSNotification*)notification {
    debug NSLog(@"ProfileEdit-upload Failed");
    self.editedProfileImage = nil;
    [self hideActivity];
}


#pragma mark - TDFollowCellProfileDelegate

- (void)showActivity {
    //self.saveButton.enabled = NO;
    self.backButton.enabled = NO;
    self.activityIndicator.center = self.view.center;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
   // [self checkForSaveButton];
}

#pragma mark - TDFollowCellProfileDelegate
- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag{
    debug NSLog(@"TDFollowViewControllerDelegate: action button pressed with tag=%tu and row=%ld", tag, (long)row);
    debug NSLog(@"follow/unfollow--");
    self.currentRow = row;
    
    NSNumber *userId = nil;
    if(self.followUsers != nil) {
        userId = [[self.followUsers objectAtIndex:row] valueForKeyPath:@"id"];
        debug NSLog(@"going to follow user w/ id=%@", userId);
    }
    
    if (tag == kFollowButtonTag) {
        TDFollowProfileCell * cell;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentRow inSection:0];
        UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
        if(modifyCell != nil) {
            cell = (TDFollowProfileCell*)modifyCell;
            // Got the cell, change the button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
            [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
            [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
        }
        // Send follow user to server
        [[TDUserAPI sharedInstance] followUser:userId callback:^(BOOL success) {
            if (success) {
                debug NSLog(@"now following user=%@", userId);
            } else {
                debug NSLog(@"could not follow user=%@", userId);
                //TODO: Show toast view of error, TRY AGAIN
                // Switch button back
                if (cell != nil) {
                    // Got the cell, change the button
                    UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
                    [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
                    [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
                    [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];
                }
            }
        }];
    } else if (tag == kFollowingButtonTag) {
        debug NSLog(@"show confirmation");
        // TODO: UIActionSheet to confirm that we are unfollowing this person
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
        debug NSLog(@"going to unfollow user w/ id=%@", userId);
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
        }
        
        // Send unfollow user to server
        [[TDUserAPI sharedInstance] unFollowUser:userId callback:^(BOOL success) {
            if (success) {
                debug NSLog(@"now following user=%@", userId);
                
            } else {
                debug NSLog(@"could not follow user=%@", userId);
                //TODO: Display toast saying error processing, TRY AGAIN
                // Switch button back to cell
                UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
                [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
                [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
                [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
            }
        }];
    }

}

#pragma mark - TDNoFollowCellProfileDelegate
- (void)inviteButtonPressed {
    debug NSLog(@"inside TDFollowViewController:inviteButtonPressed");
    
}
- (void)findButtonPressed {
    debug NSLog(@"inside findButtonPressed");
    
}
@end
