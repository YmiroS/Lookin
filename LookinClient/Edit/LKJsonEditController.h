//
//  LKJsonEditController.h
//  LookinClient
//
//  Created by Xs on 2022/5/9.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "LKBaseViewController.h"
#import "LKJsonEditWebView.h"


@interface LKJsonEditController : LKBaseViewController<WKNavigationDelegate>

@property (strong) LKJsonEditWebView *webView;

@end
