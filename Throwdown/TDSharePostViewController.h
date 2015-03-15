//
//  TDShareWithViewController.h
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDSharePostViewController : UIViewController

- (void)setValuesForSharing:(NSString *)filename withComment:(NSString *)comment isPR:(BOOL)isPR userGenerated:(BOOL)ug locationData:(NSDictionary*)locationData taggedPost:(BOOL)taggedPost;

@end
