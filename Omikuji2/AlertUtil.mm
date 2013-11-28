//
//  AlertUtil.m
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "AlertUtil.hpp"

#include <map>

// ----------------------------------------------
//
//  アラート系ユーティルの実装
//
// ----------------------------------------------

// 特殊メッセージ
static NSString *const _SPECIAL_MSG[] = {
    @"致命的なエラーです。管理者にご連絡ください。",
    @"認証に失敗しました。再度ログインしてください。",
    @"ログインに失敗しました。IDとPWをお確かめください。",
    @"状態エラーです。管理者にご連絡ください。",
    @"無効なコンテンツです。管理者にご連絡ください。",
    @"サーバエラーです。管理者にご連絡ください。",
    @"タイムアウトです。再度お試しください。",
    @"ネットワークに接続されていません。ネットワーク状態をお確かめください。"
};

// レスポンスコード -> アラートタイプマップ
static std::map< ConnectionUtil::HTTP_CODE, unsigned > _CODE_MAP =
{
    { ConnectionUtil::CODE_FATALERROR, 0 },
    { ConnectionUtil::CODE_AUTHERROR, 1 },
    { ConnectionUtil::CODE_STATUSERROR, 3 },
    { ConnectionUtil::CODE_NOTFOUND, 4 },
    { ConnectionUtil::CODE_SERVERERROR, 5 },
};


// **********************************************
// * アラート表示
// **********************************************
void AlertUtil::showAlert(NSString* title, NSString* msg) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

// ******************************************
// * アラート表示
// ******************************************
void AlertUtil::showAlert(NSString *title, ALERT_TYPE type) {
    AlertUtil::showAlert( title, _SPECIAL_MSG[ type ] );
}

// ******************************************
// * アラート表示
// ******************************************
void AlertUtil::showAlert(NSString *title, ConnectionUtil::HTTP_CODE code, bool login) {
    auto p = _CODE_MAP.find( code );
    if ( p!=_CODE_MAP.end() ) {
        unsigned index = p->second;
        if ( login && code==ConnectionUtil::CODE_AUTHERROR ) index += 1;
        showAlert( title, _SPECIAL_MSG[ index ] );
    }
    NSLog( @"AlertUtil::showAlert unknown code: %d", code );
}

// ******************************************
// * アラート用特殊メッセージの取得
// ******************************************
NSString *const AlertUtil::getMsg(ALERT_TYPE type) {
    return _SPECIAL_MSG[ type ];
}

// ******************************************
// * アラートタイプとHTTPレスポンスコードの変換
// ******************************************
AlertUtil::ALERT_TYPE AlertUtil::convert(ConnectionUtil::HTTP_CODE code, bool login) {
    switch ( code ) {
        case ConnectionUtil::CODE_FATALERROR : return AlertUtil::INVALID_PARAM;
        case ConnectionUtil::CODE_AUTHERROR : return ( login ) ? AlertUtil::AUTH_ERROR : AlertUtil::LOGIN_AUTH_ERROR;
        case ConnectionUtil::CODE_STATUSERROR : return AlertUtil::STATUS_ERROR;
        case ConnectionUtil::CODE_NOTFOUND : return AlertUtil::CONTENT_ERROR;
        case ConnectionUtil::CODE_SERVERERROR : return AlertUtil::SERVER_ERROR;
        default :
            break;
    }
    
    return AlertUtil::ALERT_NONE;
}









