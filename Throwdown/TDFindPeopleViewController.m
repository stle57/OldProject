//
//  TDFindPeopleViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 10/15/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFindPeopleViewController.h"
#import "UIActionSheet+Blocks.h"
#import "TDUserAPI.h"
#import "TDAPIClient.h"
#import "TDViewControllerHelper.h"
#import "TDInviteViewController.h"
#import "TDUserProfileViewController.h"
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@implementation TDFindPeopleViewController
@synthesize filteredUsersArray;
@synthesize tdUsers;
@synthesize suggestedUsers;
@synthesize origNameLabelYAxis;
@synthesize origNameLabelFrame;
@synthesize inviteList;
@synthesize gotFromServer;
@synthesize currentRow;
@synthesize profileUser;
@synthesize searchingActive;
@synthesize disableViewOverlay;
@synthesize headerView;
@synthesize emptyCell;
@synthesize editingIndexPath;

- (void)dealloc {
    self.tdUsers = nil;
    self.suggestedUsers = nil;
    self.filteredUsersArray = nil;
    self.inviteList = nil;
    self.labels = nil;
    self.profileUser = nil;
    self.searchText = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        tdUsers = [[NSMutableArray alloc] init];
        inviteList = [[NSMutableArray alloc] init];
        self.labels = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,44.0f,SCREEN_WIDTH,SCREEN_HEIGHT-self.navigationController.navigationBar.frame.size.height - self.searchBar.frame.size.height)];
    self.disableViewOverlay.backgroundColor=[UIColor blackColor];
    self.disableViewOverlay.alpha = 0;
    
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    [navigationBar setOpaque:YES];
    
    self.inviteButton.hidden = NO;
    self.inviteButton.titleLabel.font = [TDConstants fontRegularSized:18];
    self.inviteButton.titleLabel.textColor = [UIColor whiteColor];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.inviteButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;

    CGRect inviteFrame = self.inviteButton.frame;
    inviteFrame.origin.y = 7;
    inviteFrame.origin.x = 270;
    self.inviteButton.frame = inviteFrame;

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
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextAlignment:NSTextAlignmentLeft];
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 25)];
    UILabel *suggestedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, SCREEN_WIDTH, 25)];
    suggestedLabel.text = @"Suggested people to follow";
    suggestedLabel.font = [TDConstants fontRegularSized:13.0];
    suggestedLabel.textColor = [TDConstants helpTextColor];
     
    [self.headerView addSubview:suggestedLabel];
    self.tableView.tableHeaderView = self.headerView;

    // Title
    self.navLabel.text = @"Find People";
    self.inviteButton.hidden = NO;

    self.filteredUsersArray = [NSMutableArray arrayWithCapacity:[tdUsers count]];

    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
    emptyCell = [topLevelObjects objectAtIndex:0];
    emptyCell.selectionStyle = UITableViewCellSelectionStyleNone;
    emptyCell.delegate = self;
    emptyCell.noFollowLabel.hidden = YES;
    emptyCell.invitePeopleButton.hidden = YES;
    emptyCell.findPeopleButton.hidden = YES;
    emptyCell.backgroundColor = [TDConstants lightBackgroundColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userFollowed:) name:TDNotificationUserFollow object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUnfollowed:) name:TDNotificationUserUnfollow object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUserList) name:TDUserListLoadedFromBackground object:nil];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants commentTimeTextColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[TDConstants fontRegularSized:16.0]];

    CGRect frame = self.searchBar.frame;
    frame.size.width = SCREEN_WIDTH;
    self.searchBar.frame = frame;
    [self.searchBar sizeToFit];

    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.width = SCREEN_WIDTH;
    tableFrame.size.height = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height - self.searchBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    self.tableView.frame = tableFrame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)loadData {
    self.gotFromServer = NO;
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    // Load data from server
    [[TDUserAPI sharedInstance] getSuggestedUserList:^(BOOL success, NSArray *suggestedList) {
        if (success && suggestedList && suggestedList.count > 0) {
            self.suggestedUsers = [suggestedList copy];
            [self loadUserList];
        } else {
            self.gotFromServer = NO;
            [self hideActivity];
        }
    }];


}

