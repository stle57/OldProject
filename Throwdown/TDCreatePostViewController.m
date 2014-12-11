//
//  TDCreatePostViewController.m
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCreatePostViewController.h"
#import "TDSharePostViewController.h"
#import "TDViewControllerHelper.h"
#import "TDTextViewControllerHelper.h"
#import "UIPlaceHolderTextView.h"
#import "TDConstants.h"
#import "TDAnalytics.h"
#import "TDPostAPI.h"
#import "TDSlideUpSegue.h"
#import "TDUnwindSlideLeftSegue.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDUserAPI.h"
#import "TDAPIClient.h"
#import "TDUserListView.h"
#import "TDKeyboardObserver.h"
#import "TDCreatePostHeaderCell.h"
#import "CSStickyHeaderFlowLayout.h"
#import "TDPhotoCellCollectionViewCell.h"
#import "TDLocationViewController.h"
#import "TDEditVideoViewController.h"

#import "TDAppDelegate.h"

//static int const kTextViewConstraint = 84;
//static int const kTextViewHeightWithUserList = 70;
static int const kCellPerRow = 3;
@interface TDCreatePostViewController () <UITextViewDelegate>
@property (nonatomic)  TDCreatePostHeaderCell *postHeaderCell;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIView *hitStateOverlay;
@property (nonatomic) UIView *viewOverlay;
@property (nonatomic, retain) UIViewController *overlayVc;
@property (nonatomic, strong) UINib *headerNib;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *assets;
@property (nonatomic) CGPoint origContentOffset;
@property (nonatomic) NSURL *recordedURL;
@property (nonatomic) NSURL *croppedURL;
@property (nonatomic) NSURL *assetURL;
@property (nonatomic) UIImage *assetImage;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;

//@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;
//@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
//@property (weak, nonatomic) IBOutlet UILabel *labelPR;
//@property (weak, nonatomic) IBOutlet UILabel *labelMedia;
//@property (weak, nonatomic) IBOutlet UILabel *labelLocation;
//@property (weak, nonatomic) IBOutlet UIButton *mediaButton;
//@property (weak, nonatomic) IBOutlet UIButton *locationButton;
//@property (weak, nonatomic) IBOutlet UIButton *prButton;
//@property (weak, nonatomic) IBOutlet UIView *topLineView;
//@property (weak, nonatomic) IBOutlet UIView *optionsView;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;f

@property (nonatomic) BOOL isOriginal;
@property (nonatomic) BOOL isPR;
@property (nonatomic) BOOL minimizeIconIsShowing;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) TDUserListView *userListView;
@property (nonatomic) UIImage *prOnImage;
@property (nonatomic) UIImage *prOffImage;
@property (nonatomic) BOOL location;
@property (nonatomic) NSDictionary *locationData;
@property (nonatomic) float cellLength;
//@property (nonatomic) TDKeyboardObserver *keyboardObserver;

@end

@implementation TDCreatePostViewController
+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.headerNib = [UINib nibWithNibName:CELL_IDENTIFIER_CREATE_POSTHEADER bundle:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_loaded"];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    navigationBar.translucent = NO;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:18],
                                             NSForegroundColorAttributeName: [UIColor whiteColor] }];

    UIButton *button = [TDViewControllerHelper navCloseButton];
    [button addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
   
    CSStickyHeaderFlowLayout *layout = [[CSStickyHeaderFlowLayout alloc] init];
    // Create the header size.
    layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.size.width, SCREEN_HEIGHT/2-15);

    //layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.view.frame.size.width, 0);
    layout.itemSize = CGSizeMake(self.cellLength, self.cellLength);
    layout.parallaxHeaderAlwaysOnTop = YES;
