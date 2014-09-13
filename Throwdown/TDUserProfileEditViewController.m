//
//  TDUserProfileEditViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileEditViewController.h"
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

@interface TDUserProfileEditViewController ()

@property (nonatomic) BOOL hasLoaded;
@property (nonatomic) NSDictionary *settings;

@end

@implementation TDUserProfileEditViewController

@synthesize profileUser;
@synthesize name;
@synthesize username;
@synthesize phone;
@synthesize email;
@synthesize password;
@synthesize bio;
@synthesize pictureFileName;
@synthesize fromProfileType;
@synthesize editedProfileImage;
@synthesize tempFlyInImageView;

- (void)dealloc {
    self.profileUser = nil;
    self.name = nil;
    self.username = nil;
    self.phone = nil;
    self.email = nil;
    self.password = nil;
    self.bio = nil;
    self.pictureFileName = nil;
    self.editedProfileImage = nil;
    self.tempFlyInImageView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    debug NSLog(@"EditUserProfile:%@", self.profileUser);

    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Title
    self.titleLabel.text = @"Edit Profile";
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
    self.saveButton.titleLabel.font = [TDConstants fontRegularSized:18.0];
    UIBarButtonItem *saveBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.saveButton];
    self.navigationItem.rightBarButtonItem = saveBarButton;

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    [[TDAPIClient sharedInstance] getUserSettings:[TDCurrentUser sharedInstance].authToken success:^(NSDictionary *settings) {
        self.hasLoaded = YES;
        if ([settings isKindOfClass:[NSDictionary class]]) {
            self.settings = settings;
            self.name = [settings objectForKey:@"name"];
            self.username = [settings objectForKey:@"username"];
            self.phone = [settings objectForKey:@"displayed_phone_number"];
            self.email = [settings objectForKey:@"displayed_email"];
            if ([settings objectForKey:@"bio"] == [NSNull null]) {
                self.bio = @"";
            } else {
                self.bio = [settings objectForKey:@"bio"];
            }

            if ([settings objectForKey:@"picture"] != [NSNull null] && ![[settings objectForKey:@"picture"] isEqualToString:@"default"]) {
                self.pictureFileName = [settings objectForKey:@"picture"];
            }
        }

        [self checkForSaveButton];
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

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    origTableViewFrame = self.tableView.frame;

    if (self.hasLoaded) {
        [self checkForSaveButton];
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

- (IBAction)saveButtonHit:(id)sender {
    [self hideKeyboard];
    [self showActivity];
    if (self.editedProfileImage) {
        self.activityIndicator.text.text = @"Uploading photo";
        [self uploadNewAvatarImage];
    } else {
        [self sendToTheServer];
    }
}

- (void)backButtonHit:(id)sender {
    [self leave];
}

- (void)sendToTheServer {
    self.activityIndicator.text.text = @"Saving";
    [[TDUserAPI sharedInstance] editUserWithName:self.name
                                           email:self.email
                                        username:self.username
                                           phone:self.phone
                                             bio:self.bio
                                         picture:self.pictureFileName
                                        callback:^(BOOL success, NSDictionary *dict) {
                                            [self hideActivity];

                                            if (success) {
                                                debug NSLog(@"EDIT SUCCESS:%@ %@", dict, self.editedProfileImage);

                                                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateWithUserChangeNotification object:nil];

                                                NSString *message;
                                                if (![self.phone isEqualToString:[self.settings objectForKey:@"displayed_phone_number"]]) {
                                                    message = [NSString stringWithFormat:@"Verification SMS sent to:\n%@\n", self.phone];
                                                }
                                                if (![self.email isEqualToString:[self.settings objectForKey:@"displayed_email"]]) {
                                                    message = [NSString stringWithFormat:@"%@Verification email sent to:\n%@\n", message ? message : @"", self.email];
                                                }
                                                if (message) {
                                                    message = [NSString stringWithFormat:@"%@Please verify to confirm your info.\n", message];
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                                                    message:message
                                                                                                   delegate:nil
                                                                                          cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil];
                                                    [alert show];
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationReloadHome object:nil];
                                                }

                                                [self leave];
                                            } else {
                                                debug NSLog(@"EDIT FAILURE:%@", dict);

                                                NSMutableString *message = [NSMutableString string];

                                                if ([dict objectForKey:@"name"]) {
                                                    [message appendFormat:@"%@", [self buildStringFromErrors:[dict objectForKey:@"name"] baseString:[NSString stringWithFormat:@"Name (%@)", self.name]]];
                                                }
                                                if ([dict objectForKey:@"username"]) {
                                                    [message appendFormat:@"%@", [self buildStringFromErrors:[dict objectForKey:@"username"] baseString:[NSString stringWithFormat:@"Username (%@)", self.username]]];
                                                }
                                                if ([dict objectForKey:@"phone_number"]) {
                                                    [message appendFormat:@"%@", [self buildStringFromErrors:[dict objectForKey:@"phone_number"] baseString:[NSString stringWithFormat:@"Phone (%@)", self.phone]]];
                                                }
                                                if ([dict objectForKey:@"email"]) {
                                                    [message appendFormat:@"%@", [self buildStringFromErrors:[dict objectForKey:@"email"] baseString:[NSString stringWithFormat:@"Email (%@)", self.email]]];
                                                }
                                                if ([dict objectForKey:@"bio"]) {

                                                    if (self.bio && [self.bio length] > 8) {    // make sure it's not too long for the alert
                                                        self.bio = [NSString stringWithFormat:@"%@...", [self.bio substringToIndex:7]];
                                                    }
                                                    [message appendFormat:@"%@", [self buildStringFromErrors:[dict objectForKey:@"bio"] baseString:[NSString stringWithFormat:@"Bio (%@)", self.bio]]];
                                                }

                                                message = [[message stringByReplacingOccurrencesOfString:@" ."
                                                                                              withString:@"."] mutableCopy];

                                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Error"
                                                                                                message:message
                                                                                               delegate:nil
                                                                                      cancelButtonTitle:@"OK"
                                                                                      otherButtonTitles:nil];
                                                [alert show];
                                                [self.tableView reloadData];
                                            }
                                        }];
}

