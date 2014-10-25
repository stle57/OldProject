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

@interface TDContactsViewController ()
@property (nonatomic, retain) NSMutableArray *currentInviteList;
@end

@implementation TDContactsViewController
@synthesize delegate;
@synthesize filteredContactArray;
@synthesize contacts;
@synthesize origNameLabelYAxis;
@synthesize origNameLabelFrame;
@synthesize inviteList;
@synthesize searchingActive;
@synthesize searchText;
@synthesize disableViewOverlay;
@synthesize editingIndexPath;

- (void)dealloc {
    delegate = nil;
    self.contacts = nil;
    self.filteredContactArray = nil;
    self.inviteList = nil;
    self.labels = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contacts = [[NSMutableArray alloc] init];
        self.inviteList = [[NSMutableArray alloc] init];
        self.labels = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,44.0f,SCREEN_WIDTH,SCREEN_HEIGHT-self.navigationController.navigationBar.frame.size.height - self.searchBar.frame.size.height)];
    self.disableViewOverlay.backgroundColor=[UIColor blackColor];
    self.disableViewOverlay.alpha = 0;

    // Resize the view
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = SCREEN_HEIGHT;
    viewFrame.size.width = SCREEN_WIDTH;
    self.view.frame = viewFrame;
    
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    
    self.doneButton.hidden = NO;
    self.doneButton.titleLabel.font = [TDConstants fontRegularSized:18];
    self.doneButton.titleLabel.textColor = [UIColor whiteColor];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    // Title
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];
    

    // Search Bar
    [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"f5f5f5_square.png"] forBarPosition:0 barMetrics:UIBarMetricsDefault]; // Sets the search bar to a solid color(no transparancy)
    self.searchBar.translucent = NO;
    self.searchBar.layer.borderColor = [[TDConstants darkBorderColor] CGColor];
    self.searchBar.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.searchBar.clipsToBounds = YES;
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    
    self.filteredContactArray = [NSMutableArray arrayWithCapacity:[contacts count]];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Title
    self.navLabel.text = @"Contacts";
    
    self.contacts = [[TDAddressBookAPI sharedInstance] getContactList];

    NSDictionary *dict = [[TDAddressBookAPI sharedInstance] getContactsDictionary];
    // Check if we've already added the person to the invite list, and mark the contact as added
    for (int index = 0; index < self.currentInviteList.count; index++) {
        TDContactInfo *info = self.currentInviteList[index];
        // Check if we've already added the person
        TDContactInfo *obj = [dict objectForKey:[info.id stringValue]];
        {
            obj.selectedData = info.selectedData;
            obj.inviteType = info.inviteType;
        }
    }
    [self.tableView reloadData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];
    
    CGRect frame = self.searchBar.frame;
    frame.size.width = SCREEN_WIDTH;
    self.searchBar.frame = frame;
    [self.searchBar sizeToFit];

    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.width = SCREEN_WIDTH;
    tableFrame.size.height = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.searchBar.frame.size.height;
    self.tableView.frame = tableFrame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews{
    //[self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.searchBar setShowsCancelButton:NO animated:NO];
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

- (IBAction)doneButtonHit:(id)sender {
    [self leave];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.searchingActive || [self.searchText isEqual:@""]) {
        return 65;
    }
    else {
        if ([filteredContactArray count] > 0) {
            return 65;
        } else {
            return 220;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.searchingActive || [self.searchText isEqual:@""]) {
        return [self.contacts count];
    }
    else {
        if ([filteredContactArray count] > 0) {
            return [filteredContactArray count];
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((!self.searchingActive) || [self.searchText isEqual:@""]) {
        TDContactInfo *contactPerson = contacts[indexPath.row];
        if (contactPerson.fullName != nil && contactPerson.fullName.length != 0) {
            TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath contact:contactPerson];
            return cell;
        }
    } else {
        if (filteredContactArray.count == 0) {
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
            cell.userInteractionEnabled = YES;
            cell.backgroundColor = [UIColor whiteColor];
            self.tableView.backgroundColor = [UIColor whiteColor];

            NSString *noMatchesString = @"No matches found";
            NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:noMatchesString font:[TDConstants fontSemiBoldSized:16.0] color:[TDConstants headerTextColor] lineHeight:19 lineHeightMultipler:(19/16.0)];
            cell.noFollowLabel.attributedText = attString;
            
            cell.findPeopleButton.hidden = YES;
            cell.findPeopleButton.enabled = NO;

            cell.invitePeopleButton.hidden = YES;
            cell.invitePeopleButton.enabled = NO;
            
            CGRect descripFrame = cell.noFollowLabel.frame;
            descripFrame.origin.y = descripFrame.origin.y + descripFrame.size.height + 7;
            
            UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, descripFrame.origin.y, SCREEN_WIDTH, 57)];
            CGFloat lineHeight = 19;
            NSString *text = @"Sorry we weren't able to find the\nperson you're looking for in\nyour Address Book.";
            attString = [TDViewControllerHelper makeParagraphedTextWithString:text font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/15.0)];
            descriptionLabel.attributedText = attString;
            descriptionLabel.textAlignment = NSTextAlignmentCenter;
            [descriptionLabel setNumberOfLines:0];
            [cell addSubview:descriptionLabel];
            
            return cell;

        } else {
            self.tableView.backgroundColor = [TDConstants lightBackgroundColor];

            TDContactInfo *contactPerson = [filteredContactArray objectAtIndex:indexPath.row];
            if (contactPerson.fullName != nil && contactPerson.fullName.length != 0) {
            TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath contact:contactPerson];
            
            // Check if we've already added the person from the main table view.  If so, change the reformat the cell
            for (int index = 0; index < self.inviteList.count; index++) {
                TDContactInfo *info = self.inviteList[index];
                // Check if we've already added the person
                if(info.id == contactPerson.id) {
                    [self reformatCellToSelected:cell contactInfo:contactPerson];
                }
            }
            return cell;
            }
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (!self.searchingActive) {
        // Get contact from contract array
        TDContactInfo *contactPerson = contacts[indexPath.row];
        [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];

    } else {
        if ([self.filteredContactArray count] == 0) {
            // We got in this state because the user tapped out of the search bar and had
            // and empty search result.
            return;
        } else {
            TDContactInfo *contactPerson = filteredContactArray[indexPath.row];

            [self addToInviteList:contactPerson indexPath:indexPath tableView:tableView];
        }
    }
}