- (void)loadUserList {
    debug NSLog(@"  inside loadUserList");
    [[TDUserList sharedInstance] getListWithCallback:^(NSArray *returnList) {
        if (returnList && returnList.count > 0) {
            self.tdUsers = [returnList copy];
            if (self.searchText.length > 0) {
                [self filterContentForSearchText:self.searchText scope:nil];
            }
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        }
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews{
    [self.searchBar setShowsCancelButton:NO animated:NO];
}

- (IBAction)backButtonHit:(id)sender {
    [self leave];
}

- (void) leave {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)inviteButtonHit:(id)sender {
    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Follow and unfollow notification

- (void)userFollowed:(NSNotification *)n {
    self.filteredUsersArray = [self changeFollowingForUserId:n.object to:YES inList:self.filteredUsersArray];
    self.suggestedUsers = [self changeFollowingForUserId:n.object to:YES inList:self.suggestedUsers];
    self.tdUsers = [self changeFollowingForUserId:n.object to:YES inList:self.tdUsers];
    [self.tableView reloadData];
}

- (void)userUnfollowed:(NSNotification *)n {
    self.filteredUsersArray = [self changeFollowingForUserId:n.object to:NO inList:self.filteredUsersArray];
    self.suggestedUsers = [self changeFollowingForUserId:n.object to:NO inList:self.suggestedUsers];
    self.tdUsers = [self changeFollowingForUserId:n.object to:NO inList:self.tdUsers];
    [self.tableView reloadData];
}

- (NSMutableArray *)changeFollowingForUserId:(NSNumber *)userId to:(BOOL)following inList:(NSArray *)list {
    if (list) {
        NSMutableArray *newList = [[NSMutableArray alloc] init];
        for (int c = 0; c < [list count]; c++) {
            NSDictionary *user = [list objectAtIndex:c];
            if ([[user objectForKey:@"id"] isEqualToNumber:userId]) {
                NSMutableDictionary *newUser = [user mutableCopy];
                [newUser setObject:[[NSNumber alloc] initWithBool:following] forKey:@"following"];
                [newList addObject:newUser];
            } else {
                [newList addObject:user];
            }
        }
        return newList;
    }
    return nil;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchingActive) {
        if (self.filteredUsersArray == nil || [self.filteredUsersArray count] == 0) {
            if ([self.searchText isEqual:@""]) {
                return 65;
            } else {
                [self createLabels];
                UILabel *label = [self.labels objectAtIndex:0];
                UILabel *label2 = [self.labels objectAtIndex:1];
                return 30 + label.frame.size.height + 7 + label2.frame.size.height + 30 + [UIImage imageNamed:@"btn-invite-friends.png"].size.height+ self.headerView.frame.size.height;
            }
        } else {
            // Calculate the height of the labels
            return 65.0;
        }
    } else {
        return 65.0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.gotFromServer) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.gotFromServer) {
        if (self.searchingActive) {
            if ([self.searchText isEqual:@""]) {
                // If count is 0, we should show suggested user list!
                [self.view addSubview:self.disableViewOverlay];
                return [suggestedUsers count];
            } else if ([filteredUsersArray count] == 0){
                return 1;
            } else {
                return [filteredUsersArray count];
            }
        } else {
            if ([suggestedUsers count] == 0) {
                return 1;
            } else {
                return [suggestedUsers count];
            }
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger current = indexPath.row;
    if (!self.searchingActive) {
        if ([suggestedUsers count] == 0) {
            return emptyCell;
        } else {
            NSArray *object = [self.suggestedUsers objectAtIndex:current];
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
        }
        
    } else {
        self.tableView.tableHeaderView = nil;
        if ([self.searchText isEqual:@""]) {
            self.tableView.tableHeaderView = self.headerView;
            // Need to show the suggested list
            NSArray *object = [self.suggestedUsers objectAtIndex:current];
            
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
            
        } else if (filteredUsersArray.count == 0) {
            TDNoFollowProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowProfileCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowProfileCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.delegate = self;
            }
            
            cell.contentView.backgroundColor = [UIColor whiteColor];
            tableView.backgroundColor = [UIColor whiteColor];
            cell.noFollowLabel.text = @"No matches found";
            
            cell.findPeopleButton.hidden = YES;
            cell.findPeopleButton.enabled = NO;
            
            cell.invitePeopleButton.hidden = NO;
            cell.invitePeopleButton.enabled = YES;
            cell.noFollowLabel.hidden = NO;
            UILabel *descriptionLabel = [self.labels objectAtIndex:1];
            
            CGRect descripFrame = descriptionLabel.frame;
            descripFrame.origin.y = cell.noFollowLabel.frame.origin.y + cell.noFollowLabel.frame.size.height + 7;
            descripFrame.origin.x = SCREEN_WIDTH/2 - descripFrame.size.width/2;
            descriptionLabel.frame = descripFrame;
            [descriptionLabel setNumberOfLines:0];
            [cell addSubview:descriptionLabel];
            
            CGRect frame = cell.invitePeopleButton.frame;
            frame.origin.x = SCREEN_WIDTH/2 - cell.invitePeopleButton.frame.size.width/2;
            frame.origin.y = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 30;
            cell.invitePeopleButton.frame = frame;
            
            self.tableView.backgroundColor = [UIColor whiteColor];
            return cell;
        } else {
            NSArray *object = [self.filteredUsersArray objectAtIndex:indexPath.row];
            TDFollowProfileCell *cell = [self createCell:indexPath tableView:tableView object:object];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (TDFollowProfileCell*)createCell:(NSIndexPath*)indexPath tableView:(UITableView*)tableView object:(NSArray*)object{
    BOOL adjustHeightCell = NO;
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    

    cell.userId = [object valueForKey:@"id"];
    cell.row = indexPath.row;
    cell.topLine.hidden = cell.row != 0;

    NSAttributedString *usernameAttStr = nil;
    NSString *str = [NSString stringWithFormat:@"%@", [object valueForKey:@"bio"]];
    if (str == nil || str.length == 0 || [[object valueForKey:@"bio"] isKindOfClass:[NSNull class]]) {
        str = [NSString stringWithFormat:@"@%@", [object valueForKey:@"username"]];
        usernameAttStr = [TDViewControllerHelper makeParagraphedTextWithString:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
    } else {
        // Need to adjust the height of label to accomodate for emojis in BIO
        adjustHeightCell = YES;
        usernameAttStr = [TDViewControllerHelper makeParagraphedTextForTruncatedBio:str font:[TDConstants fontRegularSized:13.0] color:[TDConstants headerTextColor] lineHeight:16.0];
    }
    
    cell.descriptionLabel.attributedText = usernameAttStr;
    
    if (adjustHeightCell) {
        [cell.descriptionLabel sizeToFit];
        
        CGRect frame = cell.descriptionLabel.frame;
        frame.size.height = frame.size.height +5;
        frame.size.width = cell.descriptionLabelOrigWidth;
        cell.descriptionLabel.frame = frame;
    }
    
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:[object valueForKey:@"name"] font:[TDConstants fontSemiBoldSized:16] color:[TDConstants brandingRedColor] lineHeight:19.0];
    cell.nameLabel.attributedText = attString;
    
    cell.userImageView.hidden = NO;
    cell.userImageView.image = nil;
    if ([object valueForKey:@"picture"] != [NSNull null] && ![[object valueForKey:@"picture"] isEqualToString:@"default"]) {
        [self downloadUserImage:[object valueForKeyPath:@"picture"] cell:cell];
    } else {
        cell.userImageView.image = [UIImage imageNamed:@"prof_pic_default"];
    }

    
    BOOL following = [[object valueForKey:@"following"] boolValue];
    
    if (!following) {
        // Not follow - change action button
        UIImage * buttonImage = [UIImage imageNamed:@"btn-small-follow.png"];
        [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateHighlighted];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-follow-hit.png"] forState:UIControlStateSelected];
        
        [cell.actionButton setTag:kFollowButtonTag];
    } else {
        UIImage * buttonImage = [UIImage imageNamed:@"btn-small-following.png"];
        [cell.actionButton setImage:buttonImage forState:UIControlStateNormal];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateHighlighted];
        [cell.actionButton setImage:[UIImage imageNamed:@"btn-small-following-hit.png"] forState:UIControlStateSelected];
        [cell.actionButton setTag:kFollowingButtonTag];
    }
    
    if ([cell.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
        cell.actionButton.hidden = YES;
    } else {
        cell.actionButton.hidden = NO;
    }
    return cell;
}

- (void)downloadUserImage:(NSString *)profileImage cell:(TDFollowProfileCell *)cell {
    cell.userImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", RSHost, profileImage]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:cell.userImageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        CGFloat width = cell.userImageView.frame.size.width * [UIScreen mainScreen].scale;
        image = [image scaleToSize:CGSizeMake(width, width)];
        if (![finalURL isEqual:cell.userImageURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cell.userImageView) {
                    cell.userImageView.image = image;
                }
            });
        }
    }];
}

- (void)createLabels {
    NSString *text1 = @"No matches found";
    UILabel *noMatchesLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 30, SCREEN_WIDTH, 100)];
    noMatchesLabel.text = text1;
    noMatchesLabel.font = [TDConstants fontSemiBoldSized:16.0];
    noMatchesLabel.textColor = [TDConstants headerTextColor];
    [noMatchesLabel sizeToFit];
    
    [self.labels addObject:noMatchesLabel];
    
    NSString *text2 = @"Sorry, we weren't able to find the\nperson you're looking for.\n Invite them to join Throwndown!";
    
    UILabel *descriptionLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:text2 font:[TDConstants fontRegularSized:15.0] color:[TDConstants headerTextColor] lineHeight:19.0 lineHeightMultipler:(19.0/15.0)];
    descriptionLabel.attributedText = attString;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel sizeToFit];
    [self.labels addObject:descriptionLabel];
    
}

