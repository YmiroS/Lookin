//
//  LKJsonEditController.h
//  LookinClient
//
//  Created by Xs on 2022/5/9.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "LKBaseViewController.h"
#import "LKJsonEditWebView.h"


@interface LKJsonEditController : LKBaseViewController<WKNavigationDelegate, WKUIDelegate>

@property (strong) LKJsonEditWebView *webView;
- (void)loadJsonEditor;
-(void) saveStringwithBlock:(void (^)(NSString* saveJson))nextBlock;
@end