- (void)addToInviteList:(TDContactInfo*)contactPerson indexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    // If there is no contact info except facetime, pop up aialertview
    if (contactPerson.emailList.count == 0 && contactPerson.phoneList.count == 0) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Contact Method Available"
                                                        message:@"Sorry, we weren't able to find an available phone number or email to send this person an invite."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if ( (contactPerson.emailList.count > 1 || contactPerson.phoneList.count > 1) || ((contactPerson.emailList.count == 1 && contactPerson.phoneList.count ==1) ) ){
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
                                     if(formatedPhone.length > 0) {
                                         contactPerson.selectedData = formatedPhone;
                                         contactPerson.inviteType = kInviteType_Phone;
                                     } else {
                                         return;
                                     }
                                 }
                                 
                                 // Modify the cell
                                 [self addToInviteList:contactPerson];
                                 [self markCellAsSelected:contactPerson indexPath:indexPath tableView:tableView];
                                 [self markCellAsSelected:contactPerson indexPath:nil tableView:tableView];
                             }
                         }];
    } else if (contactPerson.emailList.count == 1 || contactPerson.phoneList.count == 1) {
        // else if there is only one contact method, move the selection to the invite page 1
        if (contactPerson.emailList.count == 1) {
            if ([TDViewControllerHelper validateEmail:contactPerson.emailList[0]]) {
                contactPerson.selectedData = contactPerson.emailList[0];
                contactPerson.inviteType = kInviteType_Email;
                
                [self addToInviteList:contactPerson];
                [self markCellAsSelected:contactPerson indexPath:indexPath tableView:tableView];
                [self markCellAsSelected:contactPerson indexPath:nil tableView:tableView];
            }
        } else if (contactPerson.phoneList.count == 1) {
            NSString *formatedPhone =[TDViewControllerHelper validatePhone:contactPerson.phoneList[0]];
            if (formatedPhone.length > 0) {
                contactPerson.selectedData = formatedPhone;
                contactPerson.inviteType = kInviteType_Phone;
                [self addToInviteList:contactPerson];
                [self markCellAsSelected:contactPerson indexPath:indexPath tableView:tableView];
                [self markCellAsSelected:contactPerson indexPath:nil tableView:tableView];
            }
        }
        
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

    //TODO: Setting height to 1 for ios7 bug, but need to fix this
    if ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0){
        cell.topLine.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1);
        cell.bottomLine.frame = CGRectMake(0, 64, SCREEN_WIDTH, 1);
    }
    // Reset everything in cell.
    cell.row = indexPath.row;
    cell.topLine.hidden = cell.row != 0;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.descriptionLabel.hidden = YES;
    cell.descriptionLabel.attributedText = [[NSMutableAttributedString alloc] init];
    cell.nameLabel.text = @"";
    cell.actionButton.hidden = YES;
    [cell.userImageView setImage:[UIImage imageNamed:@"prof_pic_default.png"]];
    cell.userId = contact.id;

    cell.nameLabel.textColor = [TDConstants headerTextColor];
    cell.nameLabel.font = [TDConstants fontRegularSized:16];
    
    CGRect nameFrame = cell.nameLabel.frame;
    self.origNameLabelYAxis = nameFrame.origin.y;
    nameFrame.origin.y = MIDDLE_CELL_Y_AXIS;
    cell.nameLabel.frame = nameFrame;

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
    // Check if we've already added the person from the main table view.  If so, change the reformat the cell
    for (int index = 0; index < self.inviteList.count; index++) {
        TDContactInfo *info = self.inviteList[index];
        // Check if we've already added the person
        if(info.id == contact.id) {
            [self reformatCellToSelected:cell contactInfo:contact];
        }
    }
    return cell;
}

