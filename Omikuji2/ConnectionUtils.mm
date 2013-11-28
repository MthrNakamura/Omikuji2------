//
//  ConnectionUtils.m
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#include "ConnectionUtils.hpp"

#include "AppDelegate.h"

// ----------------------------------------------
//
//  通信系ユーティルの実装
//
// ----------------------------------------------

// **********************************************
// * リクエストの生成
// **********************************************
NSMutableURLRequest* ConnectionUtil::createRequest(NSString *url_str, bool auth, NSData* post_data)
{
    AppDelegate* delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // リクエストURLを設定
    auto url = [[NSURL alloc]initWithString:url_str];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // ヘッダーを設定
    [request setValue:APP_ID forHTTPHeaderField:@"ApplicationId"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if ( auth ) [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];
    
    // POSTデータが存在する
    if ( post_data ) {
        // メソッドは POST
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:post_data];
    }
    // POSTデータが存在しない
    else {
        // メソッドは GET
        [request setHTTPMethod:@"GET"];
    }
    
    return request;
}

// **********************************************
// * ステータスコードの確認
// **********************************************
bool ConnectionUtil::checkStatusCode(NSHTTPURLResponse* response, ConnectionUtil::HTTP_CODE &code) {
    
    // ステータスコードの取得
    code = static_cast< ConnectionUtil::HTTP_CODE >( response.statusCode );
    
    return ( code==ConnectionUtil::CODE_OK );
}

// **********************************************
// * レスポンスのチェックとデータシリアライズ処理
// **********************************************
NSDictionary* ConnectionUtil::checkAndSerializeResponse(NSURLResponse* response, NSData *data, ConnectionUtil::HTTP_CODE &code)
{
    // ステータスコードのチェック
    auto http_response = static_cast< NSHTTPURLResponse* >( response );
    if ( !checkStatusCode( http_response, code ) ) return nil;
    
    // シリアライズ
    NSError *error = nil;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:&error];
}








