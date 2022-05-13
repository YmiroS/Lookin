//
//  NSDictionary+Addition.m
//  LookinClient
//
//  Created by Xs on 2022/5/11.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "NSDictionary+Addition.h"

@implementation NSDictionary (Addition)


- (NSString *)jsonString
{
    if (!self || ![self isKindOfClass:[NSDictionary class]] || [self count] == 0) {
        return @"";
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
    
    NSString *jsonString = nil;
    if (data && data.length > 0) {
        jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}


+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    NSDictionary *dic;
    if ([jsonString isKindOfClass:[NSString class]]) {
        if (jsonString.length > 0) {
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            if ([jsonData isKindOfClass:[NSData class]]) {
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {//转换成功
                    dic = dictionary;
                }
            }
        }
    }
    return dic;
}
@end
