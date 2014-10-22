//
//  TDInviteViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 9/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDInviteViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDInviteCell.h"
#import "TDAnalytics.h"
#import "TDCurrentUser.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDContactsViewController.h"
#import "TDSendInviteController.h"

@import AddressBook;

@interface TDInviteViewController ()
@property (nonatomic) BOOL accessoryViewShown;
@property (nonatomic, retain) NSMutableArray *inviteList;
@end

static NSString *topHeaderText1 =@"Receive a free Throwdown T-shirt if\nthree of your friends join!";
static NSString *topHeaderText2 = @"Invite friends to join with a phone number or\nemail address, or select from your contacts";

@implementation TDInviteViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.inviteList = [[NSMutableArray alloc] init];
        self.headerLabels = [[NSMutableArray alloc] init];
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
    
    self.nextButton.titleLabel.textColor = [UIColor whiteColor];
    self.nextButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.nextButton sizeToFit];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.nextButton]; // NextButton
    self.navigationItem.rightBarButtonItem = rightBarButton;
    self.nextButton.hidden = YES;
    
    // Title
    self.titleLabel.text = @"Invite Friends";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleLabel sizeToFit];
    [self.navigationItem setTitleView:self.titleLabel];
    
    [self checkForNextButton];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
}

- (void)dealloc {
    self.inviteList = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.width = SCREEN_WIDTH;
    tableViewFrame.size.height = [UIScreen mainScreen].bounds.size.height -
        self.navigationController.navigationBar.frame.size.height;
    
    self.tableView.frame = tableViewFrame;
    
    [super viewWillAppear:animated];
    
    [self displayNextButton];
    [self checkForNextButton];
    [self.tableView reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // This is needed so the cells do not overlap with section header
    float  heightForHeader = TD_INVITE_HEADER_HEIGHT_SEC0;
    if (scrollView.contentOffset.y<=heightForHeader&&scrollView.contentOffset.y>=0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=heightForHeader) {
        scrollView.contentInset = UIEdgeInsetsMake(-heightForHeader, 0, 0, 0);
    }
}

- (IBAction)closeButtonHit:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextButtonHit:(id)sender {
   TDSendInviteController *vc = [[TDSendInviteController alloc] initWithNibName:@"TDSendInviteController" bundle:nil ];
    [vc setValuesForSharing:self.inviteList senderName:[[TDCurrentUser sharedInstance] currentUserObject].name];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) createHeaderLabels:(NSInteger)section {
    switch (section) {
        case 0:
        {
            UIFont *font = [TDConstants fontSemiBoldSized:17.0];
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, 30, SCREEN_WIDTH, 100)];
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:topHeaderText1 font:font color:[TDConstants headerTextColor] lineHeight:21.0 lineHeightMultipler:(21.0/17.0)];
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
        case 1:
        {
            if ([self.headerLabels count] == 1) {
                UILabel *topLabel = [self.headerLabels objectAtIndex:section-1];
                UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, HEADER1_TOP_MARGIN + topLabel.frame.size.height + HEADER1_MIDDLE_MARGIN, SCREEN_WIDTH - TD_MARGIN, 100)];
                UIFont *bottomFont = [TDConstants fontRegularSized:15.0];
                NSAttributedString *bottomAttString = [TDViewControllerHelper makeParagraphedTextWithString:topHeaderText2 font:bottomFont color:[TDConstants helpTextColor] lineHeight:19.0 lineHeightMultipler:(19.0/15.0)];
                [bottomLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [bottomLabel setAttributedText:bottomAttString];
                [bottomLabel setNumberOfLines:0];
                [bottomLabel sizeToFit];
            
                // This helps realign the text on the screen
                CGRect bottomLabelFrame = bottomLabel.frame;
                bottomLabelFrame.size.width = SCREEN_WIDTH;
                bottomLabelFrame.origin.x = SCREEN_WIDTH/2 - bottomLabelFrame.size.width/2;
                bottomLabel.frame = bottomLabelFrame;
                [self.headerLabels insertObject:bottomLabel atIndex:section];
            }
        }
        break;
        case 2:
        {
            if ([self.headerLabels count] ==2) {
                UILabel *sectionHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(TD_MARGIN, HEADER1_TOP_MARGIN, SCREEN_WIDTH, 100)];
                NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:@"TO INVITE" font:[TDConstants fontSemiBoldSized:14.0] color:[TDConstants helpTextColor] lineHeight:28.0 lineHeightMultipler:(28.0/14.0)];
                [sectionHeaderLabel setTextAlignment:NSTextAlignmentCenter];
                [sectionHeaderLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [sectionHeaderLabel setAttributedText:attString];
                [sectionHeaderLabel setNumberOfLines:0];
                [sectionHeaderLabel sizeToFit];
                [sectionHeaderLabel setTextAlignment:NSTextAlignmentLeft];
                
                [self.headerLabels insertObject:sectionHeaderLabel atIndex:section];

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
            UILabel *bottomLabel = [self.headerLabels objectAtIndex:section+1];
            
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, HEADER1_TOP_MARGIN + topLabel.frame.size.height + HEADER1_MIDDLE_MARGIN + bottomLabel.frame.size.height + HEADER1_BOTTOM_MARGIN )];
            
            [headerView addSubview:topLabel];
            [headerView addSubview:bottomLabel];
            return headerView;
        }
        break;
        case 2:
        {
            
            UILabel *sectionHeaderLabel = [self.headerLabels objectAtIndex:section];
            UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, SCREEN_WIDTH, HEADER2_TOP_MARGIN + sectionHeaderLabel.frame.size.height + HEADER2_BOTTOM_MARGIN)];

            [headerView addSubview:sectionHeaderLabel];
            return headerView;
        }
        break;
        default:
            break;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0: // phone number row
            return 1;
            break;
        case 1: // my contacts row
            return 1;
            break;
        case 2: // invite list
            return [self.inviteList count];
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return TD_POTRAIT_CELL_HEIGHT;
            break;
        case 1:
            return TD_POTRAIT_CELL_HEIGHT;
            break;
        case 2:
            return TD_INVITE_CELL_HEIGHT;
            break;
        default:
            break;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: // Enter Phone number
        {
            TDInviteCell *cell = (TDInviteCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_INVITE];
            
            UIColor *textFieldPlaceHolderColor = [TDConstants helpTextColor];
            UIFont *placeHolderFont = [TDConstants fontRegularSized:16];
            cell.contactTextField.tag = 800+(10*indexPath.section)+indexPath.row;
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_INVITE owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.contactTextField.delegate = self;
                cell.delegate = self;
            }
            
            cell.contactTextField.hidden = NO;
            cell.contactTextField.enabled = YES;
            cell.contactTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Phone number or email address..."
                                                                                          attributes:@{NSForegroundColorAttributeName: textFieldPlaceHolderColor, NSFontAttributeName:placeHolderFont}];
            cell.contactTextField.keyboardType = UIKeyboardTypeTwitter;
            
            cell.contactTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.contactTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            self.accessoryViewShown = NO;
            
            return cell;
        }
        break;
            
        case 1: // Go to My Contacts
        {
            TDInviteCell *cell = (TDInviteCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_INVITE];
            UIFont *placeHolderFont = [TDConstants fontRegularSized:16];
            UIColor *myContactColor = [TDConstants headerTextColor];
            cell.contactTextField.tag = 800+(10*indexPath.section)+indexPath.row;
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_INVITE owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.contactTextField.delegate = self;
            }
            
            cell.contactTextField.hidden = NO;
            cell.contactTextField.secureTextEntry = YES;
            cell.contactTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"My Contacts"
                                                                                          attributes:@{NSForegroundColorAttributeName: myContactColor, NSFontAttributeName:placeHolderFont}];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            cell.contactTextField.enabled = NO;
            return cell;

        }
        break;
        case 2: {
            if (self.inviteList[indexPath.row] != nil) {
                TDContactInfo *contact = [self.inviteList objectAtIndex:indexPath.row];
                TDFollowProfileCell * followCell =(TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
                if (!followCell) {
                    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
                    followCell = [topLevelObjects objectAtIndex:0];
                    self.origUsernameLabelFrame = followCell.descriptionLabel.frame;
                    self.origNameLabelFrame = followCell.nameLabel.frame;
                }
                followCell.delegate = self;
                followCell.row = indexPath.row;
                followCell.nameLabel.hidden = YES;
                followCell.descriptionLabel.hidden = YES;
                followCell.actionButton.hidden = YES;
                followCell.userId = contact.id;
                followCell.nameLabel.textColor = [TDConstants headerTextColor];
                followCell.nameLabel.font = [TDConstants fontSemiBoldSized:16.0];
                [followCell setAccessoryType:UITableViewCellAccessoryNone];
                if (contact.fullName.length == 0 && contact.selectedData.length != 0) {
                    UIFont *font = [TDConstants fontRegularSized:16.0];
                    
                    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:contact.selectedData font:font color:[TDConstants headerTextColor] lineHeight:16.0];
                    
                    CGRect labelFrame = followCell.descriptionLabel.frame;
                    labelFrame.origin.y = 23.75;
                    followCell.descriptionLabel.frame = labelFrame;
                    followCell.descriptionLabel.hidden = NO;
                    followCell.descriptionLabel.attributedText = attString;
                } else {
                    followCell.nameLabel.hidden = NO;
                    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                    NSString *usernameStr = contact.fullName;
                    [style setLineSpacing:19.0];
                    
                    NSDictionary *attributes2= @{NSParagraphStyleAttributeName:style};
                    NSAttributedString * attributedString2 = [[NSAttributedString alloc] initWithString:usernameStr attributes:attributes2];
                    followCell.nameLabel.attributedText = attributedString2;
                    
                    
                    followCell.descriptionLabel.hidden = NO;
                    followCell.descriptionLabel.text = contact.selectedData;
                    followCell.descriptionLabel.frame = self.origUsernameLabelFrame;

                }
                followCell.actionButton.hidden = NO;
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove.png"] forState:UIControlStateNormal];
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateHighlighted];
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateSelected];
                
                [followCell.actionButton setTag:1001]; //TODO:Fix this!
                
                if (contact.contactPicture) {
                    [followCell.userImageView setImage:contact.contactPicture];
                } else {
                    [followCell.userImageView setImage:[UIImage imageNamed:@"prof_pic_default"]];
                }
                return followCell;
            }
        }
        break;
            
        default:
        break;
            
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.inviteList count] == 0) {
        return 2;
    } else {
        return 3;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            [self createHeaderLabels:section];
            [self createHeaderLabels:section+1];
            UILabel *topLabel = [self.headerLabels objectAtIndex:section];
            UILabel *bottomLabel = [self.headerLabels objectAtIndex:section+1];
            
            return HEADER1_TOP_MARGIN + topLabel.frame.size.height + HEADER1_MIDDLE_MARGIN + bottomLabel.frame.size.height + HEADER1_BOTTOM_MARGIN ;
        }
            break;
        case 1:
            return TD_INVITE_HEADER_HEIGHT_SEC1;
            break;
        case 2:
        {
            [self createHeaderLabels:section];
            UILabel *toInviteLabel = [self.headerLabels objectAtIndex:section];
            return HEADER2_TOP_MARGIN + toInviteLabel.frame.size.height + HEADER2_BOTTOM_MARGIN;
        }
            break;
        default:
            return 0.;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case 1:
            switch (indexPath.row) {
                case 0:
                    self.activityIndicator.text.text = @"Loading";
                    [self showActivity];
                    [self gotoMyContacts];
                    break;

                default:
                    break;
            }
            break;
        default:
            break;
    }
    
}