- (void)markCellAsSelected:(TDContactInfo*)contactInfo indexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView{
    if (indexPath != nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self reformatCellToSelected:cell contactInfo:contactInfo];
    } else {
        NSUInteger index = 0;

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.id == %@", contactInfo.id];
        if (self.searchingActive){
            NSArray * selectedObject = [self.contacts filteredArrayUsingPredicate:predicate];
            if (selectedObject){
                index = [self.contacts indexOfObject:selectedObject[0]];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(int)index inSection:0];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell) {
                    [self reformatCellToSelected:cell contactInfo:selectedObject[0]];
                }
            }
        } else {
            debug NSLog(@"have contact info to mark in search view");
        }
    }
}

- (void)reformatCellToSelected:(UITableViewCell*)cell contactInfo:(TDContactInfo*)contactInfo{
    if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
        TDFollowProfileCell *followCell = (TDFollowProfileCell*)cell;
        followCell.accessoryType = UITableViewCellAccessoryNone;
        
        followCell.nameLabel.frame = self.origNameLabelFrame;
        followCell.nameLabel.font = [TDConstants fontSemiBoldSized:16];
        followCell.nameLabel.textColor = [TDConstants headerTextColor];
        [followCell.nameLabel sizeToFit];
        followCell.descriptionLabel.hidden = NO;
        NSString *usernameLabel = [NSString stringWithFormat:@"%@%@", @"Invite via: ", contactInfo.selectedData];
        
        CGFloat lineHeight = 0;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:usernameLabel];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineHeightMultiple:(lineHeight/13.0)];
        [paragraphStyle setMinimumLineHeight:lineHeight];
        [paragraphStyle setMaximumLineHeight:lineHeight];
        paragraphStyle.alignment = NSTextAlignmentLeft;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, usernameLabel.length)];
        [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:13.0] range:NSMakeRange(0, usernameLabel.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, usernameLabel.length)];
        
        followCell.descriptionLabel.attributedText = attributedString;
        [followCell.descriptionLabel sizeToFit];
        
        CGRect frame = followCell.descriptionLabel.frame;
        frame.size.width = followCell.actionButton.frame.origin.x - frame.origin.x - TD_MARGIN;
        followCell.descriptionLabel.frame = frame;
        
        followCell.actionButton.hidden = NO;
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove.png"] forState:UIControlStateNormal];
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateHighlighted];
        [followCell.actionButton setImage:[UIImage imageNamed:@"btn-remove-hit.png"] forState:UIControlStateSelected];
    }
}
- (void)addToInviteList:(TDContactInfo*)contact {
    // Check if we've already added the person
    NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:[NSPredicate
                                                      predicateWithFormat:@"self.id == %@", contact.id]];
    if (!filteredArray.count) {
        [self.inviteList insertObject:contact atIndex:0];
    }
}

