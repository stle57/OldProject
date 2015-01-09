//
//  TDInterestsViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDInterestsViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDGoalsCell.h"

@interface TDInterestsViewController ()
@property (nonatomic) NSMutableArray *interestList;
@property (nonatomic) NSIndexPath *selectedIndexPath;
@end

static NSString *topHeaderText1 = @"What are your interests?";
static NSString *topHeaderText2 = @"Select all that apply.";
static const int doneBackgroundViewHeight = 80;

@implementation TDInterestsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withBackButton:(BOOL)yes
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.interestList = [NSMutableArray arrayWithObjects:@"Cycling", @"Yoga",
                         @"CrossFit", @"Bodybuilding", @"Marathons", @"Kickboxing", @"MMA", nil];
        self.showBackButton = yes;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH+20, SCREEN_HEIGHT);
    self.view.backgroundColor = [UIColor clearColor];
    
    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor whiteColor];
    [self.alphaView setAlpha:.92];
    [self.view addSubview:self.alphaView];
    
    if (self.showBackButton) {
        self.backButton.frame = CGRectMake(15, 15, [UIImage imageNamed:@"btn_back"].size.width, [UIImage imageNamed:@"btn_back"].size.height);
        [self.alphaView addSubview:self.backButton];
    }
    
    [self createHeaderLabel];
    
    self.tableView.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT - 80 - 100);
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.alphaView addSubview:self.tableView];
    
    CGRect bottomLineRect = self.bottomMargin.frame;
    bottomLineRect.origin.x = 0;
    bottomLineRect.origin.y = SCREEN_HEIGHT - 80;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomMargin.frame = bottomLineRect;
    self.bottomMargin.backgroundColor = [TDConstants commentTimeTextColor];
    [self.alphaView addSubview:self.bottomMargin];
    
    self.doneBackgroundView.frame = CGRectMake(0, self.bottomMargin.frame.origin.y + self.bottomMargin.frame.size.height, SCREEN_WIDTH, doneBackgroundViewHeight);
    self.doneBackgroundView.backgroundColor = [UIColor colorWithRed:(251.0/255.0) green:(250.0/255.0) blue:(249.0/255.0) alpha:1.0];
    [self.alphaView addSubview:self.doneBackgroundView];

    
    self.doneButton.frame = CGRectMake(self.doneBackgroundView.frame.size.width/2 - [UIImage imageNamed:@"btn_okdone"].size.width/2, doneBackgroundViewHeight - 10- [UIImage imageNamed:@"ovals_right"].size.height - 10-[UIImage imageNamed:@"btn_okdone"].size.height, [UIImage imageNamed:@"btn_okdone"].size.width, [UIImage imageNamed:@"btn_okdone"].size.height);
    
    [self.doneBackgroundView addSubview:self.doneButton];
    
    self.pageIndicator.frame = CGRectMake(self.doneBackgroundView.frame.size.width/2 - [UIImage imageNamed:@"ovals_right"].size.width/2, self.doneButton.frame.origin.y + self.doneButton.frame.size.height + 10, [UIImage imageNamed:@"ovals_right"].size.width, [UIImage imageNamed:@"ovals_right"].size.height);
    
    self.pageIndicator.hidden = NO;
    [self.doneBackgroundView addSubview:self.pageIndicator];
    
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
    [self.keyboardObserver startListening];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    debug NSLog(@"interest view frame=%@", NSStringFromCGRect(self.view.frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}

- (IBAction)doneButtonPressed:(id)sender {
    debug NSLog(@"done button pressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(doneButtonPressed)]) {
        [self.delegate doneButtonPressed];
    }
}

#pragma mark UITableViewDataSource delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.interestList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDGoalsCell *cell = (TDGoalsCell *)[tableView dequeueReusableCellWithIdentifier:@"TDGoalsCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGoalsCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        cell.editableTextField.delegate = self;
    }
    
    cell.row = indexPath.row;
    if (indexPath.row == self.interestList.count) {
        [cell createCell:YES text:nil];
        
    } else {
        [cell createCell:NO text:self.interestList[indexPath.row]];
    }
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"row selected");
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.interestList.count) {
        TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            [cell makeCellFirstResponder];
            self.selectedIndexPath = indexPath;
        }
    } else {
        [self selectionButtonPressedFromRow:indexPath.row];
    }
}

#pragma mark TDGoalsCellDelegate
- (void)selectionButtonPressedFromRow:(NSInteger)row {
    debug NSLog(@"selection button pressed, change buttons");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell setSelectionButton];
    }
}

- (void)addGoals:(NSString*)text row:(NSInteger)row{
    [self.interestList addObject:text];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell changeCellToAddGoals];
    }
    
    NSIndexPath *path1 = [NSIndexPath indexPathForRow:self.interestList.count inSection:0]; //ALSO TRIED WITH indexPathRow:0
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)addNewGoalPressed:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark helper methods

- (void)createHeaderLabel {
    self.headerLabel1.frame = CGRectMake(0,
                                         35,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString1 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText1 font:[TDConstants fontSemiBoldSized:18.] color:[TDConstants headerTextColor] lineHeight:18. lineHeightMultipler:18/18];
    [self.headerLabel1 setAttributedText:attString1];
    [self.headerLabel1 setNumberOfLines:0];
    [self.headerLabel1 sizeToFit];
    
    CGRect frame1 = self.headerLabel1.frame;
    frame1.origin.x = SCREEN_WIDTH/2 - self.headerLabel1.frame.size.width/2;
    self.headerLabel1.frame = frame1;
    [self.alphaView addSubview:self.headerLabel1];
    
    UIFont *font2 = [TDConstants fontRegularSized:14.0];
    self.headerLabel2.frame = CGRectMake(0,
                                         self.headerLabel1.frame.origin.y + self.headerLabel1.frame.size.height + 9,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString2 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText2 font:font2 color:[TDConstants headerTextColor] lineHeight:14.0 lineHeightMultipler:(14./14.0)];
    [self.headerLabel2 setAttributedText:attString2];
    [self.headerLabel2 setNumberOfLines:0];
    [self.headerLabel2 sizeToFit];
    
    CGRect frame2 = self.headerLabel2.frame;
    frame2.origin.x = SCREEN_WIDTH/2 - self.headerLabel2.frame.size.width/2;
    frame2.origin.y = self.headerLabel1.frame.origin.y + self.headerLabel1.frame.size.height+ 9;
    self.headerLabel2.frame = frame2;

    [self.alphaView addSubview:self.headerLabel2];
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
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Show the "Add" button
    debug NSLog(@"going to start editing");
    
}

- (void)textFieldDidChange:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    //Show the checkbox
    debug NSLog(@"done editing");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    debug NSLog(@"return button hit");
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
    if (cell) {
        [self addGoals:cell.editableTextField.text row:cell.row];
    }
    return YES;
}

- (IBAction)backButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(backButtonPressed)]) {
        [self.delegate backButtonPressed];
    }
}

@end