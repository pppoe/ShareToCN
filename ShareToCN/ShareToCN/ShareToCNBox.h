//
//  ShareToCNBox.h
//  ShareToCN
//
//  Created by hli on 7/7/11.
//  Copyright 2011 mr.pppoe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShareToCNBox : NSObject {

    int _maxUnitCount;
    int _unitCharCount;
    
    //< GUI Comps
    UIView *_coverView;
    UIView *_containerView;
}

@property (nonatomic, assign) int maxUnitCount;
@property (nonatomic, assign) int unitCharCount;

+ (void)showWithText:(NSString *)text;

@end
