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

@interface TDUserProfileEditViewController ()

@end

@implementation TDUserProfileEditViewController

@synthesize profileUser;
@synthesize name;
@synthesize username;
@synthesize phone;
@synthesize email;
@synthesize password;
@synthesize fromFrofileType;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    self.profileUser = nil;
    self.name = nil;
    self.username = nil;
    self.phone = nil;
    self.email = nil;
    self.password = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"UserProfile:%@", self.profileUser);

    origTableViewFrame = self.tableView.frame;
    statusBarFrame = [self.view convertRect: [UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.text = @"Edit Profile";
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:20.0];
    [self.navigationItem setTitleView:self.titleLabel];

    // Buttons
    self.saveButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:18.0];
    self.closeButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:18.0];
    self.closeButton.titleLabel.textColor = [TDConstants headerTextColor];

    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.saveButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    self.saveButton.enabled = NO;
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    self.closeButton.enabled = YES;

    [self checkForSaveButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(IBAction)saveButtonHit:(id)sender
{
    NSLog(@"saveButtonHit");
}

-(IBAction)closeButtonHit:(id)sender
{
    if ([self checkIfChanged]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit"
                                                        message:@"Are you sure you want to\nlose your edits?"
                                                       delegate:self
                                              cancelButtonTitle:@"Yes"
                                              otherButtonTitles:@"No", nil];
        alert.tag = 89892;
        [alert show];

    } else {
        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:nil];
    }
}

#pragma mark - Keyboard / Textfield
-(void)updateFieldsForTextField:(UITextField *)textfield text:(NSString *)text
{
    // 800+(10*indexPath.section)+indexPath.row;
    switch (textfield.tag) {
        case (800+10*0+1):
        {
            self.name = text;
        }
        break;
        case (800+10*0+2):
        {
            self.username = text;
        }
        break;
        case (800+10*1+0):
        {
            self.phone = text;
        }
        break;
        case (800+10*1+1):
        {
            self.email = text;
        }
        break;
        case (800+10*1+2):
        {
            self.password = text;
        }
        break;

        default:
        break;
    }

    NSLog(@"%@ %@ %@ %@ %@", self.name, self.username, self.phone, self.email, self.password);

    [self checkForSaveButton];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self updateFieldsForTextField:textField text:textField.text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self updateFieldsForTextField:textField text:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateFieldsForTextField:textField text:textField.text];
}

-(IBAction)textFieldDidChange:(id)sender
{
    [self checkForSaveButton];
}

-(BOOL)checkIfChanged
{
    return YES; // temp
}

-(void)checkForSaveButton
{
    if ([self.name length] > 0 &&
        [self.username length] > 0 &&
        [self.phone length] > 0 &&
        [self.email length] > 0 &&
        [self.password length] > 0)
    {
        self.saveButton.enabled = YES;
    }
    else
    {
        self.saveButton.enabled = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (self.saveButton.enabled)
    {
        [self saveButtonHit:nil];
        return NO;
    }
    else
    {
    }

    [self checkForSaveButton];
    return YES;
}

- (void)keyboardWillHide:(NSNotification *)n
{
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

- (void)keyboardWillShow:(NSNotification *)n
{
    if (keybdUp) {
        return;
    }

    NSDictionary* userInfo = [n userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // resize the table
    CGRect tableViewNewFrame = origTableViewFrame;
    tableViewNewFrame.size.height -= keyboardSize.height-self.navigationController.navigationBar.frame.size.height-statusBarFrame.size.height;

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

-(void)hideKeyboard
{
    for (TDUserEditCell *cell in self.tableView.visibleCells) {
        if ([cell.textField isFirstResponder]) {
            [cell.textField resignFirstResponder];
        }
    }
}

#pragma mark - AlertView
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 89892 && buttonIndex == 0) // Leave
    {
        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:nil];
    }
}

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        self.sectionHeaderLabel.text = @"PRIVATE INFORMATION";
        self.sectionHeaderLabel.font = [UIFont fontWithName:TDFontProximaNovaSemibold size:15.0];
        self.sectionHeaderLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                      0.0,
                                                                      self.view.frame.size.width,
                                                                      self.sectionHeaderLabel.frame.size.height)];
        CGRect headerLabelFrame = self.sectionHeaderLabel.frame;
        headerLabelFrame.origin.x = 12.0;
        self.sectionHeaderLabel.frame = headerLabelFrame;
        [headerView addSubview:self.sectionHeaderLabel];
        return headerView;
    }

    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            return 5.0;
        }
        break;
        case 1:
        {
            return self.sectionHeaderLabel.frame.size.height;
        }
        break;
        case 2:
        {
            return 0.0;
        }
        break;

        default:
        break;
    }

    return 0.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3; // User name, photo + phone, email, password + log out
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
        {
            return 3;
        }
        break;
        case 1:
        {
            return 3;
        }
        break;
        case 2:
        {
            return 1;
        }
        break;

        default:
        break;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    TDUserEditCell *cell = (TDUserEditCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_EDITPROFILE];

    if (!cell) {

        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_EDITPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textField.delegate = self;
    }

    cell.titleLabel.hidden = YES;
    cell.middleLabel.hidden = YES;
    cell.userImageView.hidden = YES;
    cell.topLine.hidden = YES;
    cell.textField.hidden = YES;
    cell.textField.secureTextEntry = NO;
    cell.leftMiddleLabel.hidden = YES;
    cell.textField.tag = 800+(10*indexPath.section)+indexPath.row;
    UIColor *textFieldPlaceHolderColor = [UIColor colorWithRed:(189.0/255.0) green:(189.0/255.0) blue:(189.0/255.0) alpha:1.0];;

    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell.userImageView.hidden = NO;
                    cell.topLine.hidden = NO;
                    cell.leftMiddleLabel.hidden = NO;
                    cell.leftMiddleLabel.text = @"Edit Photo";
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                }
                break;
                case 1:
                {
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"name"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Name";
                    cell.textField.text = self.name;
                }
                break;
                case 2:
                {
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"username"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Username";
                    cell.textField.text = self.username;
                }
                break;
                
                default:
                break;
            }
        }
        break;
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"phone"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Phone";
                    cell.textField.text = self.phone;
                    cell.topLine.hidden = NO;
                }
                break;
                case 1:
                {
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"example@email.com"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Email";
                    cell.textField.text = self.email;
                }
                break;
                case 2:
                {
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"password"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.textField.secureTextEntry = YES;
                    cell.titleLabel.text = @"Password";
                    cell.textField.text = self.password;
                }
                break;

                default:
                break;
            }
        }
        break;
        case 2:
        {
            // Log Out
            cell.topLine.hidden = NO;
            cell.middleLabel.hidden = NO;
            cell.middleLabel.text = @"Log Out";
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        break;

        default:
        break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];


}

@end