- (NSString *)buildStringFromErrors:(NSArray *)array baseString:(NSString *)baseString {
    NSMutableString *returnString = [NSMutableString string];
    for (NSString *string in array) {
        [returnString appendFormat:@"%@ %@. ", baseString, string];
    }
    return returnString;
}

- (void)leave {
    switch (fromProfileType) {
        case kFromProfileScreenType_OwnProfile:
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        break;
        case kFromProfileScreenType_OwnProfileButton:
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
        case (800+10*1+0):
            self.phone = text;
            break;
        case (800+10*1+1):
            self.email = text;
            break;
        case (800+10*1+2):
            self.password = text;
            break;
        default:
            break;
    }

    [self checkForSaveButton];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateFieldsForTextField:textField text:textField.text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self updateFieldsForTextField:textField text:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    [self checkForSaveButton];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateFieldsForTextField:textField text:textField.text];
}

- (IBAction)textFieldDidChange:(id)sender {
    [self checkForSaveButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkForSaveButton];
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

#pragma mark - Validate phone
- (BOOL)validatePhone {
    NSError *error = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.phone error:&error];
    self.phone = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    if (!error && [phoneUtil isValidNumber:parsedPhoneNumber]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Check Save Button
- (BOOL)checkIfChanged {
    if (!self.hasLoaded) {
        // Don't allow saving if server failed
        return NO;
    }
    if ([self.phone length] > 0 && ![self validatePhone]) {
        return NO;
    }

    NSString *currentBio = [self.settings objectForKey:@"bio"];
    if (self.editedProfileImage != nil ||
        ([self.name length] > 0 && ![self.name isEqualToString:[self.settings objectForKey:@"name"]]) ||
        ([self.username length] > 0 && ![self.username isEqualToString:[self.settings objectForKey:@"username"]]) ||
        ([self.phone length] > 0 && ![self.phone isEqualToString:[self.settings objectForKey:@"displayed_phone_number"]]) ||
        (![self.bio isEqualToString:(currentBio ? currentBio :  @"")]) ||
        ([self.email length] > 0 && ![self.email isEqualToString:[self.settings objectForKey:@"displayed_email"]]))
    {
        return YES;
    }

    return NO;
}

- (void)checkForSaveButton {
    if ([self checkIfChanged]) {
        self.saveButton.enabled = YES;
    } else {
        self.saveButton.enabled = NO;
    }
}

#pragma mark - TextView
- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.bio = textView.text;
    [self checkForSaveButton];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.bio = textView.text;
    [self checkForSaveButton];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.bio = textView.text;
    [self checkForSaveButton];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Too long?
    if ([[textView.text stringByReplacingCharactersInRange:range withString:text] length] > 200) {
        return NO;
    }

    self.bio = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self checkForSaveButton];
    return YES;
}

#pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 89892 && buttonIndex == 0) {
        switch (fromProfileType) {
            case kFromProfileScreenType_OwnProfile:
                [self.navigationController popViewControllerAnimated:YES];
            break;
            
            default:
            break;
        }
    }
}

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
    switch (section) {
        case 1:
        case 0:
        case 2:
        case 3:
        case 4:
            return 40;
        break;
        default:
            return 0.;
        break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0: // profile
            return 5;
            break;
        case 1: // private
            return 2;
            break;
        case 2: // push / social / password
            return 3;
            break;
        case 3: // app rate / buy shirt
            return 2;
            break;
        case 4: // log out
            return 1;
            break;
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    TDUserEditCell *cell = (TDUserEditCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_EDITPROFILE];

    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_EDITPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textField.delegate = self;
        cell.textView.delegate = self;
    }

    cell.titleLabel.hidden = YES;
    cell.longTitleLabel.hidden = YES;
    cell.middleLabel.hidden = YES;
    cell.userImageView.hidden = YES;
    cell.topLine.hidden = YES;
    cell.textField.hidden = YES;
    cell.textField.secureTextEntry = NO;
    cell.leftMiddleLabel.hidden = YES;
    cell.textView.hidden = YES;
    cell.textField.tag = 800+(10*indexPath.section)+indexPath.row;
    UIColor *textFieldPlaceHolderColor = [TDConstants headerTextColor];
    cell.textView.frame = cell.textViewdOrigRect;
    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                       cell.bottomLineOrigY,
                                       cell.bottomLine.frame.size.width,
                                       cell.bottomLine.frame.size.height);

    switch (indexPath.section) {
        case 0: // profile settings
            switch (indexPath.row) {
                case 0:
                    cell.userImageView.hidden = NO;
                    if (self.editedProfileImage) {
                        cell.userImageView.image = self.editedProfileImage;
                    } else if (self.pictureFileName) {
                        [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.userImageView,
                                                                 @"filename":self.pictureFileName,
                                                                 @"width":[NSNumber numberWithInt:cell.userImageView.frame.size.width],
                                                                 @"height":[NSNumber numberWithInt:cell.userImageView.frame.size.height]}];
                    }
                    cell.topLine.hidden = NO;
                    cell.leftMiddleLabel.hidden = NO;
                    cell.leftMiddleLabel.text = @"Edit Photo";
                    CGRect labelFrame = cell.leftMiddleLabel.frame;
                    labelFrame.origin.x = 100;
                    cell.leftMiddleLabel.frame = labelFrame;
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    break;
                case 1:
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"name"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Name";
                    cell.textField.text = self.name;
                    CGRect cellFrame = cell.textField.frame;
                    cellFrame.origin.x = 100;
                    cell.textField.frame = cellFrame;
                    break;
                case 2:
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"username"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Username";
                    cell.textField.text = self.username;
                    CGRect fieldFrame = cell.textField.frame;
                    cellFrame.origin.x = 100;
                    cell.textField.frame = fieldFrame;
                    break;
                case 3:
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;

                    cell.titleLabel.text = @"Location";
                    cell.textField.text = @"San Francisco";
                    cell.textField.textColor = [TDConstants commentTextColor];
                    break;
                    
                case 4:
                    cell.titleLabel.hidden = NO;
                    cell.textView.hidden = NO;
                    cell.titleLabel.text = @"Bio";
                    cell.textView.text = self.bio;
                    CGRect newTextFrame = cell.textView.frame;
                    newTextFrame.size.height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
                    newTextFrame.origin.x = 100;
                    cell.textView.frame = newTextFrame;
                    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                                       CGRectGetMaxY(newTextFrame),
                                                       cell.bottomLine.frame.size.width,
                                                       cell.bottomLine.frame.size.height);

                    break;
                default:
                    break;
            }
        break;

        case 1: // Private information
            switch (indexPath.row) {
                case 0:
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"phone"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Phone";
                    cell.textField.text = self.phone;
                    cell.topLine.hidden = NO;
                    cell.textField.keyboardType = UIKeyboardTypePhonePad;
                break;
                case 1:
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"example@email.com"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Email";
                    cell.textField.text = self.email;
                break;
                default:
                    break;
            }
        break;

        case 2: // Settings
            switch (indexPath.row) {
                case 0:
                    cell.topLine.hidden = NO;
                    cell.longTitleLabel.hidden = NO;
                    cell.longTitleLabel.text = @"Push Notifications";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.topLine.hidden = YES;
                    cell.longTitleLabel.hidden = NO;
                    cell.longTitleLabel.text = @"Social Networks";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 2:
                    cell.topLine.hidden = YES;
                    cell.longTitleLabel.hidden = NO;
                    cell.longTitleLabel.text = @"Change Password";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    cell.topLine.hidden = NO;
                    cell.longTitleLabel.hidden = NO;
                    cell.longTitleLabel.text = @"Buy a Throwdown T-Shirt";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.topLine.hidden = YES;
                    cell.longTitleLabel.hidden = NO;
                    cell.longTitleLabel.text = @"Rate Throwdown in App Store";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;

        case 4: // Log out
            switch (indexPath.row) {
                case 0:
                    cell.topLine.hidden = NO;
                    cell.middleLabel.hidden = NO;
                    cell.middleLabel.text = @"Log Out";
                    cell.middleLabel.textColor = [TDConstants brandingRedColor]; //TODO: #4c4c4c is grey but spec shows red
                    debug NSLog(@"debug height=%f", cell.middleLabel.frame.size.height);
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    break;
            }
        break;
        default:
            break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 && indexPath.row == 4 ? 90.0 : 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: // PHOTO
                    [self hideKeyboard];
                    [self showPhotoActionSheet];
                    break;
                case 1:
                    break;
                case 2:
                    break;
                default:
                    break;
            }
            break;

        case 2:
            switch (indexPath.row) {
                case 0: // Edit Push
                    [self gotoEditPushNotifications];
                    break;
                case 1:
                    [self showSocialNetworks];
                    break;
                case 2:
                    [self showEditPassword];
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0: {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/store", [TDConstants getBaseURL]]];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
                    break;
                case 1:
                    [self gotoRateAppLink];
                    break;
                  default:
                    break;
            }
        break;
        case 4:
            [self hideKeyboard];
            switch (indexPath.row) {
                case 0: {
                    // Log Out
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log out?" message:nil delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                    [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        if (buttonIndex != alertView.cancelButtonIndex) {
                            [[TDUserAPI sharedInstance] logout];
                            [self showWelcomeController];
                        }
                    }];
                }
                break;
                default:
                    break;
            }
        break;
        default:
            break;
    }
}