- (void)createLabels {
    
}
#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    self.searchingActive = YES;

    [self searchBar:self.searchBar activate:YES];
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.searchingActive = NO;
    self.searchBar.text= @"";
    self.searchText = self.searchBar.text;
    [self searchBar:self.searchBar activate:NO];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchString {
    if (searchString.length > 0) {
        [disableViewOverlay removeFromSuperview];
    } else {
        self.disableViewOverlay.alpha = 0;
        [self.view addSubview:self.disableViewOverlay];
        
        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        self.disableViewOverlay.alpha = 0.6;
        [UIView commitAnimations];
    }
    self.searchText = searchString;
    [self filterContentForSearchText:searchText scope:nil];
    
    [self.tableView reloadData];
}
#pragma mark Content Filtering
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Remove all objects from the filtered search array
	[self.filteredContactArray removeAllObjects];
    
	// Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.fullName contains[c] %@",self.searchText];
    NSArray *tempArray = [self.contacts filteredArrayUsingPredicate:predicate];
    self.filteredContactArray = [NSMutableArray arrayWithArray:tempArray];
}

#pragma mark - TDFollowCellProfileDelegate
- (void)removeFromInviteList:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
    
    // Remove from invite list on
    if (self.inviteList[indexPath.row] != nil) {
        [self.inviteList removeObjectAtIndex:indexPath.row];
        
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
            TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
            revertedCell.actionButton.hidden = YES;
            revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            revertedCell.descriptionLabel.hidden = YES;
            CGRect frame = revertedCell.nameLabel.frame;
            frame.origin.y = MIDDLE_CELL_Y_AXIS;
            revertedCell.nameLabel.frame = frame;
            revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
        }
    }
}

- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber*)userId{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0] ;
    if (self.searchingActive) {
        // Remove from invite list on
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self reformatCellToUnselected:cell];
        
        // Need to reformat on the entire list too
        NSUInteger index = 0;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.id == %@", userId];
        NSArray * selectedObject = [self.contacts filteredArrayUsingPredicate:predicate];
        if (selectedObject){
            index = [self.contacts indexOfObject:selectedObject[0]];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(int)index inSection:0];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self reformatCellToUnselected:cell];
        }
        
    } else {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self reformatCellToUnselected:cell];
    }
    
    // Remove from invite list of this view
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.id <> %@", userId];
    NSArray *filteredArray = [self.inviteList filteredArrayUsingPredicate:predicate];
    [self.inviteList removeAllObjects];
    if ([filteredArray count] > 0) {
        [self.inviteList addObjectsFromArray:filteredArray];
    }
}

- (void)reformatCellToUnselected:(UITableViewCell*)cell {
    if (cell && [cell isKindOfClass:[TDFollowProfileCell class]]) {
        TDFollowProfileCell *revertedCell = (TDFollowProfileCell*)cell;
        revertedCell.actionButton.hidden = YES;
        revertedCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        revertedCell.descriptionLabel.hidden = YES;
        CGRect frame = revertedCell.nameLabel.frame;
        frame.origin.y = MIDDLE_CELL_Y_AXIS;
        revertedCell.nameLabel.frame = frame;
        revertedCell.nameLabel.font = [TDConstants fontRegularSized:16];
    }
}

# pragma mark - setting data from previous controller
- (void)setValuesForSharing:(NSArray *)currentInvite {
    for (id object in currentInvite) {
        [self.inviteList addObject:object];
    }
}

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active {
    if (!active) {
        [disableViewOverlay removeFromSuperview];
        [searchBar resignFirstResponder];
        self.searchText = nil;
    } else {
        self.disableViewOverlay.alpha = 0;
        [self.view addSubview:self.disableViewOverlay];
        
        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        self.disableViewOverlay.alpha = 0.6;
        [UIView commitAnimations];
        
        // probably not needed if you have a details view since you
        // will go there on selection
        NSIndexPath *selected = [self.tableView
                                 indexPathForSelectedRow];
        if (selected) {
            [self.tableView deselectRowAtIndexPath:selected
                                          animated:NO];
        }
    }
}

#pragma mark - Keyboard / Textfield

- (void)keyboardWillHide:(NSNotification *)notification {
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
    [self.tableView scrollToRowAtIndexPath:self.editingIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchBar isFirstResponder] && [touch view] != self.searchBar)
    {
        [self.searchBar resignFirstResponder];
        
    }
    [super touchesBegan:touches withEvent:event];
}

@end
