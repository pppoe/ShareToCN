//
//  ShareToCNBox.m
//  ShareToCN
//
//  Created by hli on 7/7/11.
//  Copyright 2011 mr.pppoe. All rights reserved.
//

#import "ShareToCNBox.h"
#import "ShareToCN.h"

#import <QuartzCore/QuartzCore.h>

#define kTagTextView 0x1234
#define kTagLabel 0x1235

static ShareToCNBox *sharedBox = nil;

static const float kVPadding = 5.0f;
static const float kHPadding = 10.0f;
static const float kUpperPartRate = 0.75f;

static const float kButtonWidth = 100.0f;
static const float kButtonHeight = 30.0f;

static const int kFontSize = 14.0f;

/////////////////////////////////////////////////////////////////////
@interface ShareToCNBoxView : UIView {
}
@end

/////////////////////////////////////////////////////////////////////
@implementation ShareToCNBoxView

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, rect);
    
    CGPoint points[2];
    points[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect) + kUpperPartRate * rect.size.height);
    points[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect) + kUpperPartRate * rect.size.height);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextStrokeLineSegments(context, points, 2);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat colors[] = {
        0x2f/255.0f, 0x2f/255.0f, 0x2f/255.0f, 1.0f,
        0x12/255.0f, 0x12/255.0f, 0x12/255.0f, 1.0f
    };

    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGContextDrawLinearGradient(context, gradient, 
                                CGPointMake(CGRectGetMidX(rect), 
                                            CGRectGetMinY(rect) + kUpperPartRate * rect.size.height),
                                CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), 0);
    CGColorSpaceRelease(colorSpace);
}

@end

/////////////////////////////////////////////////////////////////////
@interface ShareToCNBox (Private) <ShareToCNDelegate, UITextViewDelegate>

+ (ShareToCNBox *)box;
- (void)showWithPreText:(NSString *)preText;
- (IBAction)buttonTapped:(id)sender;

- (void)reveal;
- (void)hide;

- (void)showKeyboard;
- (void)hideKeyboard;

- (int)charCountOfString:(NSString *)string;
- (NSString *)trimString:(NSString *)string toCharCount:(int)charCount;

@end

/////////////////////////////////////////////////////////////////////
@implementation ShareToCNBox
@synthesize maxUnitCount = _maxUnitCount;
@synthesize unitCharCount = _unitCharCount;

+ (void)showWithText:(NSString *)text {
    [[ShareToCNBox box] showWithPreText:text];
}

- (id)init {
    if ((self = [super init]))
    {
        CGRect frame = CGRectMake(20, 60, 280, 200);
        
        UIButton *bkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        bkButton.frame = [[UIApplication sharedApplication] keyWindow].bounds;
        [bkButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];        
        
        _coverView = [bkButton retain];
        
        _containerView = [[ShareToCNBoxView alloc] initWithFrame:frame];
        _containerView.layer.cornerRadius = 10.0f;
        _containerView.clipsToBounds = YES;
        
        float width = frame.size.width;
        float height = frame.size.height;
        
        self.maxUnitCount = 140;
        self.unitCharCount = 2;
        
        //< GUI
        CGRect textViewRect = CGRectMake(kHPadding, kVPadding, 
                                         width - 2 * kHPadding, 
                                         height * kUpperPartRate - 2 * kVPadding);
        CGRect labelRect = CGRectMake(CGRectGetMinX(textViewRect), 
                                      height * kUpperPartRate + (height * (1.0f - kUpperPartRate) - kButtonHeight)/2.0f, 
                                      kButtonWidth, kButtonHeight);
        CGRect buttonRect = CGRectMake(CGRectGetMaxX(textViewRect) - kButtonWidth, 
                                       height * kUpperPartRate + (height * (1.0f - kUpperPartRate) - kButtonHeight)/2.0f, 
                                       kButtonWidth, kButtonHeight);

        CALayer *shadowLayer = [CALayer layer];
        shadowLayer.frame = textViewRect;
        
        UITextView *textView = [[UITextView alloc] initWithFrame:textViewRect];
        textView.layer.shadowColor = [UIColor blackColor].CGColor;
        textView.layer.shadowOffset = CGSizeMake(2, -2);
        textView.layer.shadowOpacity = 0.8f;
        textView.layer.shadowRadius = 1.0f;
        textView.font = [UIFont systemFontOfSize:kFontSize];
        textView.delegate = self;
        textView.tag = kTagTextView;
        [_containerView addSubview:textView];
        [textView release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.font = [UIFont systemFontOfSize:kFontSize];
        label.textColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(2, 2);
        label.shadowColor = [UIColor blackColor];
        label.text = [NSString stringWithFormat:@"%d", self.maxUnitCount];
        label.backgroundColor = [UIColor clearColor];
        label.tag = kTagLabel;
        [_containerView addSubview:label];
        [label release];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:NSLocalizedString(@"share_to_cn_button", @"") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.frame = buttonRect;
        [_containerView addSubview:button];
        
        _coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        [_coverView addSubview:_containerView];
    }
    return self;
}

- (void)dealloc {
    [_coverView release];
    [_containerView release];
    [super dealloc];
}

@end

/////////////////////////////////////////////////////////////////////
@implementation ShareToCNBox (Private)
                          
+ (ShareToCNBox *)box {
    if (!sharedBox)
    {
        sharedBox = [[ShareToCNBox alloc] init];
    }
    return sharedBox;
}

- (void)showWithPreText:(NSString *)preText {
    
    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    textView.text = [preText substringToIndex:MIN(self.maxUnitCount * self.unitCharCount, [preText length])];
    [self textViewDidChange:textView];
    
    [self reveal];
}

- (void)reveal {

    if (_coverView.superview)
    {
        [_coverView removeFromSuperview];
    }
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:_coverView];
    
    _coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
    _containerView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    
    _coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    _containerView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    
    [UIView commitAnimations];
    
}

