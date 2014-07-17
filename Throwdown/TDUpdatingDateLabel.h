//
//  TDUpdatingDateLabel.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDUpdatingDateLabel : UILabel

@property (nonatomic, retain) NSTimer *timeStampUpdateTimer;
@property (nonatomic, retain) NSDate *labelDate;

@end
