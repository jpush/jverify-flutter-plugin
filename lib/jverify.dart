import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';

class Jverify {
  final String flutter_log = "| JVER | Flutter | ";
  factory Jverify() => _instance;

  final Platform _platform;
  final MethodChannel _channel;
  @visibleForTesting
  Jverify.private(MethodChannel channel, Platform platform)
      : _channel = channel,
        _platform = platform;

  static final _instance = new Jverify.private(
      const MethodChannel("jverify"),
      const LocalPlatform()
  );

//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }

  /// 初始化
  void setup({String appKey, String channel, bool useIDFA}) {
    print("$flutter_log" + "setup");
    _channel.invokeMethod("setup", {"appKey": appKey, "channel": channel, "useIDFA": useIDFA});
  }

  /// 设置 debug 模式
  void setDebugMode(bool debug) {
    print("$flutter_log" + "setDebugMode");
    _channel.invokeMethod("setDebugMode", {"debug": debug});
  }

  /// 获取 SDK 初始化是否成功标识
  Future<Map<dynamic, dynamic>> isInitSuccess() async {
    print("$flutter_log" + "isInitSuccess");
    return await _channel.invokeMethod("isInitSuccess");
  }

  /// SDK判断网络环境是否支持
  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    print("$flutter_log" + "checkVerifyEnable");
    return await _channel.invokeMethod("checkVerifyEnable");
  }

  /// SDK 获取号码认证token
  Future<Map<dynamic, dynamic>> getToken({String timeOut}) async {
    print("$flutter_log" + "getToken");
    var para = {"timeOut": timeOut};
    para.remove((key, value) => value == null);
    return await _channel.invokeMethod("getToken", para);
  }

  /// SDK 发起号码认证
  Future<Map<dynamic, dynamic>> verifyNumber(String phone,
      {String token}) async {
    print("$flutter_log" + "verifyNumber");
    var para = {"phone": phone, "token": token};
    para.remove((key, value) => value == null);
    return await _channel.invokeMethod("verifyNumber", para);
  }

  /// SDK 一键登录预取号,timeOut 有效取值范围[3000,10000]
  Future<Map<dynamic, dynamic>> preLogin({int timeOut}) async {
    var para = new Map();
    if (timeOut != null) {
      if (timeOut >= 3000 && timeOut <= 10000) {
        para["timeOut"] = timeOut;
      }
    }

    print("$flutter_log" + "preLogin" + "$para");
    return await _channel.invokeMethod("preLogin", para);
  }

  /// SDK 请求授权一键登录
  Future<Map<dynamic, dynamic>> loginAuth(bool autoDismiss) async {
    print("$flutter_log" + "loginAuth");
    return await _channel
        .invokeMethod("loginAuth", {"autoDismiss": autoDismiss});
  }

  /// 自定义授权页面
  void setCustomUI(
      {int navColor,
      String navText,
      int navTextColor,
      String navReturnImgPath,
      String logoImgPath,
      int logoWidth,
      int logoHeight,
      int logoOffsetY,
      bool logoHidden,
      int numberColor,
      int numFieldOffsetY,
      String logBtnText,
      int logBtnOffsetY,
      int logBtnTextColor,
      String logBtnBackgroundPath,
      String loginBtnNormalImage,
      String loginBtnPressedImage,
      String loginBtnUnableImage,
      String uncheckedImgPath,
      String checkedImgPath,
      int privacyOffsetY,
      String clauseName,
      String clauseUrl,
      int clauseBaseColor,
      int clauseColor,
      String clauseNameTwo,
      String clauseUrlTwo,
      int sloganOffsetY,
      int sloganTextColor}) {

    print("$flutter_log" + "setCustomUI");

    var para = {
      "navColor": navColor,
      "navText": navText,
      "navTextColor": navTextColor,
      "navReturnImgPath": navReturnImgPath,
      "logoImgPath": logoImgPath,
      "logoWidth": logoWidth,
      "logoHeight": logoHeight,
      "logoOffsetY": logoOffsetY,
      "logoHidden": logoHidden,
      "numberColor": numberColor,
      "numFieldOffsetY": numFieldOffsetY,
      "logBtnText": logBtnText,
      "logBtnOffsetY": logBtnOffsetY,
      "logBtnTextColor": logBtnTextColor,
      "logBtnBackgroundPath": logBtnBackgroundPath,
      "loginBtnNormalImage": loginBtnNormalImage,
      "loginBtnPressedImage": loginBtnPressedImage,
      "loginBtnUnableImage": loginBtnUnableImage,
      "uncheckedImgPath": uncheckedImgPath,
      "checkedImgPath": checkedImgPath,
      "privacyOffsetY": privacyOffsetY,
      "clauseName": clauseName,
      "clauseUrl": clauseUrl,
      "clauseBaseColor": clauseBaseColor,
      "clauseColor": clauseColor,
      "clauseNameTwo": clauseNameTwo,
      "clauseUrlTwo": clauseUrlTwo,
      "sloganOffsetY": sloganOffsetY,
      "sloganTextColor": sloganTextColor
    };
    para.removeWhere((key, value) => value == null);

    _channel.invokeMethod("setCustomUI",para);
  }
}
