//
//  TDContactsViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDContactsViewController.h"
#import "UIActionSheet+Blocks.h"
#import "TDUserAPI.h"
#import "TDViewControllerHelper.h"
#import "TDAddressBookAPI.h"

@implementation TDContactsViewController
@synthesize delegate;
@synthesize filteredContactArray;
@synthesize contacts;
@synthesize userList;

- (void)dealloc {
    delegate = nil;
    self.contacts = nil;
    self.userList = nil;
    self.filteredContactArray = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        contacts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.searchDisplayController.searchBar sizeToFit];
    
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    self.tableView.backgroundColor = [TDConstants tableViewBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    
    [self.searchDisplayController.searchBar setBarTintColor:[TDConstants tableViewBackgroundColor]];
    
    // Title
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];
    

    self.searchDisplayController.searchBar.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.searchDisplayController.searchBar.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.searchDisplayController.searchBar.backgroundColor = [TDConstants tableViewBackgroundColor];
    
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    self.tableView.backgroundColor = [TDConstants tableViewBackgroundColor];
    
    self.filteredContactArray = [NSMutableArray arrayWithCapacity:[contacts count]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Title
    self.navLabel.text = @"Contacts";
    self.suggestedLabel.hidden = YES;
    self.inviteButton.hidden = YES;
    
    contacts = [[TDAddressBookAPI sharedInstance] getContactList];
    debug NSLog(@"contacts count=%lu", (unsigned long)[contacts count]);
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
}

- (IBAction)backButtonHit:(id)sender {
    [self leave];
}

- (void) leave {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)inviteButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [filteredContactArray count];
        
    } else {
        return [contacts count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        TDContactInfo *contactPerson = contacts[indexPath.row];
        TDFollowProfileCell *cell = [self createCell:indexPath contact:contactPerson];
        return cell;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        TDContactInfo *contactPerson = [filteredContactArray objectAtIndex:indexPath.row];
        TDFollowProfileCell *cell = [self createCell:indexPath contact:contactPerson];
         return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        // Get contact from contract array
        TDContactInfo *contactPerson = contacts[indexPath.row];
        [self addToInviteList:contactPerson];

    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        TDContactInfo *contactPerson = filteredContactArray[indexPath.row];
        [self addToInviteList:contactPerson];
    }
}

- (void)addToInviteList:(TDContactInfo*)contactPerson {
    // If there is no contact info except facetime, pop up aialertview
    if (contactPerson.emailList.count == 0 & contactPerson.phoneList.count == 0) {
        debug NSLog(@"display uialertview!!!!");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Contact Method Available"
                                                        message:@"Sorry, we weren't able to find an available phone number or email to send this person an invite."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if ( contactPerson.emailList.count > 1 || contactPerson.phoneList.count > 1) {
        // else if there is a lot of contact info, use UIActionSheet and show various ways.
        NSMutableArray *buttonStrings = [NSMutableArray arrayWithArray:contactPerson.emailList];
        [buttonStrings addObjectsFromArray:contactPerson.phoneList];

        [UIActionSheet showInView:self.view
                        withTitle:@"Invite via"
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:nil
                otherButtonTitles:buttonStrings
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex == actionSheet.cancelButtonIndex) {
                                 return;
                             }
                             NSLog(@"Selected button at index %lu", (unsigned long)buttonIndex);
                             debug NSLog(@"  with contact name=%@", contactPerson.fullName);
                             if (self.delegate && [self.delegate respondsToSelector:@selector(contactPressedFromRow:)]) {
                                 NSString *formatedPhone;
                                 if ([TDViewControllerHelper validateEmail:buttonStrings[buttonIndex]]) {
                                     contactPerson.selectedData = buttonStrings[buttonIndex];
                                     contactPerson.inviteType = kInviteType_Email;
                                 } else {
                                     formatedPhone = [TDViewControllerHelper validatePhone:buttonStrings[buttonIndex]];
                                     if(formatedPhone) {
                                         contactPerson.selectedData = formatedPhone;
                                         contactPerson.inviteType = kInviteType_Phone;
                                     } else {
                                         return;
                                     }
                                 }
                                 [delegate contactPressedFromRow:(contactPerson)];
                             }
                             [self leave];
                         }];
    } else if (contactPerson.emailList.count == 1 || contactPerson.phoneList.count == 1) {
        // else if there is only one contact method, move the selection to the invite page 1
        debug NSLog(@"just use this info and add to invite list");
        if (contactPerson.emailList.count == 1) {
            contactPerson.selectedData = contactPerson.emailList[0];
            contactPerson.inviteType = kInviteType_Email;
            if (self.delegate && [self.delegate respondsToSelector:@selector(contactPressedFromRow:)]) {
                [delegate contactPressedFromRow:(contactPerson)];
            }
        } else if (contactPerson.phoneList.count == 1) {
            contactPerson.selectedData = contactPerson.phoneList[0];
            contactPerson.inviteType = kInviteType_Phone;
            if (self.delegate && [self.delegate respondsToSelector:@selector(contactPressedFromRow:)]) {
                [delegate contactPressedFromRow:(contactPerson)];
            }
        }
        [self leave];
    }
}

- (TDFollowProfileCell*) createCell:(NSIndexPath *)indexPath contact:(TDContactInfo*)contact{
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[self.tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
        cell.row = indexPath.row;
        
        cell.usernameLabel.hidden = YES;
        cell.actionButton.hidden = YES;
        
        cell.nameLabel.textColor = [TDConstants headerTextColor];
        cell.nameLabel.font = [TDConstants fontBoldSized:16];
        
        CGRect nameFrame = cell.nameLabel.frame;
        nameFrame.origin.y = MIDDLE_CELL_Y_AXIS;
        cell.nameLabel.frame = nameFrame;
        if(contact.fullName == nil) {
            debug NSLog(@"!!!!this contact has a null full name");
        }
        NSString *fullName = contact.fullName;
        cell.nameLabel.hidden = NO;
        cell.nameLabel.text = fullName;
        [cell.nameLabel sizeToFit];
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:19.0];
        NSDictionary *attributes2= @{NSParagraphStyleAttributeName:style};
        NSAttributedString * attributedString2 = [[NSAttributedString alloc] initWithString:fullName attributes:attributes2];
        cell.nameLabel.attributedText = attributedString2;
        
        if (contact.contactPicture) {
            [cell.userImageView setImage:contact.contactPicture];
        }
    }
    return cell;
}
#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
}

#pragma mark Content Filtering
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Remove all objects from the filtered search array
	[self.filteredContactArray removeAllObjects];
    
	// Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.fullName contains[c] %@",searchText];
    NSArray *tempArray = [contacts filteredArrayUsingPredicate:predicate];
    filteredContactArray = [NSMutableArray arrayWithArray:tempArray];
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - TDFollowCellProfileDelegate
- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag{
  // Implement in next build SLE: 09/24/2014
}

@end
