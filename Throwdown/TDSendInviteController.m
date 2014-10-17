//
//  TDSendInviteController.m
//  Throwdown
//
//  Created by Stephanie Le on 9/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSendInviteController.h"
#import "TDUserEditCell.h"
#import "TDAPIClient.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#import "TDViewControllerHelper.h"

@interface TDSendInviteController ()
@property NSMutableArray *contactList;
@end

static NSString *header1Text =@"Please confirm how you'd like your\nname to appear to your friends.";
static NSString *header2Text1 =@"Suggestion: use your first and last name";
static NSString *header2Text2 = @"Tap \"Send\" to send your invites!";

@implementation TDSendInviteController
@synthesize sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contactList = [[NSMutableArray alloc] init];
        self.headerLabels = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBarStyle:UIBarStyleBlack];
    navigationBar.translucent = NO;
    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    self.sendButton.titleLabel.textColor = [UIColor whiteColor];
    self.sendButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.sendButton sizeToFit];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton]; // NextButton
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    // Title
    self.titleLabel.text = @"Invite Friends";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleLabel sizeToFit];
    [self.navigationItem setTitleView:self.titleLabel];
    
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.width = SCREEN_WIDTH;
    self.tableView.frame = tableViewFrame;
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    _tapGesture.enabled = NO;
    [self.view addGestureRecognizer:_tapGesture];

}

