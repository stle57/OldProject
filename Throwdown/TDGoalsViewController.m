//
//  TDGoalsViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGoalsViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDAppCoverBackgroundView.h"
#import "TDAnalytics.h"

@interface TDGoalsViewController ()
@property (nonatomic) NSIndexPath *selectedIndexPath;
@end

static NSString *topHeaderText1 = @"Let's personalize your experience.";
static NSString *topHeaderText2 = @"What are your fitness goals?";
static NSString *topHeaderText3 = @"Select all that apply.";
static NSString *continueButtonStr = @"btn_continue";
static NSString *ovalsLeftButtonStr = @"ovals_left";

static const int closeBackgroundViewHeight = 80;
@implementation TDGoalsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withCloseButton:(BOOL)yes goalsList:(NSArray *)goalsList{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if (goalsList == nil) {
            self.goalList =

            [NSMutableArray arrayWithObjects:@{@"name":@"Lose weight",@"selected":@0, @"id":@0},
                                                @{@"name":@"Get back into shape", @"selected":@0, @"id":@0},
                                                @{@"name":@"Tone up", @"selected":@0, @"id":@0},
                                                @{@"name":@"Get stronger", @"selected":@0, @"id":@0},
                                                @{@"name":@"Gain more muscle", @"selected":@0, @"id":@0},
                                                @{@"name":@"Increase endurance", @"selected":@0, @"id":@0},
                                                @{@"name":@"Improve mobility", @"selected":@0, @"id":@0},
                                                @{@"name":@"Become more functionally fit", @"selected":@0, @"id":@0},
                                                @{@"name":@"Develop more self confidence", @"selected":@0, @"id":@0}, nil];
        } else {
            self.goalList = [goalsList mutableCopy];
        }

        self.showCloseButton = yes;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH+20, SCREEN_HEIGHT); // +20 is to extend the frame for the scrollview offset(inside autolayout)
    self.view.backgroundColor = [UIColor clearColor];
    
    if (self.showCloseButton) {
        self.closeButton.frame = CGRectMake(15, [UIApplication sharedApplication].statusBarFrame.size.height, [UIImage imageNamed:@"btn_x"].size.width, [UIImage imageNamed:@"btn_x"].size.height);
        [self.view addSubview:self.closeButton];

        
        //- Adjust the size of the button to have a larger tap area
        self.closeButton.frame = CGRectMake(self.closeButton.frame.origin.x -10,
                                            self.closeButton.frame.origin.y -10,
                                            self.closeButton.frame.size.width + 20,
                                            self.closeButton.frame.size.height + 20);
    }
    
    [self createHeaderLabel];
    
    self.tableView.frame = CGRectMake(0, 125, SCREEN_WIDTH, SCREEN_HEIGHT - closeBackgroundViewHeight - 125);
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    CGRect bottomLineRect = self.bottomMargin.frame;
    bottomLineRect.origin.x = 0;
    bottomLineRect.origin.y = SCREEN_HEIGHT - closeBackgroundViewHeight;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomMargin.frame = bottomLineRect;
    self.bottomMargin.backgroundColor = [TDConstants commentTimeTextColor];
    [self.view addSubview:self.bottomMargin];
    
    self.closeButtonBackgroundView.frame = CGRectMake(0,
                                                      self.bottomMargin.frame.origin.y + self.bottomMargin.frame.size.height,
                                                      SCREEN_WIDTH+20,
                                                      closeBackgroundViewHeight);
    UIColor *color = [[UIColor alloc] initWithRed:(251./255.) green:(250./255.) blue:(249./255.) alpha:1];
    [self.closeButtonBackgroundView setBackgroundColor:[UIColor whiteColor]];
    [self.closeButtonBackgroundView setTintColor:color];
    [self.view addSubview:self.closeButtonBackgroundView];
    
    self.continueButton.frame = CGRectMake(
                                           (self.closeButtonBackgroundView.frame.size.width-20)/2 - [UIImage imageNamed:continueButtonStr].size.width/2,//-20 on the width because we extended the view to cover the extra space in the scroll view
                                           self.closeButtonBackgroundView.frame.size.height - 10 - [UIImage imageNamed:ovalsLeftButtonStr].size.height - 10 - [UIImage imageNamed:continueButtonStr].size.height,
                                           [UIImage imageNamed:continueButtonStr].size.width,
                                           [UIImage imageNamed:continueButtonStr].size.height);
    
    [self.closeButtonBackgroundView addSubview:self.continueButton];
    
    self.pageIndicator.frame = CGRectMake(
                                          (self.closeButtonBackgroundView.frame.size.width-20)/2 - [UIImage imageNamed:ovalsLeftButtonStr].size.width/2, //-20 on the width because we extended the view to cover the extra space in the scroll view
                                          self.continueButton.frame.origin.y + self.continueButton.frame.size.height + 10,
                                          [UIImage imageNamed:ovalsLeftButtonStr].size.width,
                                          [UIImage imageNamed:ovalsLeftButtonStr].size.height);
    
    self.pageIndicator.hidden = NO;
    [self.closeButtonBackgroundView addSubview:self.pageIndicator];
    
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
    [self.keyboardObserver startListening];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[TDAnalytics sharedInstance] logEvent:@"goals_view"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}