//    layout.minimumInteritemSpacing = 1.25;
//    layout.minimumLineSpacing = 1.25;
    // If we want to disable the sticky header effect
    layout.disableStickyHeaders = YES;

    self.collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    // Also insets the scroll indicator so it appears below the search bar
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    [self.collectionView registerNib:self.headerNib
          forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader
                 withReuseIdentifier:CELL_IDENTIFIER_CREATE_POSTHEADER];
    
    [self.collectionView registerClass:[TDPhotoCellCollectionViewCell class] forCellWithReuseIdentifier:@"TDPhotoCellCollectionViewCell"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.collectionView];
    
    self.viewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
    self.viewOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];

    self.overlayVc = [[UIViewController alloc] init];
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];

    if (status == ALAuthorizationStatusAuthorized) {
        [self loadPhotoAlbum];
    }
    
    [self.postHeaderCell.commentTextView becomeFirstResponder];
    
    float spacingPixelTotal = 2.5 *(kCellPerRow+1);
    self.cellLength= (SCREEN_WIDTH - spacingPixelTotal)/kCellPerRow;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    if (self.minimizeIconIsShowing) {
        UIButton *button = [TDViewControllerHelper navCloseButton];
        [button addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.minimizeIconIsShowing = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.postHeaderCell.mediaButton.enabled = YES;
    //[self.postHeaderCell.keyboardObserver startListening];
    [self.postHeaderCell.commentTextView becomeFirstResponder];
    
    CSStickyHeaderFlowLayout *layout =  (id)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        layout.parallaxHeaderReferenceSize = CGSizeMake(SCREEN_WIDTH, self.postHeaderCell.commentTextView.frame.size.height + self.postHeaderCell.optionsView.frame.size.height + 15); // 15 is kTextViewMargin from postheadercell
    }
    //[self minimizeButtonPressed];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.postHeaderCell.commentTextView resignFirstResponder];
    [self.postHeaderCell.keyboardObserver stopListening];
}

- (void)dealloc {
    //self.commentTextView.delegate = nil;
    [self.userListView removeFromSuperview];
    self.userListView.delegate = nil;
    self.userListView = nil;
    self.thumbnailPath = nil;
    self.filename = nil;
    self.isOriginal = NO;
    self.headerNib = nil;
    self.postHeaderCell = nil;
    self.viewOverlay = nil;
}