#pragma mark - TDTextField delegates    

-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Build the two index paths
    NSIndexPath* indexPath1 = [NSIndexPath indexPathForRow:0 inSection:0];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath1];
    if(cell) {
        TDInviteCell *inviteCell = (TDInviteCell*)cell;
        [inviteCell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
       self.accessoryViewShown = NO;
        inviteCell.addedButton = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSIndexPath *indexPath1 =[NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath1];
    if(cell) {
        TDInviteCell *inviteCell = (TDInviteCell*)cell;
        if (textField == inviteCell.contactTextField) {
            [inviteCell.contactTextField resignFirstResponder];
            [self insertDataIntoInviteList:indexPath1];
        }
        [inviteCell setAccessoryType:UITableViewCellAccessoryNone];
        [inviteCell setAccessoryView:nil];
        self.accessoryViewShown = NO;
        
        
        return NO;
    }
    
    return YES;
}

- (void)checkButtonTapped:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil) {
        [self insertDataIntoInviteList:indexPath];
    }
}

- (void)checkForNextButton {
    if ([self.inviteList count]) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
    }
}

- (void) displayNextButton {
    if ([self.inviteList count] == 0) {
        self.nextButton.hidden = YES;
    } else {
        self.nextButton.hidden = NO;
    }

}
- (void)insertDataIntoInviteList:(NSIndexPath*)indexPath1 {
    NSString *formatedPhone;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath1];
    if (cell) {
        TDInviteCell *inviteCell = (TDInviteCell*)cell;
        TDContactInfo *contact = [[TDContactInfo alloc]init];
        if ([TDViewControllerHelper validateEmail:inviteCell.contactTextField.text]) {
            contact.selectedData = inviteCell.contactTextField.text;
            contact.inviteType = kInviteType_Email;
        } else {
            formatedPhone = [TDViewControllerHelper validatePhone:inviteCell.contactTextField.text];
            if(formatedPhone.length > 0) {
                contact.selectedData = formatedPhone;
                contact.inviteType = kInviteType_Phone;
            } else {
                contact.inviteType = kInviteType_None;
            }
        }
        
        if (contact.inviteType != kInviteType_None) {
            // Check if data is already in the current invite list
            NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:[NSPredicate
                                                                                   predicateWithFormat:@"self.selectedData == %@", contact.selectedData]];
            if (![filteredArray count]) {
                [self addToInviteList:contact];
            }
        }
        inviteCell.contactTextField.text = @"";
        [self.tableView reloadData];
        [self displayNextButton];
    }
}

