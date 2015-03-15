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
#import "TDCreatePostHeaderCell.h"
#import "CSStickyHeaderFlowLayout.h"
#import "TDPhotoCellCollectionViewCell.h"
#import "TDLocationViewController.h"
#import "TDEditVideoViewController.h"

#import "TDAppDelegate.h"

static int const kCellsPerRow = 3;
static const NSUInteger BufferSize = 1024*1024;

@interface TDCreatePostViewController () <UITextViewDelegate>
@property (nonatomic)  TDCreatePostHeaderCell *postHeaderCell;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIView *hitStateOverlay;
@property (nonatomic) UIView *viewOverlay;
@property (nonatomic, retain) UIViewController *overlayVc;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *assets;
@property (nonatomic) NSURL *recordedURL;
@property (nonatomic) NSURL *croppedURL;
@property (nonatomic) NSURL *assetURL;
@property (nonatomic) UIImage *assetImage;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;

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
@property (nonatomic) BOOL reloadAssets;
@property (nonatomic) BOOL isTaggedPost;
@end

@implementation TDCreatePostViewController

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
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

    self.cellLength = SCREEN_WIDTH / kCellsPerRow;

    layout.itemSize = CGSizeMake(self.cellLength, self.cellLength);
    layout.parallaxHeaderAlwaysOnTop = YES;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;

    // If we want to disable the sticky header effect
    layout.disableStickyHeaders = YES;

    CGFloat viewHeight = SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y;
    self.collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, viewHeight) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.scrollsToTop = YES;

    // Also insets the scroll indicator so it appears below the search bar
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
    
    [self.collectionView registerNib:[UINib nibWithNibName:CELL_IDENTIFIER_CREATE_POSTHEADER bundle:nil]
          forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader
                 withReuseIdentifier:CELL_IDENTIFIER_CREATE_POSTHEADER];

    [self.collectionView registerNib:[UINib nibWithNibName:CELL_IDENTIFIER_CREATE_IMAGE_CELL bundle:nil] forCellWithReuseIdentifier:CELL_IDENTIFIER_CREATE_IMAGE_CELL];
    self.collectionView.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.collectionView];

    // Overlay used for IOS7 action sheet.
    self.viewOverlay = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
    self.viewOverlay.backgroundColor = [UIColor whiteColor];

    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        [self loadPhotoAlbum];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForegroundCallback:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAssetChangedNotification:) name:ALAssetsLibraryChangedNotification object:[TDCreatePostViewController defaultAssetsLibrary]];
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
    [self moveCollectionView];
    [self resetCollectionViewOffset];

    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        [self.postHeaderCell.commentTextView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [self.userListView removeFromSuperview];
    self.userListView.delegate = nil;
    self.userListView = nil;
    self.thumbnailPath = nil;
    self.filename = nil;
    self.isOriginal = NO;
    self.postHeaderCell = nil;
    self.viewOverlay = nil;
    self.isTaggedPost = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willEnterForegroundCallback:(NSNotification *)notification {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        [self loadPhotoAlbum];
    }
}

- (void)handleAssetChangedNotification:(NSNotification *)notification {
    if (self.reloadAssets) {
        self.reloadAssets = NO;
        [self loadPhotoAlbum];
    }
}

