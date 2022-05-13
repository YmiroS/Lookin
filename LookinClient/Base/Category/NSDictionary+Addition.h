//
//  NSDictionary+Addition.h
//  LookinClient
//
//  Created by Xs on 2022/5/11.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Addition)
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
- (NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
