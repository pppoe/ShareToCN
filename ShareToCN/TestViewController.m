//
//  TestViewController.m
//  ShareToCN
//
//  Created by Haoxiang on 7/6/11.
//  Copyright 2011 mr.pppoe All rights reserved.
//

#import "TestViewController.h"
#import "ShareToCNBox.h"

@implementation TestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)shareAll {
    
    UITextView *textView = (UITextView *)[self.view viewWithTag:100];
    
    [ShareToCNBox showWithText:textView.text];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *composeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                               target:self
                                                                               action:@selector(shareAll)];
    self.navigationItem.rightBarButtonItem = composeItem;
    [composeItem release];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.tag = 100;
    textView.editable = NO;
    textView.font = [UIFont systemFontOfSize:15.0f];
    textView.text = [NSString stringWithFormat:@"测试 %f", 
                     [NSDate timeIntervalSinceReferenceDate]];
    [self.view addSubview:textView];
    [textView release];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
