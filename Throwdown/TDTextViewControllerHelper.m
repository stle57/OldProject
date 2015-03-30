//
//  TDTextViewControllerHelper.m
//  Throwdown
//
//  Created by Stephanie Le on 7/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTextViewControllerHelper.h"
#import "TDConstants.h"

@implementation TDTextViewControllerHelper

+ (NSString *)findUsernameInText:(NSString *)text {
    int userNameLength = 0;
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    for (int i = (int)text.length - 1; i >= 0; i--) {
        // walk backwards until we hit a non-digit or word-character or an @-sign
        // Only return positive number if we hit an @ sign
        NSString *currentCharacter = [text substringWithRange:NSMakeRange(i, 1)];
        if ([[currentCharacter stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""]) {
            // hit regular string, continue...
            userNameLength++;
        } else if ([currentCharacter isEqualToString:@"@"]) {
            // hit @-sign
            return [text substringFromIndex:(text.length - userNameLength)];
        } else {
            // hit non-alpha
            return nil;
        }
    }
    // if the loop didn't return anything, nothing was found so return nil:
    return nil;
}

+ (BOOL)usernameInString:(NSString *)text {
    int userNameLength = 0;
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    NSInteger length = text.length;

    for (int i = (int)text.length - 1; i >= 0; i--) {
        // walk backwards until we hit a non-digit or word-character or an @-sign
        // Only return positive number if we hit an @ sign
        NSString *currentCharacter = [text substringWithRange:NSMakeRange(i, 1)];
        if ([[currentCharacter stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""]) {
            // hit regular string, continue...
            userNameLength++;
        } else if ([currentCharacter isEqualToString:@"@"]) {
            // hit @-sign
            return [text substringFromIndex:(length - userNameLength)].length > 0 ? YES : NO;
        } else {
            // hit non-alpha, reset everything.
            length = length - (userNameLength+1);
            userNameLength = 0;
        }
    }
    // if the loop didn't return anything, nothing was found so return nil:
    return NO;
}

+ (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Allow pasting longer texts but cut the text to max limit
    if ([text length] + [textView.text length] > kCommentMaxCharacters) {
        textView.text = [[textView.text stringByAppendingString:text] substringToIndex:kCommentMaxCharacters];
    }
    return textView.text.length + (text.length - range.length) <= kCommentMaxCharacters;
}

@end
