//
//  ShareToCN.m
//  ShareToCN
//
//  Created by Haoxiang on 7/6/11.
//  Copyright 2011 mr.pppoe All rights reserved.
//

#import "ShareToCN.h"
#import "OAuthEngine.h"
#import "OAMutableURLRequest.h"
#import "StringUtil.h"

#import <QuartzCore/QuartzCore.h>

#define kActiveIndicatorTag 0x1234

#define kBorderWidth 10.0f
#define kPadding 52.0f

#define kTransitionDuration 0.3f

//< For Sina
#define kSinaKeyCodeLead @"获取到的授权码"
#define kSinaPostPath @"http://api.t.sina.com.cn/statuses/update.json"

static ShareToCN *sharedCenter = nil;

@interface ShareToCN (Private) <UIWebViewDelegate, OAuthEngineDelegate>

+ (ShareToCN *)center;
- (BOOL)touchForAuth;
- (void)afterAuth;
- (void)postTweet;

- (void)dismissView;
- (void)showView;

@end

@implementation ShareToCN
@synthesize text = _text;
@synthesize image = _image;
@synthesize delegate = _delegate;

- (id)init
{
    self = [super init];
    if (self) {

        _engine = [[OAuthEngine alloc] initOAuthWithDelegate:self];
        _engine.consumerKey = kShareToCNKey;
        _engine.consumerSecret = kShareToCNSecret;

        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        //< CoverView
        _containerView = [[UIView alloc] initWithFrame:keyWindow.bounds];
        _containerView.backgroundColor = [UIColor blackColor];
        
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, kPadding + kBorderWidth, 
                                                               keyWindow.frame.size.width, 
                                                               keyWindow.frame.size.height - 2 * (kPadding + kBorderWidth))];
        _webView.delegate = self;
        _webView.alpha = 0.0f;        
        [_containerView addSubview:_webView];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = _containerView.bounds;
        button.alpha = 0.1f;
        [button addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:button];
        [_containerView sendSubviewToBack:button];
        
        UIActivityIndicatorView *activeIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activeIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
                                         | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        activeIndicator.tag = kActiveIndicatorTag;
        activeIndicator.hidden = YES;
        activeIndicator.frame = CGRectMake(CGRectGetMidX(_webView.bounds) - 20.0f,
                                           CGRectGetMidY(_webView.bounds) - 20.0f,
                                           40.0f, 40.0f);
        [_webView addSubview:activeIndicator];
        [activeIndicator release];
    }
    return self;
}

- (void)dealloc
{
    
    self.text = nil;
    self.image = nil;
    
    [_containerView release];
    [_engine release];
    [_webView release];
    [super dealloc];
}

#pragma mark Methods
+ (void)shareText:(NSString *)text {
    [ShareToCN shareText:text withDelegate:nil];
}

+ (void)shareTextWithImage:(NSString *)text andImage:(UIImage *)image {
    [ShareToCN shareTextWithImage:text andImage:image withDelegate:nil];
}

+ (void)shareText:(NSString *)text withDelegate:(id<ShareToCNDelegate>)delegate {
    ShareToCN *center = [ShareToCN center];
    center.text = text;
    center.delegate = delegate;
    
    if ([center touchForAuth])
    {
        [center postTweet];
    }
}

+ (void)shareTextWithImage:(NSString *)text andImage:(UIImage *)image withDelegate:(id<ShareToCNDelegate>)delegate {
    
}

@end

@implementation ShareToCN (Private)

+ (ShareToCN *)center {
    if (!sharedCenter)
    {
        sharedCenter = [[ShareToCN alloc] init];
    }
    return sharedCenter;
}

- (BOOL)touchForAuth {
    
    if ([_engine isAuthorized])
    {
        return YES;
    }

    //< Not Authorized
    if (!_engine.OAuthSetup)
    {
        [_engine requestRequestToken];
    }
    
    //< Reveal a WebView for Authorization
    if (_containerView.superview)
    {
        [_containerView removeFromSuperview];
    }
    
    [self showView];
    
    return NO;
}

- (void)showView {
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:_containerView];
    
    _containerView.backgroundColor = [UIColor blackColor];
    _webView.alpha = 1.0f;
    _webView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    _containerView.alpha = 1.0f;
    
    [UIView beginAnimations:@"auth" context:nil];
    [UIView setAnimationDidStopSelector:@selector(showViewAnim1)];
    [UIView setAnimationDelegate:self];

    _containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    [_webView loadRequest:_engine.authorizeURLRequest];
    _webView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
    
    [UIView commitAnimations];
        
}

- (void)showViewAnim1 {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showViewAnim2)];
    _webView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
    [UIView commitAnimations];
}

- (void)showViewAnim2 {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    _webView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    [UIView commitAnimations];    
}

