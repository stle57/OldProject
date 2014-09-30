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
@property (nonatomic) NSMutableArray *inviteList;
@end

@implementation TDInviteViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.inviteList = [[NSMutableArray alloc] init];
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
    
    self.nextButton.titleLabel.textColor = [UIColor whiteColor];
    self.nextButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.nextButton sizeToFit];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.nextButton]; // NextButton
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    // Title
    self.titleLabel.text = @"Invite Friends";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.titleLabel sizeToFit];
    [self.navigationItem setTitleView:self.titleLabel];
    
    [self checkForNextButton];
    self.view.backgroundColor = [TDConstants tableViewBackgroundColor];
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
    [super viewWillAppear:animated];
    
    [self checkForNextButton];
    [self.tableView reloadData];
}

- (IBAction)closeButtonHit:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextButtonHit:(id)sender {
   TDSendInviteController *vc = [[TDSendInviteController alloc] initWithNibName:@"TDSendInviteController" bundle:nil ];
    [vc setValuesForSharing:self.inviteList senderName:[[TDCurrentUser sharedInstance] currentUserObject].name];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        {
            UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 112)];

            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 20, 300, 40)];
            NSString *topLabelText =@"Receive a free Throwdown T-shirt if\nthree of your friends join!";
            UIFont *font = [TDConstants fontSemiBoldSized:16.0];
            
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:topLabelText font:font color:[TDConstants commentTextColor]];
            
            [topLabel setTextAlignment:NSTextAlignmentCenter];
            [topLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [topLabel setAttributedText:attString];
            [topLabel setNumberOfLines:0];
            [headerView addSubview:topLabel];
            
            UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 75, 320, 36)];
            NSString *bottomText = @"Invite friends to join with a phone number or\nemail address, or select from your contacts";
            UIFont *bottomFont = [TDConstants fontRegularSized:14.0];
            
            NSAttributedString *bottomAttString = [TDViewControllerHelper makeParagraphedTextWithString:bottomText font:bottomFont color:[TDConstants commentTextColor]];

            [bottomLabel setTextAlignment:NSTextAlignmentNatural];
            [bottomLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [bottomLabel setAttributedText:bottomAttString];
            [bottomLabel setNumberOfLines:0];
            
            [headerView addSubview:bottomLabel];
            return headerView;
        }
        break;
        case 2:
        {
            UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, 320, 49)];
            UILabel *sectionHeaderLabel = [[UILabel alloc] initWithFrame:headerView.layer.frame];
            sectionHeaderLabel.text = @"TO INVITE";
            sectionHeaderLabel.font = [TDConstants fontSemiBoldSized:14];
            sectionHeaderLabel.textColor = [TDConstants commentTimeTextColor]; // a2a2a2
            CGRect labelFrame = sectionHeaderLabel.frame;
            sectionHeaderLabel.textAlignment = NSTextAlignmentLeft;
            labelFrame.origin.x = 7.0;
            labelFrame.origin.y = 25.0;
            sectionHeaderLabel.frame = labelFrame;
            [sectionHeaderLabel sizeToFit];
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
    
    debug NSLog(@"!!!!creating cell for section: %lu and row: %lu", indexPath.section, indexPath.row);
    switch (indexPath.section) {
        case 0: // Enter Phone number
        {
            TDInviteCell *cell = (TDInviteCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_INVITE];
            
            UIColor *textFieldPlaceHolderColor = [TDConstants commentTimeTextColor];
            UIFont *placeHolderFont = [TDConstants fontRegularSized:16];
            cell.contactTextField.tag = 800+(10*indexPath.section)+indexPath.row;
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_INVITE owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.contactTextField.delegate = self;
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
                    self.origUsernameLabelFrame = followCell.usernameLabel.frame;
                    self.origNameLabelFrame = followCell.nameLabel.frame;
                }
                followCell.delegate = self;
                followCell.row = indexPath.row;
                followCell.nameLabel.hidden = YES;
                followCell.usernameLabel.hidden = YES;
                followCell.actionButton.hidden = YES;
                
                followCell.nameLabel.textColor = [TDConstants headerTextColor];
                followCell.nameLabel.font = [TDConstants fontRegularSized:16.0];
                [followCell setAccessoryType:UITableViewCellAccessoryNone];
                if (contact.fullName.length == 0 && contact.selectedData.length != 0) {
                    UIFont *font = [TDConstants fontRegularSized:16.0];
                    
                    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:contact.selectedData font:font color:[TDConstants headerTextColor]];
                    
                    CGRect labelFrame = followCell.usernameLabel.frame;
                    labelFrame.origin.y = 23.75;
                    followCell.usernameLabel.frame = labelFrame;
                    followCell.usernameLabel.hidden = NO;
                    followCell.usernameLabel.attributedText = attString;
                } else {
                    followCell.nameLabel.hidden = NO;
                    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                    NSString *usernameStr = contact.fullName;
                    [style setLineSpacing:19.0];
                    NSDictionary *attributes2= @{NSParagraphStyleAttributeName:style};
                    NSAttributedString * attributedString2 = [[NSAttributedString alloc] initWithString:usernameStr attributes:attributes2];
                    followCell.nameLabel.attributedText = attributedString2;
                    
                    
                    followCell.usernameLabel.hidden = NO;
                    followCell.usernameLabel.text = contact.selectedData;
                    followCell.usernameLabel.frame = self.origUsernameLabelFrame;

                }
                followCell.actionButton.hidden = NO;
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove.png"] forState:UIControlStateNormal];
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateHighlighted];
                [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateSelected];
                
                [followCell.actionButton setTag:1001]; //TODO:Fix this!
                
                if (contact.contactPicture) {
                    [followCell.userImageView setImage:contact.contactPicture];
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
            return TD_INVITE_HEADER_HEIGHT_SEC0;
            break;
        case 1:
            return TD_INVITE_HEADER_HEIGHT_SEC1;
        case 2:
            return TD_INVITE_HEADER_HEIGHT_SEC2;
            break;
        default:
            return 0.;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"inviteviewcontroller row selected");
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case 1:
            switch (indexPath.row) {
                case 0:
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
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSIndexPath* indexPath1 = [NSIndexPath indexPathForRow:0 inSection:0];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath1];
    if(cell) {
        TDInviteCell *inviteCell = (TDInviteCell*)cell;
        [inviteCell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(inviteCell.accessoryView.frame.origin.x, inviteCell.accessoryView.frame.size.height, 44, 44);
        button.frame = frame;
        [button.titleLabel setFont:[TDConstants fontRegularSized:16]];
        [button setTitle:@"Add" forState:UIControlStateNormal];
        [button setTitleColor:[TDConstants brandingRedColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(checkButtonTapped:event:)  forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
        inviteCell.accessoryView = button;
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Build the two index paths
    NSIndexPath* indexPath1 = [NSIndexPath indexPathForRow:0 inSection:0];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath1];
    if(cell) {
        TDInviteCell *inviteCell = (TDInviteCell*)cell;
        [inviteCell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
       self.accessoryViewShown = NO;
    }
}

- (void)checkButtonTapped:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    NSString *formatedPhone;
    if (indexPath != nil)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            TDInviteCell *inviteCell = (TDInviteCell*)cell;
            TDContactInfo *contact = [[TDContactInfo alloc]init];
            if ([TDViewControllerHelper validateEmail:inviteCell.contactTextField.text]) {
                contact.selectedData = inviteCell.contactTextField.text;
                contact.inviteType = kInviteType_Email;
            } else {
                formatedPhone = [TDViewControllerHelper validatePhone:inviteCell.contactTextField.text];
                if(formatedPhone) {
                    contact.selectedData = formatedPhone;
                    contact.inviteType = kInviteType_Phone;
                } else {
                    contact.inviteType = kInviteType_None;
                }
            }
            
            // Check if data is already in the current invite list
            NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:[NSPredicate
                                                  predicateWithFormat:@"self.selectedData == %@", contact.selectedData]];
            if (![filteredArray count]) {
                [self addToInviteList:contact];
            }
            inviteCell.contactTextField.text = @"";
            [inviteCell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];

            inviteCell.accessoryView = nil;
            [self.tableView reloadData];
        }
    }
}