- (IBAction)continueButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(continueButtonPressed:)]) {
        [self.delegate continueButtonPressed:self.goalList];
    }
}

- (IBAction)closeButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeButtonPressed)]) {
        [self.delegate closeButtonPressed];
    }
}

#pragma mark UITableViewDataSource delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.goalList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.goalList.count+1 == indexPath.row) {
        return 59; // This is for the last row +(Add More)
    } else {
        return 44;
    }
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
    cell.selectionButton.tag = 0;
    if (indexPath.row == self.goalList.count) {
        [cell createCell:YES text:nil selected:NO];

    } else {
        NSDictionary *dict = self.goalList[indexPath.row];
        BOOL selected = [[dict objectForKey:@"selected"] boolValue] ;
        NSString *goalName = [dict objectForKey:@"name"];

        [cell createCell:NO text:goalName selected:selected];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.goalList.count) {
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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell goalSelected:(cell.selectionButton.tag == 0) ? YES : NO];
        // take out of the list
        NSMutableDictionary *dict = [[self.goalList objectAtIndex:row] mutableCopy];
        if ([[dict valueForKey:@"selected"] boolValue] == YES) {
            [dict setValue:@0 forKey:@"selected"];
            self.goalList[row] = dict;
        } else {
            [dict setValue:@1 forKey:@"selected"];
            self.goalList[row] = dict;
        }
    }
}

- (void)addGoals:(NSString*)text row:(NSInteger)row{
    NSDictionary *tempDict = @{@"name":text, @"selected":@1, @"id":[[NSNumber numberWithLong:(row+1)] stringValue]};
    [self.goalList addObject:tempDict];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell changeCellToAddGoals];
    }
    
    NSIndexPath *path1 = [NSIndexPath indexPathForRow:self.goalList.count inSection:0]; //ALSO TRIED WITH indexPathRow:0
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    
    //Create indexPath for row below, so we can scroll to it
    NSIndexPath *addMoreRowIndexPath = [NSIndexPath indexPathForRow:row+1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:addMoreRowIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];

}

- (void)addNewGoalPressed:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark helper methods

- (void)createHeaderLabel {
    UIFont *font = [TDConstants fontRegularSized:15.0];
    self.headerLabel1.frame = CGRectMake(0, 35, SCREEN_WIDTH, 100);
    NSAttributedString *attString = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText1 font:font color:[TDConstants headerTextColor] lineHeight:15. lineHeightMultipler:15./15.];
    [self.headerLabel1 setAttributedText:attString];
    [self.headerLabel1 setNumberOfLines:0];
    [self.headerLabel1 sizeToFit];
    
    CGRect frame = self.headerLabel1.frame;
    frame.origin.x = SCREEN_WIDTH/2 - self.headerLabel1.frame.size.width/2;
    self.headerLabel1.frame = frame;
    [self.view addSubview:self.headerLabel1];
    
    self.headerLabel2.frame = CGRectMake(0,
                                         self.headerLabel1.frame.origin.y + self.headerLabel1.frame.size.height + 9,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString2 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText2 font:[TDConstants fontSemiBoldSized:18.] color:[TDConstants headerTextColor] lineHeight:18. lineHeightMultipler:18/18];
    [self.headerLabel2 setAttributedText:attString2];
    [self.headerLabel2 setNumberOfLines:0];
    [self.headerLabel2 sizeToFit];
    
    CGRect frame2 = self.headerLabel2.frame;
    frame2.origin.x = SCREEN_WIDTH/2 - self.headerLabel2.frame.size.width/2;
    self.headerLabel2.frame = frame2;
    [self.view addSubview:self.headerLabel2];
    
    UIFont *font3 = [TDConstants fontRegularSized:14.0];
    self.headerLabel3.frame = CGRectMake(0,
                                         self.headerLabel2.frame.origin.y + self.headerLabel2.frame.size.height + 9,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString3 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText3 font:font3 color:[TDConstants headerTextColor] lineHeight:14.0 lineHeightMultipler:(14./14.0)];
    [self.headerLabel3 setAttributedText:attString3];
    [self.headerLabel3 setNumberOfLines:0];
    [self.headerLabel3 sizeToFit];
    
    CGRect frame3 = self.headerLabel3.frame;
    frame3.origin.x = SCREEN_WIDTH/2 - self.headerLabel3.frame.size.width/2;
    frame3.origin.y = self.headerLabel2.frame.origin.y + self.headerLabel2.frame.size.height+ 9;
    self.headerLabel3.frame = frame3;

    [self.view addSubview:self.headerLabel3];
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
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
    if (cell) {
        [self addGoals:cell.editableTextField.text row:cell.row];
    }
    return YES;
}


@end
