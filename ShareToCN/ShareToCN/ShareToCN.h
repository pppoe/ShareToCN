//
//  ShareToCN.h
//  ShareToCN
//
//  Created by Haoxiang on 7/6/11.
//  Copyright 2011 mr.pppoe All rights reserved.
//

#import <UIKit/UIKit.h>

//< Currently, We only Support Sina Weibo
#define kShareToCNKey       @"1380872492"
#define kShareToCNSecret    @"b41269d01f8f17e17a743ec36b702dab"

@class OAuthEngine; 

@protocol ShareToCNDelegate 

- (void)shareFailedWithError:(NSError *)error;
- (void)shareSucceed;

@end

@interface ShareToCN : NSObject {

    OAuthEngine *_engine;
    UIWebView *_webView;
    UIView *_containerView;
    
    NSString *_text;
    UIImage *_image;
    
    id<ShareToCNDelegate> _delegate; 
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, assign) id<ShareToCNDelegate> delegate;

+ (void)shareText:(NSString *)text;
+ (void)shareTextWithImage:(NSString *)text andImage:(UIImage *)image;

+ (void)shareText:(NSString *)text withDelegate:(id<ShareToCNDelegate>)delegate;
+ (void)shareTextWithImage:(NSString *)text andImage:(UIImage *)image withDelegate:(id<ShareToCNDelegate>)delegate;

@end