- (void) loadPhotoAlbum {
    // Load photo library
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    // 1
    ALAssetsLibrary *assetsLibrary = [TDCreatePostViewController defaultAssetsLibrary];
    // 2
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result)
            {
                // 3
                [[TDCurrentUser sharedInstance] didAskForPhotos:YES];
                [tmpAssets addObject:result];
            }
        }];

        // 4
        //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
        self.assets = tmpAssets;
        
        // 5
        //[self.collectionView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
    

}
- (void)cancelUpload {
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled object:nil userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

#pragma mark - segue / vc to vc interface

- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original {
    if( self.postHeaderCell != nil) {
        self.filename = filename;
        self.thumbnailPath = thumbnailPath;
        self.isOriginal = original;
        [self.postHeaderCell addMedia:filename thumbnail:thumbnailPath isOriginal:original];
        self.postButton.enabled = YES;
    }
}

#pragma mark - Keyboard / TextView management

- (void)removeButtonPressed {
    [self cancelUpload];
    self.thumbnailPath = nil;
    self.filename = nil;
    self.isOriginal = NO;
    self.postButton.enabled = [[self.postHeaderCell.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
}

- (IBAction)unwindToShareView:(UIStoryboardSegue *)sender {
    // Empty on purpose
}

- (IBAction)unwindToCreatePostView:(UIStoryboardSegue *)sender {
    // Empty on purpose
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {

    if ([@"MediaCloseSegue" isEqualToString:identifier]) {
        return [[TDSlideUpSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else if ([@"ReturnToComposeView" isEqualToString:identifier]) {
        return [[TDUnwindSlideLeftSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else {
        return [super segueForUnwindingToViewController:toViewController
                                     fromViewController:fromViewController
                                             identifier:identifier];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.assets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TDPhotoCellCollectionViewCell *cell = (TDPhotoCellCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TDPhotoCellCollectionViewCell" forIndexPath:indexPath];
    CGRect frame = cell.frame;
    frame.size.width = self.cellLength;
    frame.size.height = self.cellLength;
    cell.frame = frame;
    if (indexPath.section == 0 && indexPath.row == 0) {
        UIImage * image = [UIImage imageNamed:@"select_camera.png"];
        UIImageView *cameraImageView =[[UIImageView alloc] initWithImage:image];
        CGRect cameraFrame = cameraImageView.frame;
        cameraFrame.size.height = self.cellLength;
        cameraFrame.size.width = self.cellLength;
        cameraImageView.frame = cameraFrame;
        [cell addSubview:cameraImageView];
        //cell.backgroundColor = [UIColor redColor];
        
    } else {
        ALAsset *asset = self.assets[indexPath.row];
        cell.asset = asset;
        
        UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
        NSLog(@"image.size=%@", NSStringFromCGSize(image.size));
        UIImageView* photoImageView = [[UIImageView alloc] initWithImage:image];
        CGRect photoFrame = photoImageView.frame;
        photoFrame.size.height = self.cellLength;
        photoFrame.size.width = self.cellLength;
        photoImageView.frame = photoFrame;
        
        [cell addSubview:photoImageView];
        photoImageView.contentMode = UIViewContentModeScaleAspectFit;
        photoImageView.clipsToBounds = YES;
        cell.backgroundColor = [UIColor redColor];
    }

    return cell;
}


#pragma mark - UICollectionViewDelegate
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSDictionary *obj = self.sections[indexPath.section];
        
        TDPhotoCellCollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:@"sectionHeader"
                                                                 forIndexPath:indexPath];
        
    } else if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                            withReuseIdentifier:CELL_IDENTIFIER_CREATE_POSTHEADER
                                                                                   forIndexPath:indexPath];
        if ([cell isKindOfClass:[TDCreatePostHeaderCell class]]) {
            self.postHeaderCell = (TDCreatePostHeaderCell*)cell;
            self.postHeaderCell.delegate = self;
            [self.postHeaderCell.commentTextView becomeFirstResponder];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UI buttons

- (void)closeButtonPressed {
    [self cancelUpload];
    [self performSegueWithIdentifier:@"VideoCloseSegue" sender:self];
}

- (IBAction)postButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"OpenShareWithViewSegue" sender:self];
}

- (void)minimizeButtonPressed {
    // Go back to showing the comment text view.
    [self.collectionView setContentOffset:self.origContentOffset animated:NO];
}

#pragma mark TDCreatePostHeaderCellDelegate Methods
- (void)mediaButtonPressed {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    if (status != ALAuthorizationStatusAuthorized && [[TDCurrentUser sharedInstance] didAskForPhotos] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested" message:@"To access your photo library, please go to iPhone Settings > Privacy > Photos, and switch Throwdown to ON" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        if (!self.assets.count) {
            [self loadPhotoAlbum];
        }
        [self.collectionView reloadData];
        self.origContentOffset = [self.collectionView contentOffset];
    }
 }

- (void)locationButtonPressed {
    [self openLocationViewController];
 }

- (void)prButtonPressed {
    self.isPR = !self.isPR;
}

-(void)postButtonEnabled:(BOOL)enable {
    self.postButton.enabled = enable;
}

- (void)openLocationViewController {
    TDLocationViewController *vc = [[TDLocationViewController alloc] initWithNibName:@"TDLocationViewController" bundle:nil ];
    vc.delegate = self;
    //vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) showLocationActionSheet:location {
    NSString *newPlaceStr = @"Select Another Place";
    NSString *removeStr = @"Remove Location";
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:location
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:newPlaceStr
                                                        otherButtonTitles:removeStr, nil];
        //[self addOverlay];
        [actionSheet showInView:self.viewOverlay];
    } else {
        debug NSLog(@"location=%@", location);
        NSString *address = [TDViewControllerHelper getAddressFormat:self.locationData];
        NSString *title = [self.locationData objectForKey:@"name"];
        if (address.length) {
            title = [title stringByAppendingFormat:@"\n%@", address];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title  message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* selectAnotherLocationAction = [UIAlertAction actionWithTitle:newPlaceStr style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self openLocationViewController];
                                                              }];
        UIAlertAction *removeLocationAction =[UIAlertAction actionWithTitle:removeStr style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        if(self.postHeaderCell) {
                                                                            self.location = NO;
                                                                            [self.postHeaderCell changeLocationButton:@"Location" locationSet:self.location];
                                                                        }
                                                                    }];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        
        [alert addAction:selectAnotherLocationAction];
        [alert addAction:removeLocationAction];
        [alert addAction:cancel];
        alert.view.tintColor = [TDConstants headerTextColor];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"EditVideoSegue" isEqualToString:segue.identifier]) {
        TDEditVideoViewController *vc = [segue destinationViewController];
        if (self.assetURL) {
                [vc editVideoAt:[self.assetURL path] original:NO];
                self.assetURL = nil;
        } else if (self.croppedURL) {
            [vc editVideoAt:[self.croppedURL path] original:YES];
            self.croppedURL = nil;
        } else if (self.assetImage) {
            [vc editImage:self.assetImage];
            self.assetImage = nil;
        } else {
            NSString *filename = [NSHomeDirectory() stringByAppendingPathComponent:kPhotoFilePath];
            //[vc editPhotoAt:filename metadata:self.currentCaptureMetadata];
            //self.currentCaptureMetadata = nil;
        }
    } else if ([@"OpenShareWithViewSegue" isEqualToString:segue.identifier]) {
        NSString *comment = [self.postHeaderCell.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        TDSharePostViewController *vc = [segue destinationViewController];
        [vc setValuesForSharing:self.filename withComment:comment isPR:self.isPR userGenerated:self.isOriginal locationData:self.locationData];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cellLength, self.cellLength);
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        if (self.filename) {
            if (self.isOriginal) {
                UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Delete?" message:nil delegate:self cancelButtonTitle:@"Keep" otherButtonTitles:@"Delete", nil];
                [confirm showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (alertView.cancelButtonIndex != buttonIndex) {
                        [self.postHeaderCell removeButtonPressed:self];
                    }
                }];
            } else {
                [self.postHeaderCell removeButtonPressed:self];

            }
        } else {
            [self performSegueWithIdentifier:@"OpenRecordViewSegue" sender:self];
        }
    } else {
        TDPhotoCellCollectionViewCell * cell = (TDPhotoCellCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        self.postButton.enabled = YES;
        ALAssetRepresentation *defaultRepresentation = cell.asset.defaultRepresentation;
        if ([[cell.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            self.assetURL = [defaultRepresentation url];
        } else if([[cell.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            CGImageRef iref = [defaultRepresentation fullResolutionImage];
            self.assetImage = [UIImage imageWithCGImage:iref scale:[defaultRepresentation scale] orientation:(UIImageOrientation)[defaultRepresentation orientation]];
        }
        [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
        [self minimizeButtonPressed];
    }
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.25;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1.25;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat yOffset = scrollView.contentOffset.y;
    if ((yOffset > (self.postHeaderCell.commentTextView.frame.size.height + self.postHeaderCell.optionsView.frame.size.height))
        && !self.minimizeIconIsShowing) {
        self.minimizeIconIsShowing = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationBarItem.leftBarButtonItem setImage:[UIImage imageNamed:@"minimize"]];
        
        UIImage *image = [UIImage imageNamed:@"minimize"];
        CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
        
        UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"minimize_hit"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(minimizeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    } else {
        if (self.minimizeIconIsShowing && yOffset < self.postHeaderCell.commentTextView.frame.size.height) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            UIButton *button = [TDViewControllerHelper navCloseButton];
            [button addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
            self.minimizeIconIsShowing = NO;
        }
    }
}

#pragma mark TDLocationViewControllerDelgate
- (void)locationAdded:(NSDictionary*)data {
    // Data from foursquare
    self.location = YES;
    self.locationData = data;
    [self.postHeaderCell changeLocationButton:[data objectForKey:@"name"] locationSet:self.location];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self removeOverlay];
        return;
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self removeOverlay];
        [self openLocationViewController];
    } else {
        // Remove the location
        if(self.postHeaderCell) {
            self.location = NO;
            [self.postHeaderCell changeLocationButton:@"Location" locationSet:self.location];
            [self removeOverlay];
        }
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (id actionSubview in actionSheet.subviews) {
        if ([actionSubview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)actionSubview;
            button.titleLabel.textColor = [TDConstants headerTextColor];
        }
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
    if (self.postHeaderCell) {
        [self.postHeaderCell.commentTextView becomeFirstResponder];
    }
}
- (void)addOverlay {
    [[TDAppDelegate appDelegate].window addSubview:self.viewOverlay];
    
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
}

- (void)removeOverlay {
    [self.viewOverlay removeFromSuperview];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}
@end
