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
@synthesize origNameLabelYAxis;
@synthesize origNameLabelFrame;
@synthesize inviteList;

- (void)dealloc {
    delegate = nil;
    self.contacts = nil;
    self.userList = nil;
    self.filteredContactArray = nil;
    self.inviteList = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        contacts = [[NSMutableArray alloc] init];
        inviteList = [[NSMutableArray alloc] init];
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
    

    // Search Bar
    self.searchDisplayController.searchBar.backgroundColor = [TDConstants tableViewBackgroundColor];
    self.searchDisplayController.searchBar.backgroundImage = [UIImage new];
    self.searchDisplayController.searchResultsTableView.backgroundColor = [TDConstants postViewBackgroundColor];
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    self.tableView.backgroundColor = [TDConstants tableViewBackgroundColor];
    
    self.filteredContactArray = [NSMutableArray arrayWithCapacity:[contacts count]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Title
    self.navLabel.text = @"Contacts";
    self.suggestedLabel.hidden = YES;
    self.inviteButton.hidden = YES;
    
    self.contacts = [[TDAddressBookAPI sharedInstance] getContactList];

    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    self.tableView.hidden = NO;
    
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(invitesAdded:)]) {
        [delegate invitesAdded:(self.inviteList)];
    }
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.filteredContactArray == nil || self.filteredContactArray == 0) {
            return 90.0;
        } else {
            return 65.0;
        }
    } else {
        return 65.0;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([filteredContactArray count] > 0) {
            return [filteredContactArray count];
        } else {
            return 1;
        }
        
    } else {
        return [contacts count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        TDContactInfo *contactPerson = contacts[indexPath.row];
        if (contactPerson.fullName != nil && contactPerson.fullName.length != 0) {
            TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath contact:contactPerson];
            return cell;
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (filteredContactArray.count == 0) {
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
            cell.contentView.backgroundColor = [TDConstants tableViewBackgroundColor];
            cell.noFollowLabel.text = @"No matches found";
            cell.findPeopleButton.hidden = YES;
            cell.findPeopleButton.enabled = NO;
            
            cell.invitePeopleButton.hidden = NO;
            cell.invitePeopleButton.enabled = YES;
            
            CGRect descripFrame = cell.noFollowLabel.frame;
            descripFrame.origin.y = descripFrame.origin.y + descripFrame.size.height + 7;
            
            UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, descripFrame.origin.y, 320, 57)];
            NSString *text = @"Sorry we weren't able to find the\nperson you're looking for.\n Invite them to join Throwndown.";
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:text font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor]];
            descriptionLabel.attributedText = attString;
            descriptionLabel.textAlignment = NSTextAlignmentCenter;
            [descriptionLabel setNumberOfLines:0];
            [cell addSubview:descriptionLabel];
            
            CGRect frame = cell.invitePeopleButton.frame;
            frame.origin.x = 160 - frame.size.width/2;
            frame.origin.y = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 15;
            cell.invitePeopleButton.frame = frame;
            return cell;

        } else {
            TDContactInfo *contactPerson = [filteredContactArray objectAtIndex:indexPath.row];
            if (contactPerson.fullName != nil && contactPerson.fullName.length != 0) {
            TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath contact:contactPerson];
                return cell;
            }
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        // Get contact from contract array
        TDContactInfo *contactPerson = contacts[indexPath.row];
        [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];

    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        TDContactInfo *contactPerson = filteredContactArray[indexPath.row];
        [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];
    }
}

- (void)addToInviteList:(TDContactInfo*)contactPerson indexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    // If there is no contact info except facetime, pop up aialertview
    if (contactPerson.emailList.count == 0 & contactPerson.phoneList.count == 0) {

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
                                 
                                 // Modify the cell
                                 [self addToInviteList:contactPerson];
                                 [self markCellAsSelected:contactPerson indexPath:indexPath tableView:tableView];
                             }
                         }];
    } else if (contactPerson.emailList.count == 1 || contactPerson.phoneList.count == 1) {
        // else if there is only one contact method, move the selection to the invite page 1
        if (contactPerson.emailList.count == 1) {
            contactPerson.selectedData = contactPerson.emailList[0];
            contactPerson.inviteType = kInviteType_Email;
        } else if (contactPerson.phoneList.count == 1) {
            contactPerson.selectedData = contactPerson.phoneList[0];
            contactPerson.inviteType = kInviteType_Phone;
        }
        [self addToInviteList:contactPerson];
        [self markCellAsSelected:contactPerson indexPath:indexPath tableView:tableView];
    }
}

