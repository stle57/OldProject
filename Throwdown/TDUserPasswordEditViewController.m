//
//  TDUserPasswordEditViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserPasswordEditViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDUserAPI.h"
#import "NBPhoneNumberUtil.h"

@implementation TDUserPasswordEditViewController

@synthesize profileUser;
@synthesize password1;
@synthesize current;
@synthesize password2;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.profileUser = nil;
    self.password1 = nil;
    self.password2 = nil;
    self.current = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    debug NSLog(@"UserProfile:%@", self.profileUser);

    statusBarFrame = [self.view convertRect: [UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.text = @"Edit Password";
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:20.0];
    [self.navigationItem setTitleView:self.titleLabel];

    // Buttons
    self.doneButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:18.0];

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

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    origTableViewFrame = self.tableView.frame;
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];
    self.navigationItem.rightBarButtonItem = doneBarButton;
    self.doneButton.enabled = NO;

    [self checkForSaveButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)leave {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonHit:(id)sender {
    // Changed?
    if ([self checkIfChanged]) {
        [self sendToTheServerNewPassword];
    } else {
        [self leave];
    }
}

- (void)backButtonHit:(id)sender {
    [self hideKeyboard];
    [self leave];
}

- (void)sendToTheServerNewPassword {
    [self hideKeyboard];

    self.activityIndicator.text.text = @"Saving…";
    [self showActivity];

    [[TDUserAPI sharedInstance] changePasswordFrom:self.current
                                       newPassword:self.password1
                                   confirmPassword:self.password2
                                          callback:^(BOOL success, NSDictionary *dict) {
                                              [self hideActivity];
                                              if (success) {
                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Changed"
                                                                                                  message:@"Your password was successfully changed."
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                                  [alert show];
                                                  [self leave];

                                              } else {

                                                  NSMutableString *message = [NSMutableString string];
                                                  // Current
                                                  if ([dict objectForKey:@"current_password"] && [[dict objectForKey:@"current_password"] isKindOfClass:[NSArray class]]) {
                                                      NSArray *currentArray = [dict objectForKey:@"current_password"];
                                                      if ([currentArray count] > 0) {
                                                          [message appendString:@"Current password "];
                                                      }
                                                      for (NSString *string in currentArray) {
                                                          [message appendFormat:@"%@, ", string];
                                                      }
                                                  }

                                                  // Remove last 2
                                                  if ([message length] > 2) {
                                                      message = [[message substringToIndex:[message length]-2] mutableCopy];
                                                      [message appendString:@". "];
                                                  }

                                                  // New password
                                                  if ([dict objectForKey:@"password"] && [[dict objectForKey:@"password"] isKindOfClass:[NSArray class]]) {
                                                      NSArray *currentArray = [dict objectForKey:@"password"];
                                                      if ([currentArray count] > 0) {
                                                          if ([message length] > 0) {
                                                              [message appendString:@"\nNew password "];
                                                          } else {
                                                              [message appendString:@"New password "];
                                                          }
                                                      }
                                                      for (NSString *string in currentArray) {
                                                          [message appendFormat:@"%@, ", string];
                                                      }
                                                  }

                                                  // Remove last 2
                                                  if ([message length] > 2) {
                                                      message = [[message substringToIndex:[message length]-2] mutableCopy];
                                                      [message appendString:@". "];
                                                  }

                                                  if (!message || [message length] == 0) {
                                                      message = [@"Couldn't connect to server" mutableCopy];
                                                  }

                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Edit"
                                                                                                  message:message
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                                  [alert show];
                                              }
                                          }];
    
}

-(NSString *)buildStringFromErrors:(NSArray *)array baseString:(NSString *)baseString {
    NSMutableString *returnString = [NSMutableString string];
    for (NSString *string in array) {
        [returnString appendFormat:@"%@ %@. ", baseString, string];
    }
    return returnString;
}

#pragma mark - Keyboard / Textfield
-(void)updateFieldsForTextField:(UITextField *)textfield text:(NSString *)text {
    // 800+(10*indexPath.section)+indexPath.row;
    switch (textfield.tag) {
        case (800+10*0+0):
            self.current = text;
            break;
        case (800+10*1+0):
            self.password1 = text;
            break;
        case (800+10*1+1):
            self.password2 = text;
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
    [self checkIfChanged];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateFieldsForTextField:textField text:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self checkIfChanged]) {
        [self doneButtonHit:nil];
        return NO;
    }

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
                         if (done) {
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
    if ([self.current length] > 0 &&
        [self.password1 length] > 0 &&
        [self.password1 isEqualToString:self.password2]) {
        return YES;
    }

    return NO;
}

- (void)checkForSaveButton {
    if ([self checkIfChanged]) {
        self.doneButton.enabled = YES;
    } else {
        self.doneButton.enabled = NO;
    }
}

#pragma mark - AlertView
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
}

#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Existing, Edit
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
            return 1;
        break;
        case 1:
            return 2;
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
    UIColor *textFieldPlaceHolderColor = [UIColor colorWithRed:(189.0/255.0) green:(189.0/255.0) blue:(189.0/255.0) alpha:1.0];
    cell.textView.frame = cell.textViewdOrigRect;
    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                       [self tableView:self.tableView heightForRowAtIndexPath:indexPath],
                                       cell.bottomLine.frame.size.width,
                                       cell.bottomLine.frame.size.height);

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.topLine.hidden = NO;
                    cell.titleLabel.hidden = NO;
                    cell.textField.hidden = NO;
                    cell.textField.secureTextEntry = YES;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Your current password"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Current";
                    cell.textField.text = self.current;
                break;
                default:
                break;
            }
        break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.topLine.hidden = NO;
                    cell.titleLabel.hidden = NO;
                    cell.textField.secureTextEntry = YES;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"New password"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"New";
                    cell.textField.text = self.password1;
                break;
                case 1:
                    cell.titleLabel.hidden = NO;
                    cell.textField.secureTextEntry = YES;
                    cell.textField.hidden = NO;
                    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Confirm new password"
                                                                                           attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor}];
                    cell.titleLabel.text = @"Confirm";
                    cell.textField.text = self.password2;
                break;
                default:
                break;
            }
        break;

        default:
        break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Activity

- (void)showActivity {
    self.doneButton.enabled = NO;
    self.backButton.enabled = NO;
    self.activityIndicator.center = self.view.center;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.doneButton.enabled = YES;
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

@end