#pragma mark - my contacts
- (void)gotoMyContacts {
    // Check to see if we asked for contact permission yet
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        //show controller
        TDContactsViewController *vc = [[TDContactsViewController alloc] initWithNibName:@"TDContactsViewController" bundle:nil ];
        vc.delegate = self;
        [vc setValuesForSharing:self.inviteList];
        [self.navigationController pushViewController:vc animated:YES];
        [self hideActivity];
    } else {
        NSString * message = @"We'd like to ask for your permission\nto access your Contacts.  On the\nnext screen, please tap \"OK\" to\n give us permission.";
        
        [[TDAnalytics sharedInstance] logEvent:@"contacts_asked"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ask me", nil];
        [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [[TDAnalytics sharedInstance] logEvent:@"contacts_accept"];
                // iOS permission to access contacts
                [[TDCurrentUser sharedInstance] didAskForContacts:YES];
                ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!granted){
                            UIAlertView *cantAddContactAlert = [[UIAlertView alloc] initWithTitle: @"Cannot Add Contact" message: @"You must give the app permission to add the contact first." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
                            [cantAddContactAlert show];
                            [self hideActivity];
                            return;
                        }
                        TDContactsViewController *vc = [[TDContactsViewController alloc] initWithNibName:@"TDContactsViewController" bundle:nil ];
                        [vc setValuesForSharing:self.inviteList];
                        [self.navigationController pushViewController:vc animated:YES];
                        [self hideActivity];
                    });
                });
            } else {
                [self hideActivity];
            }
        }];
        
    }
}

