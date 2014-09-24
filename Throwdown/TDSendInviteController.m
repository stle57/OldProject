//
//  TDSendInviteController.m
//  Throwdown
//
//  Created by Stephanie Le on 9/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSendInviteController.h"
#import "TDConstants.h"
#import "TDUserEditCell.h"
#import "TDAPIClient.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#import "TDViewControllerHelper.h"

@interface TDSendInviteController ()
@property NSMutableArray *contactList;
@end

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
    self.tableView.backgroundColor = [TDConstants tableViewBackgroundColor];
    
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
    
    self.view.backgroundColor = [TDConstants tableViewBackgroundColor];

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
    debug NSLog(@"senderName = %@", senderName);
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
        [self showActivity];
        [[TDAPIClient sharedInstance] sendInvites:senderName contactList:self.contactList success:^ {
            [self hideActivity];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [[TDAppDelegate appDelegate] showToastWithText:@"Invites sent successfully!" type:kToastType_InviteSent payload:nil delegate:nil];
            [[TDAnalytics sharedInstance] logEvent:@"invites_sent"];
        } failure:^{
            [self hideActivity];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [[TDAppDelegate appDelegate] showToastWithText:@"Invites failed.  Tap here to retry" type:kToastType_InviteWarning payload:@{} delegate:nil];
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

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 63)];
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 20, 300, 32)];
            NSString *topLabelText =@"Please confirm how you'd like your\nname to appear to your friends.";
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:topLabelText font:[TDConstants fontRegularSized:16] color:[TDConstants commentTextColor] ];
            [topLabel setTextAlignment:NSTextAlignmentCenter];
            [topLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [headerView addSubview:topLabel];
            
            return headerView;
        }
        break;
    
        case 1: {
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 112)];
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, 300, 40)];
            NSString *topLabelText =@"Sugestion: use your first and last name";

            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:topLabelText font:[TDConstants fontRegularSized:14.0] color:[TDConstants commentTextColor]];
            
            [topLabel setNumberOfLines:1];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [headerView addSubview:topLabel];
            
            UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 63, 320, 36)];
            NSString *bottomText = @"Tap \"Send\" to send your invites!";
            NSAttributedString *bottomAttString = [TDViewControllerHelper makeParagraphedTextWithString:bottomText font:[TDConstants fontSemiBoldSized:16.0] color:[TDConstants headerTextColor]];
            
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
            return 50;
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
            return 63;
            break;
        case 1:
            return 79;
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