#pragma mark UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchingActive = YES;
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[TDConstants headerTextColor]];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    
    [self searchBar:searchBar activate:YES];
    [self searchBar:self.searchBar textDidChange:self.searchBar.text];
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        [disableViewOverlay removeFromSuperview];
    }
    
    self.searchText = searchText;
    [self filterContentForSearchText:searchText scope:nil];

    [self.tableView reloadData];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchBar isFirstResponder] && [touch view] != self.searchBar)
    {
        [self.searchBar resignFirstResponder];

    }
    [super touchesBegan:touches withEvent:event];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.searchingActive = NO;
    [self searchBar:self.searchBar activate:NO];
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredUsersArray removeAllObjects];

    // Filter the arraphy using NSPredicate
    NSString *regexString = [NSString stringWithFormat:@".*\\B%@.*", searchText];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.username matches[c] %@) OR (SELF.name matches[c] %@)", regexString, regexString];
    NSArray *tempArray = [self.tdUsers filteredArrayUsingPredicate:predicate];
    self.filteredUsersArray = [NSMutableArray arrayWithArray:tempArray];
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

#pragma mark - TDFollowCellProfileDelegate

- (void)showActivity {
    self.backButton.enabled = NO;
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

#pragma mark - TDFollowProfileCellDelegate
- (void)inviteButtonPressed {
    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)userProfilePressedWithId:(NSNumber *)userId {
    [self showUserProfile:userId];
}

- (void)showUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TDFollowCellProfileDelegate
- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber *)userId{
    self.currentRow = row;
    
    if (tag == kFollowButtonTag) {
        [[TDUserAPI sharedInstance] followUser:userId callback:^(BOOL success) {
            if (!success) {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
            }
        }];

    } else if (tag == kFollowingButtonTag) {

        NSString *reportText = [NSString stringWithFormat:@"Unfollow @%@", [[(self.searchingActive ? self.filteredUsersArray : self.suggestedUsers) objectAtIndex:row] valueForKeyPath:@"username"]];
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:reportText
                                                         otherButtonTitles:nil, nil];
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSNumber *userId = nil;
    if (self.searchingActive) {
        userId = [[self.filteredUsersArray objectAtIndex:self.currentRow] valueForKey:@"id"];
    } else {
        userId = [[self.suggestedUsers objectAtIndex:self.currentRow] valueForKeyPath:@"id"];
    }

    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [[TDUserAPI sharedInstance] unFollowUser:userId callback:^(BOOL success) {
            if (!success) {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
            }
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active{
    self.tableView.allowsSelection = !active;
    if (!active) {
        [disableViewOverlay removeFromSuperview];
        [searchBar resignFirstResponder];
        self.tableView.tableHeaderView = self.headerView;
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

@end