- (void)loadPhotoAlbum {
    // Load photo library
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    // 1
    ALAssetsLibrary *assetsLibrary = [TDCreatePostViewController defaultAssetsLibrary];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    dispatch_async(queue, ^{
        // 2
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            debug NSLog(@"Enumerate group: %@ asset count: %ld %@", [group valueForProperty:ALAssetsGroupPropertyName], (long)group.numberOfAssets, [group valueForProperty:ALAssetsGroupPropertyType]);
            if ((long)group.numberOfAssets > 0) {
                [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        NSString *videoURL = [[result defaultRepresentation] UTI];
                        NSDictionary *photoInfo = @{@"asset" : result, @"date" : [result valueForProperty:ALAssetPropertyDate], @"uti" :videoURL};
                        [tmpAssets addObject:photoInfo];
                    }
                }];

                // 4
                self.assets = tmpAssets;
                [[TDCurrentUser sharedInstance] didAskForPhotos:YES];

                // 5
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                    if (self.filename != nil && self.thumbnailPath != nil) {
                        // This little trick forces the first responder call to be executed after the collection view has reloaded it's data.
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            NSLog(@"become first responder");
                            [self.postHeaderCell.commentTextView becomeFirstResponder];
                        });
                    }
                });
                debug NSLog(@"done reloading collection view");
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error loading images %@", error);
            NSString *errorMessage = nil;
            switch ([error code]) {
                case ALAssetsLibraryAccessUserDeniedError:
                case ALAssetsLibraryAccessGloballyDeniedError:
                    errorMessage = @"The user has declined access to it.";
                    break;
                default:
                    errorMessage = @"Reason unknown.";
                    break;
            }
            [error localizedDescription];
        }];
    });
}

- (void)cancelUpload {
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled object:nil userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

#pragma mark - segue / vc to vc interface

- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original {
    [self cancelUpload];
    if (self.postHeaderCell != nil) {
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
    // Tells to reload photos after possible photo was taken
    self.reloadAssets = YES;
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
    TDPhotoCellCollectionViewCell *cell = (TDPhotoCellCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER_CREATE_IMAGE_CELL forIndexPath:indexPath];

    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.image = [UIImage imageNamed:@"select_camera.png"];
    } else if ([self.assets count] > indexPath.row - 1) {
        NSDictionary *assetDict = self.assets[indexPath.row - 1];
        ALAsset *asset = [assetDict objectForKey:@"asset"];
        cell.asset = asset;
        cell.image = [UIImage imageWithCGImage:[asset thumbnail]];
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            [cell setVideoImage];
        }
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                            withReuseIdentifier:CELL_IDENTIFIER_CREATE_POSTHEADER
                                                                                   forIndexPath:indexPath];
        if ([cell isKindOfClass:[TDCreatePostHeaderCell class]]) {
            self.postHeaderCell = (TDCreatePostHeaderCell*)cell;
            self.postHeaderCell.delegate = self;
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
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)resetCollectionViewOffset {
    [self.collectionView setContentOffset:CGPointZero animated:NO];
}

#pragma mark TDCreatePostHeaderCellDelegate Methods

- (void)mediaButtonPressed {
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized && [[TDCurrentUser sharedInstance] didAskForPhotos] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested" message:@"To access your photo library, please go to iPhone Settings > Privacy > Photos, and switch Throwdown to ON" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [alert show];
    } else if ([self.assets count] == 0) {
        [self loadPhotoAlbum];
    }
    self.collectionView.scrollEnabled = YES;
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

    // - Created a new navigation controller because pushing view controller onto existing navigation cannot
    // - do a bottom to top transition.
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];

}

-(void)commentTextViewBeginResponder:(BOOL)yes {
    if (yes) {
        [self resetCollectionViewOffset];
        self.collectionView.scrollEnabled = NO;
        [self moveCollectionView];
    }
}

- (void)adjustCollectionViewHeight {
    [self moveCollectionView];
}

- (void)moveCollectionView {
    CSStickyHeaderFlowLayout *layout =  (id)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        // 15 is kTextViewMargin from postheadercell
        layout.parallaxHeaderReferenceSize = CGSizeMake(SCREEN_WIDTH, self.postHeaderCell.commentTextView.frame.size.height + self.postHeaderCell.optionsView.frame.size.height + 15);
    }
}

#pragma mark action sheet methods

