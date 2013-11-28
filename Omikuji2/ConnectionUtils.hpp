//
//  ConnectionUtils.h
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#pragma once

// ----------------------------------------------
//
//  通信系ユーティル
//
// ----------------------------------------------
namespace ConnectionUtil {
    
    // --- HTTPレスポンスコード ---
    enum HTTP_CODE : unsigned {
        CODE_OK             = 200,  // 成功
        CODE_FATALERROR     = 400,  // 致命的なエラー
        CODE_AUTHERROR      = 401,  // 認証エラー
        CODE_STATUSERROR    = 403,  // 状態エラー
        CODE_NOTFOUND       = 404,  // Not Found
        CODE_SERVERERROR    = 500,  // サーバエラー
    };

    // --- リクエストの生成 ---
    NSMutableURLRequest* createRequest(NSString *url_str, bool auth, NSData* post_data);
    
    // --- ステータスコードの確認 ---
    bool checkStatusCode(NSHTTPURLResponse* response, ConnectionUtil::HTTP_CODE &code);
    
    // --- レスポンスのチェックとデータシリアライズ処理 ---
    NSDictionary* checkAndSerializeResponse(NSURLResponse* response, NSData *data, ConnectionUtil::HTTP_CODE &code);
    
}