- (TDFollowProfileCell*) createCell:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath contact:(TDContactInfo*)contact{
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        self.origNameLabelFrame = cell.nameLabel.frame;
    }

    // Reset everything in cell.
    cell.row = indexPath.row;
    cell.topLine.hidden = YES;
    cell.bottomLine.hidden = NO;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.usernameLabel.hidden = YES;
    cell.usernameLabel.attributedText = [[NSMutableAttributedString alloc] init];
    cell.nameLabel.text = @"";
    cell.actionButton.hidden = YES;
    [cell.userImageView setImage:[UIImage imageNamed:@"prof_pic_default.png"]];
    cell.userId = contact.id;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.topLine.hidden = NO;
    } else {
        cell.topLine.hidden = NO;
        cell.bottomLine.hidden = NO;
    }
    cell.nameLabel.textColor = [TDConstants headerTextColor];
    cell.nameLabel.font = [TDConstants fontRegularSized:16];
    
    CGRect nameFrame = cell.nameLabel.frame;
    self.origNameLabelYAxis = nameFrame.origin.y;
    nameFrame.origin.y = MIDDLE_CELL_Y_AXIS;
    cell.nameLabel.frame = nameFrame;
    if(contact.fullName == nil && ([contact.emailList count] > 0 || [contact.phoneList count] > 0)) {
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
    return cell;
}

- (void)markCellAsSelected:(TDContactInfo*)contactInfo indexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    debug NSLog(@"mark as selected");
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
        TDFollowProfileCell *followCell = (TDFollowProfileCell*)cell;
        followCell.accessoryType = UITableViewCellAccessoryNone;
        
        followCell.nameLabel.frame = self.origNameLabelFrame;
        followCell.nameLabel.font = [TDConstants fontSemiBoldSized:16];
        followCell.nameLabel.textColor = [TDConstants headerTextColor];
        [followCell.nameLabel sizeToFit];
        followCell.usernameLabel.hidden = NO;
        NSString *usernameLabel = [NSString stringWithFormat:@"%@%@", @"Invite via: ", contactInfo.selectedData];
        
        NSAttributedString * attributedString = [TDViewControllerHelper makeParagraphedTextWithString:usernameLabel font:[TDConstants fontRegularSized:13] color:[TDConstants headerTextColor]];
        
        followCell.usernameLabel.attributedText = attributedString;
        [followCell.usernameLabel sizeToFit];
        followCell.actionButton.hidden = NO;
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove.png"] forState:UIControlStateNormal];
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateHighlighted];
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateSelected];
    } else {
        debug NSLog(@"did not modify anything!");
    }
}

- (void)addToInviteList:(TDContactInfo*)contact {
    // Check if we've already added the person
    NSArray *filteredArray =
    [self.inviteList filteredArrayUsingPredicate:[NSPredicate
                                                  predicateWithFormat:@"self.id == %@", contact.id]];
    if (!filteredArray.count){
        [self.inviteList insertObject:contact atIndex:0];
    }
    debug NSLog(@"just adding contact to inviteList, count=%lu", (unsigned long)[self.inviteList count]);
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.tableView.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.tableView.hidden = NO;
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
- (void)removeFromInviteList:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
    
    debug NSLog(@"removing contact at row=%ld", (long)indexPath.row);
    
    // Remove from invite list on
    if (self.inviteList[indexPath.row] != nil) {
        [self.inviteList removeObjectAtIndex:indexPath.row];
        
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
            TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
            revertedCell.actionButton.hidden = YES;
            revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            revertedCell.usernameLabel.hidden = YES;
            CGRect frame = revertedCell.nameLabel.frame;
            frame.origin.y = MIDDLE_CELL_Y_AXIS;
            revertedCell.nameLabel.frame = frame;
            revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
        }
    }
}

- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber*)userId{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0] ;
    if (self.tableView.hidden) {
        // Remove from invite list on
        UITableViewCell* cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
            TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
            revertedCell.actionButton.hidden = YES;
            revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            revertedCell.usernameLabel.hidden = YES;
            CGRect frame = revertedCell.nameLabel.frame;
            frame.origin.y = MIDDLE_CELL_Y_AXIS;
            revertedCell.nameLabel.frame = frame;
            revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
        }
    } else {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
            TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
            revertedCell.actionButton.hidden = YES;
            revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            revertedCell.usernameLabel.hidden = YES;
            CGRect frame = revertedCell.nameLabel.frame;
            frame.origin.y = MIDDLE_CELL_Y_AXIS;
            revertedCell.nameLabel.frame = frame;
            revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
        }
    }
    
    // Remove from invite list of this view
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.id <> %@", userId];
    NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:predicate];
    [self.inviteList removeAllObjects];
    if ([filteredArray count] > 0) {
        [self.inviteList addObjectsFromArray:filteredArray];
    }
}
@end