- (void)postTweet {
    NSString* path = kSinaPostPath;
    NSString *postString = [NSString stringWithFormat:@"status=%@",
                            [self.text encodeAsURIComponent]];
    
    NSString *URL = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)path, (CFStringRef)@"%", NULL, kCFStringEncodingUTF8);
    [URL autorelease];
    NSURL *finalURL = [NSURL URLWithString:URL];
    NSMutableURLRequest* req = [[[OAMutableURLRequest alloc] initWithURL:finalURL
                                                                consumer:_engine.consumer 
                                                                   token:_engine.accessToken 
                                                                   realm: nil
                                                       signatureProvider:nil] autorelease];
    [req setHTTPMethod:@"POST"];
    [req setHTTPShouldHandleCookies:NO];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    int contentLength = [postString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    [req setValue:[NSString stringWithFormat:@"%d", contentLength] forHTTPHeaderField:@"Content-Length"];
    
    NSString *finalBody = [NSString stringWithString:@""];
    finalBody = [finalBody stringByAppendingString:postString];
    finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
                                                    (postString) ? @"&" : @"?" , 
                                                    _engine.consumerKey]];
    
    [req setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *err = nil;
    NSURLResponse *response = nil;
    
    [(OAMutableURLRequest *)req prepare];
    
    [NSURLConnection sendSynchronousRequest:req
                          returningResponse:&response
                                      error:&err];
    
    if (err)
    {
        //< Error Handle
        NSLog(@"Error %@", err);
        if (self.delegate)
        {
            [self.delegate shareFailedWithError:err];
        }
    }
    else
    {
        if (self.delegate)
        {
            [self.delegate shareSucceed];
        }
    }
}

- (void)afterAuth {
    [self postTweet];
}

- (void)dismissView {
    
    [UIView beginAnimations:@"afterAuth" context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:_containerView];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    
    _webView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    _containerView.alpha = 0.0f;
    
    [UIView commitAnimations];
}

#pragma mark UIWebViewDelegate
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
////    NSLog(@"%@", request);  
//    return YES;
//}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    UIActivityIndicatorView *activeIndicator = (UIActivityIndicatorView *)[webView viewWithTag:kActiveIndicatorTag];
    [activeIndicator sizeToFit];
    [activeIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //< The Pin Code, Copy-Paste from https://github.com/JimLiu/WeiboSDK
    {
        NSString *pin;
        
        NSString *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerText"];
        if ([html rangeOfString:kSinaKeyCodeLead].length > 0)
        {        
            if (html.length == 0) 
            {
                pin = nil;
            }
            else
            {
                const char *rawHTML = (const char *) [html UTF8String];
                int	length = strlen(rawHTML), chunkLength = 0;
                
                for (int i = 0; i < length; i++) {
                    if (rawHTML[i] < '0' || rawHTML[i] > '9') {
                        if (chunkLength == 6) {
                            char *buffer = (char *) malloc(chunkLength + 1);				
                            memmove(buffer, &rawHTML[i - chunkLength], chunkLength);
                            buffer[chunkLength] = 0;
                            
                            pin = [NSString stringWithUTF8String:buffer];
                            free(buffer);
                        }
                        chunkLength = 0;
                    } else
                        chunkLength++;
                }
            }
            
            if (pin && [pin length] > 0)
            {
                _engine.pin = pin;
                [_engine requestAccessToken];
                
                [self performSelector:@selector(dismissView) withObject:nil afterDelay:0.5f];
                [self performSelector:@selector(afterAuth) withObject:nil afterDelay:0.2f]; //< Skip some run loops
            }
        }
    }    

    UIActivityIndicatorView *activeIndicator = (UIActivityIndicatorView *)[_webView viewWithTag:kActiveIndicatorTag];
    activeIndicator.hidden = YES;
    [activeIndicator stopAnimating];    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {    
    
    if (self.delegate)
    {
        [self.delegate shareFailedWithError:error];
    }

    UIActivityIndicatorView *activeIndicator = (UIActivityIndicatorView *)[_webView viewWithTag:kActiveIndicatorTag];
    activeIndicator.hidden = YES;
    [activeIndicator stopAnimating];    

    [self performSelector:@selector(dismissView) withObject:nil afterDelay:0.5f];
}

#pragma mark OAuthEngineDelegate
- (void) storeCachedOAuthData: (NSString *) data forUsername: (NSString *) username {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	[defaults setObject:data forKey: @"authData"];
	[defaults synchronize];
}

- (NSString *) cachedOAuthDataForUsername: (NSString *) username {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"authData"];
}

- (void)removeCachedOAuthDataForUsername:(NSString *) username{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	[defaults removeObjectForKey: @"authData"];
	[defaults synchronize];
}

@end