#pragma mark TDFollowProfileCellDelegate
- (void)contactPressedFromRow:(TDContactInfo*)contact {
    // Check if we've already added the person
    NSArray *filteredArray =
    [self.inviteList filteredArrayUsingPredicate:[NSPredicate
            predicateWithFormat:@"self.selectedData == %@", contact.selectedData]];
    if (!filteredArray.count){
        [self addToInviteList:contact];
    }
}

- (void)invitesAdded:(NSMutableArray*)inviteList {
    // Need to filter dups from the contact view controller
    bool foundEntry = NO;
    for (id object in inviteList)
    {
        TDContactInfo *info = (TDContactInfo*)object;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.id == %@", info.id];
        NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] == 0) {
            foundEntry = YES;
            [self.inviteList insertObject:object atIndex:0];
        }
    }
    [self checkForNextButton];
}

- (void)addToInviteList:(TDContactInfo*)contact {
    [self.inviteList insertObject:contact atIndex:0];
    [self checkForNextButton];
}

- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber *)userId{
    if ([self.inviteList objectAtIndex:row] != nil) {
        if (tag == 1001) {
            [self.inviteList removeObjectAtIndex:row];
            [self.tableView reloadData];
            [self displayNextButton];
        }
    }
}

#pragma mark - Activity

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
@end