- (void)checkForNextButton {
    if ([self.inviteList count]) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
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
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        debug NSLog(@"first time asking");
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
                            return;
                        }
                        TDContactsViewController *vc = [[TDContactsViewController alloc] initWithNibName:@"TDContactsViewController" bundle:nil ];
                        [self.navigationController pushViewController:vc animated:YES];
                    });
                });
            }
        }];
        
    }
}

#pragma mark TDFollowProfileCellDelegate
- (void)contactPressedFromRow:(TDContactInfo*)contact {
    NSArray *filteredArray =
    [self.inviteList filteredArrayUsingPredicate:[NSPredicate
            predicateWithFormat:@"self.selectedData == %@", contact.selectedData]];
    if (!filteredArray.count){
        [self addToInviteList:contact];
    }
}

- (void)addToInviteList:(TDContactInfo*)contact {
    [self.inviteList insertObject:contact atIndex:0];
    [self checkForNextButton];
}

- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag {
    debug NSLog(@"inside TDInviteViewController: actionButtonPressedFromRow, row=%lu, tag=%ld", row, (long)tag);
    if ([self.inviteList objectAtIndex:row] != nil) {
        if (tag == 1001) {
            [self.inviteList removeObjectAtIndex:row];
            [self.tableView reloadData];
        }
    }
}

@end