#pragma mark - Edit Password
- (void)showSocialNetworks {
    TDSocialNetworksViewController *vc = [[TDSocialNetworksViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Edit Password
- (void)showEditPassword {
    TDUserPasswordEditViewController *vc = [[TDUserPasswordEditViewController alloc] initWithNibName:@"TDUserPasswordEditViewController" bundle:nil ];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Rate App Link
- (void)gotoRateAppLink {
    NSLog(@"Inside gotoRateAppLink");
    debug NSLog(@"===>Inside toastNotificationTappedRateUs for iRate");
    //mark as rated
    [iRate sharedInstance].ratedThisVersion = YES;
    
    //launch app store
    [[iRate sharedInstance] openRatingsPageInAppStore];
    //[NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? //iOS7AppStoreURLFormat: iOSAppStoreURLFormat, APP_STORE_ID]]; // Would contain the right link
}

#pragma mark - Log Out
- (void)showWelcomeController {
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Photo
- (void)showPhotoActionSheet {
    // ActionSheet
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Choose Photo", nil];
        actionSheet.tag = 3556;
        [actionSheet showInView:self.view];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Take Photo", @"Choose Photo", nil];
        actionSheet.tag = 3557;
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 3556) {
        switch (buttonIndex) {
            case 0: // Choose Photo
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                break;
            default:
                break;
        }
    }

    if (actionSheet.tag == 3557) {
        switch (buttonIndex) {
            case 0: // Take Photo
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                break;
            case 1: // Choose Photo
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                break;
            default:
                break;
        }
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.allowsEditing = YES;
    imagePickerController.delegate = self;

    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.showsCameraControls = YES;
    }

    [self presentViewController:imagePickerController
                       animated:YES
                     completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (self.tempFlyInImageView && [self.tempFlyInImageView superview]) {
        [self.tempFlyInImageView removeFromSuperview];
    }

    UIImage *image = [info valueForKey:UIImagePickerControllerEditedImage];

    // Scale to 140x140
    CGFloat shorterSide = image.size.width < image.size.height ? image.size.width : image.size.height;
    image = [image cropToSize:CGSizeMake(shorterSide, shorterSide) usingMode:NYXCropModeCenter];
    image = [image scaleToSize:CGSizeMake(140.0, 140.0) usingMode:NYXResizeModeScaleToFill];
    self.editedProfileImage = image;

    // Need to figure out where the avatar image is on the screen
    TDUserEditCell *cell = (TDUserEditCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                     inSection:0]];
    CGRect avatarImageFrame = CGRectMake(cell.frame.origin.x+cell.userImageView.frame.origin.x,
                                         cell.frame.origin.y+cell.userImageView.frame.origin.y+self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height,
                                         cell.userImageView.frame.size.width,
                                         cell.userImageView.frame.size.height);

    // Get rid of photo picker
    [self dismissViewControllerAnimated:NO
                             completion:^{
                                 // Add big in center
                                 self.tempFlyInImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0,
                                                                                                         0.0,
                                                                                                         image.size.width,
                                                                                                         image.size.height)];
                                 self.tempFlyInImageView.image = image;
                                 self.tempFlyInImageView.center = self.view.center;
                                 [self.view addSubview:self.tempFlyInImageView];

                                 [UIView animateWithDuration: 0.3
                                                       delay: 0.0
                                                     options: UIViewAnimationOptionCurveEaseOut
                                                  animations:^{
                                                      self.tempFlyInImageView.frame = avatarImageFrame;
                                                  }
                                                  completion:^(BOOL animDone){
                                                      if (animDone) {
                                                          [self.tempFlyInImageView removeFromSuperview];
                                                          self.tempFlyInImageView = nil;
                                                          [self.tableView reloadData];
                                                      }
                                                  }];

    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Upload Avatar Image

- (void)uploadNewAvatarImage {
    // Filename
    NSString *filename = [NSString stringWithFormat:@"%@.jpg", [TDPostAPI createUploadFileNameFor:[TDCurrentUser sharedInstance]]];
    self.pictureFileName = filename;

    debug NSLog(@"uploadNewAvatarImage:%@", filename);

    // Save to temp place
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", filename]];

    UIImage *image = self.editedProfileImage;
    if (image.imageOrientation == UIImageOrientationRight) {
        image = [image rotateInDegrees:-90.0];
    } else if (image.imageOrientation == UIImageOrientationDown) {
        image = [image rotateInDegrees:-180.0];
    } else if (image.imageOrientation == UIImageOrientationLeft) {
        image = [image rotateInDegrees:-90.0];
    }

    [self saveAvatarImageTo:filePath image:image];
    [[TDUserAPI sharedInstance] uploadAvatarImage:filePath withName:filename];
}

- (void)saveAvatarImageTo:(NSString *)filePath image:(UIImage *)image {
    unlink([filePath UTF8String]); // If a file already exists
    [UIImageJPEGRepresentation(image, .97f) writeToFile:filePath atomically:YES];
}

#pragma mark - Notifications

- (void)uploadComplete:(NSNotification*)notification {
    debug NSLog(@"ProfileEdit-upload Complete");
    self.editedProfileImage = nil;
    [self sendToTheServer];
}

- (void)uploadFailed:(NSNotification*)notification {
    debug NSLog(@"ProfileEdit-upload Failed");
    self.editedProfileImage = nil;
    [self hideActivity];
}

#pragma mark - Edit Push Notifications
- (void)gotoEditPushNotifications {
    TDUserPushNotificationsEditViewController *vc = [[TDUserPushNotificationsEditViewController alloc] initWithNibName:@"TDUserPushNotificationsEditViewController" bundle:nil ];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Activity
- (void)showActivity {
    self.saveButton.enabled = NO;
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
    [self checkForSaveButton];
}

@end
