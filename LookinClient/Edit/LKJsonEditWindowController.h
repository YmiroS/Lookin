//
//  LKAboutWindowController.h
//  LookinClient
//
//  Created by 李凯 on 2019/10/30.
//  Copyright © 2019 hughkli. All rights reserved.
//

#import "LKWindowController.h"
#import "LookinAttribute.h"
@interface LKJsonEditWindowController : LKWindowController
///刷新 修改需要使用的属性
@property(nonatomic, strong) LookinAttribute *attribute;

//刷新数据
-(void)refresh;
@end