- (void)showLocationActionSheet:(NSString *)location {
    NSString *newPlaceStr = @"Select Another Place";
    NSString *removeStr = @"Remove Location";
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:location
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:newPlaceStr
                                                        otherButtonTitles:removeStr, nil];
        [self addOverlay];
        [actionSheet showInView:self.viewOverlay];
    } else {
        [self addOverlay];
        NSString *address = [TDViewControllerHelper getAddressFormat:self.locationData];
        NSString *title = [self.locationData objectForKey:@"name"];
        if (address.length) {
            title = [title stringByAppendingFormat:@"\n%@", address];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title  message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* selectAnotherLocationAction = [UIAlertAction actionWithTitle:newPlaceStr style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self removeOverlay];
                                                                  [self openLocationViewController];
                                                              }];
        UIAlertAction *removeLocationAction =[UIAlertAction actionWithTitle:removeStr style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        [self removeOverlay];
                                                                        if(self.postHeaderCell) {
                                                                            self.location = NO;
                                                                            [self.postHeaderCell changeLocationButton:@"Location" locationSet:self.location];
                                                                        }
                                                                    }];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           [self removeOverlay];
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
        }
    } else if ([@"OpenShareWithViewSegue" isEqualToString:segue.identifier]) {
        NSString *comment = [self.postHeaderCell.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.isTaggedPost = self.postHeaderCell.taggedUsers;
        TDSharePostViewController *vc = [segue destinationViewController];
        [vc setValuesForSharing:self.filename withComment:comment isPR:self.isPR userGenerated:self.isOriginal locationData:self.locationData taggedPost:self.isTaggedPost];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.cellLength, self.cellLength);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];

    if (indexPath.section == 0 && indexPath.row == 0) {
        [self resetCollectionViewOffset];
        [self performSegueWithIdentifier:@"OpenRecordViewSegue" sender:self];
    } else {
        TDPhotoCellCollectionViewCell * cell = (TDPhotoCellCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        self.postButton.enabled = YES;
        ALAssetRepresentation *defaultRepresentation = cell.asset.defaultRepresentation;
        if ([[cell.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            self.assetURL = [defaultRepresentation url];
            NSError *error;
            if (![self exportDataToURL:defaultRepresentation error:&error]) {
                debug NSLog(@"Error:%@", [error localizedDescription]);
            }
        } else if([[cell.asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            CGImageRef iref = [defaultRepresentation fullResolutionImage];
            self.assetImage = [UIImage imageWithCGImage:iref scale:[defaultRepresentation scale] orientation:(UIImageOrientation)[defaultRepresentation orientation]];
        }
        [self minimizeButtonPressed];
        [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat yOffset = scrollView.contentOffset.y;
    if ((yOffset > (self.postHeaderCell.commentTextView.frame.size.height + self.postHeaderCell.optionsView.frame.size.height))
        && !self.minimizeIconIsShowing) {
        self.minimizeIconIsShowing = YES;
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
        [self removeOverlay];
        // Remove the location
        if (self.postHeaderCell) {
            self.location = NO;
            [self.postHeaderCell changeLocationButton:@"Location" locationSet:self.location];
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
    CSStickyHeaderFlowLayout *layout =  (id)self.collectionView.collectionViewLayout;
    CGSize layoutSize;
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        layoutSize = layout.parallaxHeaderReferenceSize;
    }
    CGRect overlayFrame = self.viewOverlay.frame;
    overlayFrame.origin.y = layoutSize.height;

    overlayFrame.size.height = SCREEN_HEIGHT - layoutSize.height;
    self.viewOverlay.frame = overlayFrame;
    [self.view addSubview:self.viewOverlay];
}

- (void)removeOverlay {
    [self.viewOverlay removeFromSuperview];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (BOOL) exportDataToURL:(ALAssetRepresentation*)defaultRepresentation error:(NSError**) error
{
    NSURL *selectedURLVideo = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:kAssetsVideoFilePath]];
    [[NSFileManager defaultManager] createFileAtPath:[selectedURLVideo path] contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:selectedURLVideo error:error];
    if (!handle) {
        [*error localizedDescription];
        return NO;
    }
    
    ALAssetRepresentation *rep = defaultRepresentation;
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:error];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            offset += bytesRead;
        } @catch (NSException *exception) {
            free(buffer);
            return NO;
        }
    } while (bytesRead > 0);
    
    free(buffer);
    
    self.assetURL = selectedURLVideo;
    return YES;
}
@end
