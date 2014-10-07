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
static NSString *header2Text1 =@"Sugestion: use your first and last name";
static NSString *header2Text2 = @"Tap \"Send\" to send your invites!";

@implementation TDSendInviteController
@synthesize sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contactList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBarStyle:UIBarStyleBlack];
    navigationBar.translucent = NO;
    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
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

}

- (void)dealloc {
    self.contactList = nil;
    self.sender = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonHit:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonHit:(id)sender {
    debug NSLog(@"send invitation to users");
    // Get the name of the sender
    NSString *senderName = [self getSenderName];
    if (senderName.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"Name cannot be blank.\nWe suggest entering your first and last names."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        // Get the list
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
    self.activityIndicator.center = self.view.center;
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

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            CGFloat heightText = [TDViewControllerHelper heightForText:header1Text font:[TDConstants fontRegularSized:16.0]];
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, SCREEN_WIDTH, heightText)];
            CGFloat lineHeight = 20.0;
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:header1Text font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:lineHeight];
            [topLabel setTextAlignment:NSTextAlignmentCenter];
            [topLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 22 + heightText + 25)];
            [headerView addSubview:topLabel];
            
            return headerView;
        }
        break;
    
        case 1: {
            CGFloat textHeight = [TDViewControllerHelper heightForText:header2Text1 font:[TDConstants fontRegularSized:14.0]];
            CGFloat bottomTextHeight = [TDViewControllerHelper heightForText:header2Text2 font:[TDConstants fontSemiBoldSized:16.0]];

            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 11 + textHeight + 38 + bottomTextHeight)];
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, 11, 300, textHeight)];
            CGFloat lineHeight = 14;
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:header2Text1 font:[TDConstants fontRegularSized:14.0] color:[TDConstants commentTextColor] lineHeight:lineHeight];
            
            [topLabel setNumberOfLines:1];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [headerView addSubview:topLabel];
            
            UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, 11 + textHeight + 38, SCREEN_WIDTH, bottomTextHeight)];
            lineHeight = 16.0;
            NSAttributedString *bottomAttString = [TDViewControllerHelper makeParagraphedTextWithString:header2Text2 font:[TDConstants fontSemiBoldSized:16.0] color:[TDConstants headerTextColor] lineHeight:lineHeight];
            
            [bottomLabel setTextAlignment:NSTextAlignmentCenter];
            [bottomLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [bottomLabel setAttributedText:bottomAttString];
            [bottomLabel setNumberOfLines:0];
            
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
            return 43.0;
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
            return 22 + [TDViewControllerHelper heightForText:header1Text font:[TDConstants fontRegularSized:16]] + 25;
            break;
        case 1:
            return 11 + [TDViewControllerHelper heightForText:header2Text1 font:[TDConstants fontRegularSized:14.0]] + 38 + [TDViewControllerHelper heightForText:header2Text2 font:[TDConstants fontSemiBoldSized:16.0]];
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
@end