- (void)hide {

    _coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    _containerView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.8f];
    [UIView setAnimationDelegate:_coverView];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    
    _coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];
    _containerView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    
    [UIView commitAnimations];

}

- (void)showKeyboard {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    
    _containerView.transform = CGAffineTransformMakeTranslation(0.0f, -30.0f);
    
    [UIView commitAnimations];
}

- (void)hideKeyboard {

    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    [textView resignFirstResponder];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    
    _containerView.transform = CGAffineTransformMakeTranslation(0.0f, 0.0f);
    
    [UIView commitAnimations];
    
}

- (void)cancel:(id)sender {
    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    if ([textView isFirstResponder])
    {
        [self hideKeyboard];
    }
    else
    {
        [self hide];
    }
}

- (int)charCountOfString:(NSString *)string {
    int count = 0;
    for (int i = 0; i < [string length]; i++)
    {
        unichar c = [string characterAtIndex:i];
        if (isblank(c) || isascii(c))
        {
            count++;
        }
        else
        {
            count += 2;
        }
    }
    return count;
}

- (NSString *)trimString:(NSString *)string toCharCount:(int)charCount {
    
    int curCharCount = [self charCountOfString:string];
    
    NSString *trimedStr = string;
    
    if (curCharCount > charCount)
    {
        int delta = curCharCount - charCount;
        for (int i = [string length] - 1; i >= 0; i--)
        {
            unichar c = [string characterAtIndex:i];
            if (isblank(c) || isascii(c))
            {
                delta--;
            }
            else
            {
                delta -= 2;
            }
            if (delta <= 0)
            {
                trimedStr = [string substringToIndex:i];
                break;
            }
        }
    }
    
    return trimedStr;
}


#pragma mark ShareToCNDelegate
- (void)shareFailedWithError:(NSError *)error {
    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    textView.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"share_to_cn_failed", @""), error];
    [self hide];
}

- (void)shareSucceed {
    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    textView.text = [NSString stringWithFormat:@"%@!", NSLocalizedString(@"share_to_cn_succeed", @"")];
    [self hide];
}

#pragma mark UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self showKeyboard];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    textView.text = [self trimString:textView.text toCharCount:(self.maxUnitCount * self.unitCharCount)];
    
    int unitCount = ceil((float)[self charCountOfString:textView.text]/(float)self.unitCharCount);
    
    UILabel *label = (UILabel *)[_containerView viewWithTag:kTagLabel];
    label.text = [NSString stringWithFormat:@"%d", (self.maxUnitCount - unitCount)];
}

#pragma mark IBAction
- (IBAction)buttonTapped:(id)sender {
    
    [self hideKeyboard];

    UITextView *textView = (UITextView *)[_containerView viewWithTag:kTagTextView];
    [ShareToCN shareText:textView.text withDelegate:self];
}

@end

/////////////////////////////////////////////////////////////////////