- (void)dealloc {
    self.contactList = nil;
    self.sender = nil;
    self.headerLabels = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendButtonHit:(id)sender {
    debug NSLog(@"send invitation to users");
    // Get the name of the sender
    NSString *senderName = [self getSenderName];
    if (senderName.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Name cannot be blank."
                                                        message:@"We suggest entering your first\nand last names."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        // Get the list
        [self hideKeyboard];
        self.activityIndicator.text.text = @"Sending...";
        NSArray *sentContacts = [self contacts];
        [self showActivity];
        [[TDAPIClient sharedInstance] sendInvites:senderName contactList:sentContacts callback:^(BOOL success, NSArray *contacts)
        {
            debug NSLog(@"waiting on callback");
            if (success) {
                NSMutableArray *newList = [[NSMutableArray alloc] init];
                debug NSLog(@"contacts=%@", contacts);
                for (id temp in contacts) {
                    debug NSLog(@"objectAtIndex:1=%@", [temp objectAtIndex:1]);
                    if (![[temp objectAtIndex:1] boolValue]) {
                        NSString *info = [temp objectAtIndex:0];
                        debug NSLog(@"look for info%@", info);
                        for (id s in sentContacts) {
                            debug NSLog(@"s=%@", s);
                            if ([s allKeysForObject:info]){
                                [newList addObject:s];
                                break;
                            }
                        }
                    }
                }
                if (!newList.count) {
                    debug NSLog(@"successfully send to %@", contacts);
                    [self hideActivity];
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    [[TDAppDelegate appDelegate] showToastWithText:@"Invites sent successfully!" type:kToastType_InviteSent payload:nil delegate:nil];
                    [[TDAnalytics sharedInstance] logEvent:@"invites_sent"];
                } else {
                    [self hideActivity];
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    [[TDAppDelegate appDelegate] showToastWithText:@"Invites failed.  Tap here to retry" type:kToastType_InviteWarning payload:@{@"senderName":senderName, @"retryList":newList} delegate:[TDAPIClient toastControllerDelegate]];
                }
            } else {
                [self hideActivity];
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                [[TDAppDelegate appDelegate] showToastWithText:@"Invites failed.  Tap here to retry" type:kToastType_InviteWarning payload:@{@"senderName":senderName, @"retryList":sentContacts} delegate:[TDAPIClient toastControllerDelegate]];
            }
        }];
    }
}

- (NSString*)getSenderName {
    NSString *name = nil;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(modifyCell != nil) {
        TDUserEditCell * cell = (TDUserEditCell*)modifyCell;
        // Got the cell, change the button
        name = cell.textField.text;
    }

    return name;
}

- (void)showActivity {
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

- (NSArray *)contacts {
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (id tempObject in self.contactList) {
        NSString *idString = @"";
        if ([tempObject valueForKey:@"id"] != nil) {
            idString = [tempObject valueForKey:@"id"];
        }
        
        debug NSLog(@"idString-%@", idString);
        NSDictionary *dictionary = @{@"first_name":[tempObject valueForKey:@"firstName"], @"last_name":[tempObject valueForKey:@"lastName"],
                                     @"address_book_id":idString, @"info":[tempObject valueForKey:@"selectedData"],
                                     @"info_kind":([self convertInviteType:[tempObject valueForKey:@"inviteType"] ])};
        [array addObject:dictionary];
    }
    return array;
}

- (NSString*)convertInviteType:(id)inviteType {
    NSString *inviteString = [NSString alloc];
    switch([inviteType intValue]) {
        case kInviteType_Email:
            inviteString = @"email";
            break;
        case kInviteType_Phone:
            inviteString = @"phone";
            break;
        case kInviteType_None:
            inviteString =  @"";
            break;
        default:
            inviteString = @"";
            break;
    }
    return inviteString;
}

- (void) createHeaderLabels:(NSInteger)section {
    switch (section) {
        case 0: //Top header label
        {
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, SCREEN_WIDTH, 100)];
            CGFloat lineHeight = 21.0;
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:header1Text font:[TDConstants fontRegularSized:17] color:[TDConstants headerTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/17.0)];
            
            [topLabel setTextAlignment:NSTextAlignmentCenter];
            [topLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [topLabel sizeToFit];
            
            CGRect frame = topLabel.frame;
            frame.origin.x = SCREEN_WIDTH/2 - topLabel.frame.size.width/2;
            topLabel.frame = frame;
            
            if ([self.headerLabels count] == 0) {
                [self.headerLabels insertObject:topLabel atIndex:section];
            } else {
                [self.headerLabels replaceObjectAtIndex:section withObject:topLabel];
            }

        }
        break;
        case 1: //Suggestion label
        {
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, 11, SCREEN_WIDTH, 100)];
            CGFloat lineHeight = 14;
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:header2Text1 font:[TDConstants fontRegularSized:14.0] color:[TDConstants helpTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/14.0)];
            
            [topLabel setNumberOfLines:1];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [topLabel sizeToFit];
            
            if([self.headerLabels count] == 1) {
                [self.headerLabels insertObject:topLabel atIndex:section];
            }
        }
        break;
        case 2: //Tap Send label
        {
            if ([self.headerLabels count] ==2) {
                UILabel *topLabel = [self.headerLabels objectAtIndex:section-1];
                
                UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, topLabel.frame.origin.y + topLabel.frame.size.height + MIDDLE_MARGIN_HEADER2, SCREEN_WIDTH, 100)];
                CGFloat lineHeight = 17.0;
                NSAttributedString *bottomAttString = [TDViewControllerHelper makeParagraphedTextWithString:header2Text2 font:[TDConstants fontSemiBoldSized:17.0] color:[TDConstants headerTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/17.0)];
                
                [bottomLabel setTextAlignment:NSTextAlignmentCenter];
                [bottomLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [bottomLabel setAttributedText:bottomAttString];
                [bottomLabel setNumberOfLines:0];
                [bottomLabel sizeToFit];
                
                CGRect frame = bottomLabel.frame;
                frame.origin.x = SCREEN_WIDTH/2 - bottomLabel.frame.size.width/2;
                bottomLabel.frame = frame;

                if([self.headerLabels count] == 2) {
                    [self.headerLabels insertObject:bottomLabel atIndex:section];
                }
            }
        }
        break;
        default: break;
    }
}
#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            UILabel *topLabel = [self.headerLabels objectAtIndex:section];
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, TOP_BOTTOM_HEADER1_MARGIN + topLabel.frame.size.height + TOP_BOTTOM_HEADER1_MARGIN)];
            [headerView addSubview:topLabel];
            
            return headerView;
        }
        break;
    
        case 1: {
            UILabel *topLabel = [self.headerLabels objectAtIndex:section];
            UILabel *bottomLabel = [self.headerLabels objectAtIndex:section+1];
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, TOP_MARGIN_HEADER2 + topLabel.frame.size.height + MIDDLE_MARGIN_HEADER2 + bottomLabel.frame.size.height)];
            [headerView addSubview:topLabel];
            [headerView addSubview:bottomLabel];
            return  headerView;
        }
        break;
        default:
            break;
    }
    return nil;
 }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0: // name to send info for
            return 1;
            break;
        case 1: //
            return 0;
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 44.0;
            break;
        case 1:
            return 0;
            break;
        case 2:
            return 65.0;
            break;
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == 0) {
        static NSString *CellIdentifier = CELL_IDENTIFIER_EDITPROFILE;
        TDUserEditCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_EDITPROFILE];
        
        if (cell == nil) {
            cell = [[TDUserEditCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_EDITPROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textField.delegate = self;
        }
        cell.rightArrow.hidden = YES;
        cell.titleLabel.hidden = YES;
        cell.longTitleLabel.hidden = YES;
        cell.middleLabel.hidden = YES;
        cell.userImageView.hidden = YES;
        cell.topLine.hidden = YES;
        cell.textField.hidden = YES;
        cell.textField.secureTextEntry = NO;
        cell.leftMiddleLabel.hidden = YES;
        cell.textView.hidden = YES;
        cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                           cell.bottomLineOrigY,
                                           cell.bottomLine.frame.size.width,
                                           cell.bottomLine.frame.size.height);
        cell.titleLabel.hidden = NO;
        cell.textField.hidden = NO;
        cell.titleLabel.text = @"Name";
        cell.textField.text = self.sender; 
        CGRect cellFrame = cell.textField.frame;
        cellFrame.origin.x = 100;
        cell.textField.frame = cellFrame;
        cell.topLine.hidden = NO;

        return cell;
    } else {
        return nil;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            [self createHeaderLabels:section];
            UILabel *label = [self.headerLabels objectAtIndex:section];
            return TOP_BOTTOM_HEADER1_MARGIN + label.frame.size.height + TOP_BOTTOM_HEADER1_MARGIN;
        }
        break;
        case 1:
        {
            [self createHeaderLabels:section];
            [self createHeaderLabels:section+1];
            if ([self.headerLabels count] == 3) {
                UILabel *topLabel = [self.headerLabels objectAtIndex:section];
                UILabel *bottomLabel = [self.headerLabels objectAtIndex:section+1];
                 return TOP_MARGIN_HEADER2 + topLabel.frame.size.height + MIDDLE_MARGIN_HEADER2 + bottomLabel.frame.size.height;
            } else {
                return 0.;
            }
           
        }
        break;
        default:
            return 0.;
            break;
    }
}

# pragma mark - setting data from previous controller

- (void)setValuesForSharing:(NSArray *)contacts senderName:(NSString*)senderName{
    self.sender = senderName;
    [self.contactList addObjectsFromArray:contacts];
}

- (IBAction)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    for (TDUserEditCell *cell in self.tableView.visibleCells) {
        if ([cell.textField isFirstResponder] && [touch view] != cell.textField) {
            [cell.textField resignFirstResponder];
        }
    }
    [super touchesBegan:touches withEvent:event];
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _tapGesture.enabled = YES;
    return YES;
}
-(void)hideKeyboard
{
    for (TDUserEditCell *cell in self.tableView.visibleCells) {
        if ([cell.textField isFirstResponder])
        {
            [cell.textField resignFirstResponder];
            _tapGesture.enabled = NO;
        }
    }
}
@end
