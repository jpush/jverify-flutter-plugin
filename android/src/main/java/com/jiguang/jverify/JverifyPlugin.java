package com.jiguang.jverify;

import android.app.Activity;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Paint;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import cn.jiguang.api.utils.JCollectionAuth;
import cn.jiguang.verifysdk.api.AuthPageEventListener;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyLoginBtClickCallback;
import cn.jiguang.verifysdk.api.JVerifyUIClickCallback;
import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.LoginSettings;
import cn.jiguang.verifysdk.api.PreLoginListener;
import cn.jiguang.verifysdk.api.PrivacyBean;
import cn.jiguang.verifysdk.api.RequestCallback;
import cn.jiguang.verifysdk.api.SmsClickActionListener;
import cn.jiguang.verifysdk.api.SmsListener;
import cn.jiguang.verifysdk.api.VerifyListener;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


/**
 * JverifyPlugin
 */
public class JverifyPlugin implements FlutterPlugin, MethodCallHandler {

  // 定义日志 TAG
  private static final String TAG = "| JVER | Android | -";


  /// 统一 key
  private static String j_result_key = "result";
  /// 错误码
  private static String j_code_key = "code";
  /// 回调的提示信息，统一返回 flutter 为 message
  private static String j_msg_key = "message";
  /// 运营商信息
  private static String j_opr_key = "operator";
  /// 手机号信息
  private static String j_phone_key = "phone";
  // 默认超时时间
  private static int j_default_timeout = 5000;
  // 重复请求
  private static int j_error_code_repeat = -1;


  private Context context;
  private MethodChannel channel;


  @Override
  public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "jverify");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
  }


  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d(TAG, "onMethodCall:" + call.method);

    Log.d(TAG, "processMethod:" + call.method);
    if (call.method.equals("setup")) {
      setup(call, result);
    } else if (call.method.equals("setDebugMode")) {
      setDebugMode(call, result);
    } else if (call.method.equals("setCollectionAuth")) {
      setCollectionAuth(call, result);
    }else if (call.method.equals("isInitSuccess")) {
      isInitSuccess(call, result);
    } else if (call.method.equals("checkVerifyEnable")) {
      checkVerifyEnable(call, result);
    } else if (call.method.equals("getToken")) {
      getToken(call, result);
    } else if (call.method.equals("verifyNumber")) {
      verifyNumber(call, result);
    } else if (call.method.equals("preLogin")) {
      preLogin(call, result);
    } else if (call.method.equals("loginAuth")) {
      loginAuth(call, result);
    } else if (call.method.equals("loginAuthSyncApi")) {
      loginAuthSyncApi(call, result);
    } else if (call.method.equals("dismissLoginAuthView")) {
      dismissLoginAuthView(call, result);
    } else if (call.method.equals("setCustomUI")) {
//      setCustomUI(call,result);
    } else if (call.method.equals("setCustomAuthViewAllWidgets")) {
      setCustomAuthViewAllWidgets(call, result);
    } else if (call.method.equals("clearPreLoginCache")) {
      clearPreLoginCache(call, result);
    } else if (call.method.equals("setCustomAuthorizationView")) {
      setCustomAuthorizationView(call, result);
    } else if (call.method.equals("getSMSCode")) {
      getSMSCode(call, result);
    } else if (call.method.equals("setSmsIntervalTime")) {
      setGetCodeInternal(call, result);
    } else if (call.method.equals("smsAuth")) {
      smsAuth(call, result);
    } else {
      result.notImplemented();
    }
  }


  // 主线程再返回数据
  private void runMainThread(final Map<String, Object> map, final Result result, final String method) {
    Handler handler = new Handler(Looper.getMainLooper());
    handler.post(new Runnable() {
      @Override
      public void run() {
        if (result == null && method != null) {
          channel.invokeMethod(method, map);
        } else {
          result.success(map);
        }
      }
    });
  }


  /**
   * SDK 初始换
   */
  private void setup(MethodCall call, Result result) {
    Log.d(TAG, "Action - setup:");

    Object timeout = getValueByKey(call, "timeout");
    boolean setControlWifiSwitch = (boolean) getValueByKey(call, "setControlWifiSwitch");
    if (!setControlWifiSwitch) {
      Log.d(TAG, "Action - setup: setControlWifiSwitch==" + false);
      setControlWifiSwitch();
    }

    JVerificationInterface.init(context, (Integer) timeout, new RequestCallback<String>() {
      @Override
      public void onResult(int code, String message) {
        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, message);
        // 通过 channel 返回
        runMainThread(map, null, "onReceiveSDKSetupCallBackEvent");
      }
    });
  }

  private void setControlWifiSwitch() {
    try {
      Class<JVerificationInterface> aClass = JVerificationInterface.class;
      Method method = aClass.getDeclaredMethod("setControlWifiSwitch", boolean.class);
      method.setAccessible(true);
      method.invoke(aClass, false);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }


  /**
   * SDK设置debug模式
   */
  private void setDebugMode(MethodCall call, Result result) {
    Log.d(TAG, "Action - setDebugMode:");
    Object enable = getValueByKey(call, "debug");
    if (enable != null) {
      JVerificationInterface.setDebugMode((Boolean) enable);
    }

    Map<String, Object> map = new HashMap<>();
    map.put(j_result_key, enable);
    runMainThread(map, result, null);
  }

  /**
   * SDK合规授权
   */
  private void setCollectionAuth(MethodCall call, Result result) {
    Log.d(TAG, "Action - setCollectionAuth:");
    Object enable = getValueByKey(call, "auth");
    JCollectionAuth.setAuth(context,(Boolean)enable);
    Map<String, Object> map = new HashMap<>();
    map.put(j_result_key, enable);
    runMainThread(map, result, null);
  }

  /**
   * 获取 SDK 初始化是否成功标识
   */
  private boolean isInitSuccess(MethodCall call, Result result) {
    Log.d(TAG, "Action - isInitSuccess:");
    boolean isSuccess = JVerificationInterface.isInitSuccess();
    if (!isSuccess) {
      Log.d(TAG, "SDK 初始化失败: ");
    }

    Map<String, Object> map = new HashMap<>();
    map.put(j_result_key, isSuccess);
    runMainThread(map, result, null);

    return isSuccess;
  }

  /**
   * 设置前后两次获取验证码的时间间隔，默认 30000ms，有效范围(0,300000)
   */
  private void setGetCodeInternal(MethodCall call, Result result) {
    Log.d(TAG, "Action - setSmsIntervalTime:");
    Object intervalTime = getValueByKey(call, "timeInterval");
    JVerificationInterface.setSmsIntervalTime((Long) intervalTime);
  }

  /**
   * 获取短信验证码
   */
  private void getSMSCode(MethodCall call, final Result result) {

    Object phoneNum = getValueByKey(call, "phoneNumber");
    Object signId = getValueByKey(call, "signId");
    Object tempId = getValueByKey(call, "tempId");

    if (phoneNum == null) {
      phoneNum = "0";
    }

    Log.d(TAG, "Action - getSmsCode:" + phoneNum);

    JVerificationInterface.getSmsCode(context, (String) phoneNum, (String) signId, (String) tempId, new RequestCallback<String>() {
      @Override
      public void onResult(int code, String s) {

        if (code == 3000) {//code: 返回码，3000代表获取成功，其他为失败
          Log.d(TAG, "uuid:" + s);
        } else {
          Log.e(TAG, "code=" + code + ", message=" + s);
        }

        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, s);
        map.put(j_result_key, s);

        runMainThread(map, result, null);
      }
    });
  }

  /**
   * SDK 判断网络环境是否支持
   */
  private boolean checkVerifyEnable(MethodCall call, Result result) {
    Log.d(TAG, "Action - checkVerifyEnable:");
    boolean verifyEnable = JVerificationInterface.checkVerifyEnable(context);
    if (!verifyEnable) {
      Log.d(TAG, "当前网络环境不支持");
    }

    Map<String, Object> map = new HashMap<>();
    map.put(j_result_key, verifyEnable);
    runMainThread(map, result, null);

    return verifyEnable;
  }

  /**
   * SDK获取号码认证token
   */
  private void getToken(final MethodCall call, final Result result) {
    Log.d(TAG, "Action - getToken:");

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      String timeOutString = call.argument("timeOut");

      try {
        timeOut = Integer.valueOf(timeOutString);
      } catch (Exception e) {
        Log.e(TAG, "timeOut type error.");
      }
    }


    JVerificationInterface.getToken(context, timeOut, new VerifyListener() {
      @Override
      public void onResult(final int code, final String content, final String operator, final JSONObject operatorReturn) {

        if (code == 2000) {//code: 返回码，2000代表获取成功，其他为失败
          Log.d(TAG, "token=" + content + ", operator=" + operator);
        } else {
          Log.e(TAG, "code=" + code + ", message=" + content);
        }

        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, content);
        map.put(j_opr_key, operator);

        runMainThread(map, result, null);
      }
    });
  }

  /**
   * SDK 发起号码认证
   */
  private void verifyNumber(MethodCall call, final Result result) {
    Log.d(TAG, "Action - verifyNumber:");
  }

  /**
   * SDK 一键登录预取号
   */
  private void preLogin(final MethodCall call, final Result result) {
    Log.d(TAG, "Action - preLogin:" + call.arguments);

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      timeOut = call.argument("timeOut");
    }

    JVerificationInterface.preLogin(context, timeOut, new PreLoginListener() {
      @Override
      public void onResult(final int code, final String content, final JSONObject operatorReturn) {

        if (code == 7000) {//code: 返回码，7000代表获取成功，其他为失败，详见错误码描述
          Log.d(TAG, "verify success, message =" + content);
        } else {
          Log.e(TAG, "verify fail，code=" + code + ", message =" + content);
        }
        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, content);

        runMainThread(map, result, null);
      }
    });
  }


  /**
   * SDK清除预取号缓存
   */
  private void clearPreLoginCache(MethodCall call, final Result result) {
    Log.d(TAG, "Action - clearPreLoginCache:");
    JVerificationInterface.clearPreLoginCache();
  }

  /**
   * SDK请求授权一键登录，异步
   */
  private void loginAuth(MethodCall call, final Result result) {
    Log.d(TAG, "Action - loginAuth:");
    loginAuthInterface(false, call, result);
  }

  /**
   * SDK请求授权一键登录，同步
   */
  private void loginAuthSyncApi(MethodCall call, final Result result) {
    Log.d(TAG, "Action - loginAuthSyncApi:");
    loginAuthInterface(true, call, result);
  }

  private void loginAuthInterface(final Boolean isSync, final MethodCall call, final Result result) {
    Log.d(TAG, "Action - loginAuthInterface:");

    Object autoFinish = getValueByKey(call, "autoDismiss");
    Integer timeOut = call.argument("timeout");
    final Integer loginAuthIndex = call.argument("loginAuthIndex");
    Object enableSMSService =  getValueByKey(call, "enableSms");

    AuthPageEventListener eventListener = new AuthPageEventListener() {
      @Override
      public void onEvent(int cmd, String msg) {
        Log.d(TAG, "Action - AuthPageEventListener: cmd = " + cmd);
        /// 事件
        final HashMap jsonMap = new HashMap();
        jsonMap.put(j_code_key, cmd);
        jsonMap.put(j_msg_key, msg);
        jsonMap.put("loginAuthIndex", loginAuthIndex);

        runMainThread(jsonMap, null, "onReceiveAuthPageEvent");
      }
    };

    VerifyListener listener = new VerifyListener() {
      @Override
      public void onResult(final int code, final String content, final String operator, JSONObject operatorReturn) {
        if (code == 6000) {
          Log.d(TAG, "code=" + code + ", token=" + content + " ,operator=" + operator);
        } else {
          Log.d(TAG, "code=" + code + ", message=" + content);
        }
        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, content);
        map.put(j_opr_key, operator);
        map.put("loginAuthIndex", loginAuthIndex);

        if (isSync) {
          // 通过 channel 返回
          runMainThread(map, null, "onReceiveLoginAuthCallBackEvent");
        } else {
          // 通过回调返回
          runMainThread(map, result, null);
        }
      }
    };

    if (enableSMSService != null) {
      JVerificationInterface.loginAuth((Boolean)enableSMSService, context, (Boolean) autoFinish, listener, eventListener);
    } else {
      LoginSettings settings = new LoginSettings();
      settings.setAutoFinish((Boolean) autoFinish);
      settings.setTimeout(timeOut);
      settings.setAuthPageEventListener(eventListener);

      JVerificationInterface.loginAuth(context, settings, listener);
    }

  }

  /**
   * SDK请求短信登录
   */
  private void smsAuth(MethodCall call, final Result result){
    Log.d(TAG, "Action - smsAuth:");

    Object autoFinish = getValueByKey(call, "autoDismiss");
    Integer timeOut = call.argument("timeout");
    final Integer smsAuthIndex = call.argument("smsAuthIndex");

    JVerificationInterface.smsLoginAuth(context, (Boolean) autoFinish, timeOut, new SmsListener(){
      @Override
      public void onResult(final int code, final String content,final String phone){
        Log.d(TAG, "smsAuth code=" + code + ", token=" + content + " ,phone=" + phone);

        Map<String, Object> map = new HashMap<>();
        map.put(j_code_key, code);
        map.put(j_msg_key, content);
        map.put(j_phone_key, phone);
        map.put("smsAuthIndex", smsAuthIndex);

        // 通过 channel 返回
        runMainThread(map, null, "onReceiveSMSAuthCallBackEvent");

      }
    });
  }

  /**
   * SDK关闭授权页面
   */
  private void dismissLoginAuthView(MethodCall call, Result result) {
    Log.d(TAG, "Action - dismissLoginAuthView:");

    JVerificationInterface.dismissLoginAuthActivity();
    JVerificationInterface.dismissLoginAuthActivity(true, new RequestCallback<String>() {
      @Override
      public void onResult(int i, String s) {

      }
    });
  }

  /**
   * 自定义授权界面 UI 、添加自定义控件
   */
  private void setCustomAuthViewAllWidgets(MethodCall call, Result result) {
    Log.d(TAG, "setCustomAuthViewAllWidgets:");

    Map uiconfig = call.argument("uiconfig");
    List<Map> widgetList = call.argument("widgets");


    JVerifyUIConfig.Builder builder = new JVerifyUIConfig.Builder();

    /// 布局 SDK 授权界面原有 UI
    layoutOriginOuthView(uiconfig, builder);

    if (widgetList != null) {
      for (Map widgetMap : widgetList) {

        /// 新增自定义的控件
        String type = (String) widgetMap.get("type");
        if (type.equals("textView")) {
          addCustomTextWidgets(widgetMap, builder, false);
        } else if (type.equals("button")) {
          addCustomButtonWidgets(widgetMap, builder, false);
        } else {
          Log.e(TAG, "don't support widget");
        }
      }
    }
    JVerificationInterface.setCustomUIWithConfig(builder.build());
  }

  private void setCustomAuthorizationView(MethodCall call, Result result) {
    Log.d(TAG, "setCustomAuthorizationView:");

    Boolean isAutorotate = (Boolean) call.argument("isAutorotate");
    Map portraitConfig = call.argument("portraitConfig");
    Map landscapeConfig = call.argument("landscapeConfig");
    List<Map> widgetList = call.argument("widgets");


    JVerifyUIConfig.Builder portraitBuilder = new JVerifyUIConfig.Builder();
    JVerifyUIConfig.Builder landscapeBuilder = new JVerifyUIConfig.Builder();

    /// 布局 SDK 授权界面原有 UI
    layoutOriginOuthView(portraitConfig, portraitBuilder);
    if (isAutorotate) {
      layoutOriginOuthView(landscapeConfig, landscapeBuilder);
    }


    if (widgetList != null) {
      for (Map widgetMap : widgetList) {
        /// 新增自定义的控件
        String type = (String) widgetMap.get("type");
        if (type.equals("textView")) {
          addCustomTextWidgets(widgetMap, portraitBuilder, false);
          if (isAutorotate) {
            addCustomTextWidgets(widgetMap, landscapeBuilder, false);
          }
        } else if (type.equals("button")) {
          addCustomButtonWidgets(widgetMap, portraitBuilder, false);
          if (isAutorotate) {
            addCustomButtonWidgets(widgetMap, landscapeBuilder, false);
          }
        } else {
          Log.e(TAG, "don't support widget");
        }
      }
    }
    JVerifyUIConfig portrait = portraitBuilder.build();
    if (isAutorotate) {
      JVerifyUIConfig landscape = landscapeBuilder.build();
      JVerificationInterface.setCustomUIWithConfig(portrait, landscape);
    } else {
      JVerificationInterface.setCustomUIWithConfig(portrait);
    }
  }


  /**
   * 自定义 SDK 原有的授权界面里的 UI
   */
  private void layoutOriginOuthView(Map uiconfig, JVerifyUIConfig.Builder builder) {
    Log.d(TAG, "layoutOriginOuthView:");


    Object enterAnim = valueForKey(uiconfig, "enterAnim");
    Object exitAnim = valueForKey(uiconfig, "exitAnim");
    Object authBGGifPath = valueForKey(uiconfig, "authBGGifPath");

    Object authBackgroundImage = valueForKey(uiconfig, "authBackgroundImage");
    Object authBGVideoPath = valueForKey(uiconfig, "authBGVideoPath");
    Object authBGVideoImgPath = valueForKey(uiconfig, "authBGVideoImgPath");

    Object navColor = valueForKey(uiconfig, "navColor");
    Object navText = valueForKey(uiconfig, "navText");
    Object navTextColor = valueForKey(uiconfig, "navTextColor");
    Object navTextBold = valueForKey(uiconfig, "navTextBold");
    Object navReturnImgPath = valueForKey(uiconfig, "navReturnImgPath");
    Object navHidden = valueForKey(uiconfig, "navHidden");
    Object navReturnBtnHidden = valueForKey(uiconfig, "navReturnBtnHidden");
    Object navTransparent = valueForKey(uiconfig, "navTransparent");

    Object logoImgPath = valueForKey(uiconfig, "logoImgPath");
    Object logoWidth = valueForKey(uiconfig, "logoWidth");
    Object logoHeight = valueForKey(uiconfig, "logoHeight");
    Object logoOffsetY = valueForKey(uiconfig, "logoOffsetY");
    Object logoOffsetX = valueForKey(uiconfig, "logoOffsetX");
    Object logoHidden = valueForKey(uiconfig, "logoHidden");
    Object logoOffsetBottomY = valueForKey(uiconfig, "logoOffsetBottomY");

    Object numberColor = valueForKey(uiconfig, "numberColor");
    Object numberSize = valueForKey(uiconfig, "numberSize");
    Object numberTextBold = valueForKey(uiconfig, "numberTextBold");
    Object numFieldOffsetY = valueForKey(uiconfig, "numFieldOffsetY");
    Object numFieldOffsetX = valueForKey(uiconfig, "numFieldOffsetX");
    Object numberFieldOffsetBottomY = valueForKey(uiconfig, "numberFieldOffsetBottomY");
    Object numberFieldWidth = valueForKey(uiconfig, "numberFieldWidth");
    Object numberFieldHeight = valueForKey(uiconfig, "numberFieldHeight");


    Object logBtnText = valueForKey(uiconfig, "logBtnText");
    Object logBtnOffsetY = valueForKey(uiconfig, "logBtnOffsetY");
    Object logBtnOffsetX = valueForKey(uiconfig, "logBtnOffsetX");
    Object logBtnBottomOffsetY = valueForKey(uiconfig, "logBtnBottomOffsetY");
    Object logBtnWidth = valueForKey(uiconfig, "logBtnWidth");
    Object logBtnHeight = valueForKey(uiconfig, "logBtnHeight");
    Object logBtnTextSize = valueForKey(uiconfig, "logBtnTextSize");
    Object logBtnTextColor = valueForKey(uiconfig, "logBtnTextColor");
    Object logBtnTextBold = valueForKey(uiconfig, "logBtnTextBold");
    Object logBtnBackgroundPath = valueForKey(uiconfig, "logBtnBackgroundPath");

    Object uncheckedImgPath = valueForKey(uiconfig, "uncheckedImgPath");
    Object checkedImgPath = valueForKey(uiconfig, "checkedImgPath");

    Object privacyTopOffsetY = valueForKey(uiconfig, "privacyTopOffsetY");
    Object privacyOffsetY = valueForKey(uiconfig, "privacyOffsetY");
    Object privacyOffsetX = valueForKey(uiconfig, "privacyOffsetX");
//        Object CLAUSE_NAME = valueForKey(uiconfig, "clauseName");
//        Object CLAUSE_URL = valueForKey(uiconfig, "clauseUrl");
    Object CLAUSE_BASE_COLOR = valueForKey(uiconfig, "clauseBaseColor");
    Object CLAUSE_COLOR = valueForKey(uiconfig, "clauseColor");
//        Object CLAUSE_NAME_TWO = valueForKey(uiconfig, "clauseNameTwo");
//        Object CLAUSE_URL_TWO = valueForKey(uiconfig, "clauseUrlTwo");
    Object privacyTextCenterGravity = valueForKey(uiconfig, "privacyTextCenterGravity");
    Object privacyText = valueForKey(uiconfig, "privacyText");
    Object privacyTextSize = valueForKey(uiconfig, "privacyTextSize");
    Object privacyTextBold = valueForKey(uiconfig, "privacyTextBold");
    Object privacyCheckboxHidden = valueForKey(uiconfig, "privacyCheckboxHidden");
    Object privacyCheckboxSize = valueForKey(uiconfig, "privacyCheckboxSize");
    Object privacyWithBookTitleMark = valueForKey(uiconfig, "privacyWithBookTitleMark");
    Object privacyCheckboxInCenter = valueForKey(uiconfig, "privacyCheckboxInCenter");
    Object privacyState = valueForKey(uiconfig, "privacyState");

    Object sloganOffsetY = valueForKey(uiconfig, "sloganOffsetY");
    Object sloganTextColor = valueForKey(uiconfig, "sloganTextColor");
    Object sloganOffsetX = valueForKey(uiconfig, "sloganOffsetX");
    Object sloganBottomOffsetY = valueForKey(uiconfig, "sloganBottomOffsetY");
    Object sloganTextSize = valueForKey(uiconfig, "sloganTextSize");
    Object sloganHidden = valueForKey(uiconfig, "sloganHidden");
    Object sloganTextBold = valueForKey(uiconfig, "sloganTextBold");
    Object privacyUnderlineText = valueForKey(uiconfig, "privacyUnderlineText");

    Object privacyNavColor = valueForKey(uiconfig, "privacyNavColor");
    Object privacyNavTitleTextColor = valueForKey(uiconfig, "privacyNavTitleTextColor");
    Object privacyNavTitleTextSize = valueForKey(uiconfig, "privacyNavTitleTextSize");
    Object privacyNavTitleTextBold = valueForKey(uiconfig, "privacyNavTitleTextBold");
    Object privacyNavReturnBtnPath = valueForKey(uiconfig, "privacyNavReturnBtnImage");
    Object privacyNavTitleTitle1 = valueForKey(uiconfig, "privacyNavTitleTitle1");
    Object privacyNavTitleTitle2 = valueForKey(uiconfig, "privacyNavTitleTitle2");

    Object statusBarColorWithNav = valueForKey(uiconfig, "statusBarColorWithNav");
    Object statusBarDarkMode = valueForKey(uiconfig, "statusBarDarkMode");
    Object statusBarTransparent = valueForKey(uiconfig, "statusBarTransparent");
    Object statusBarHidden = valueForKey(uiconfig, "statusBarHidden");
    Object virtualButtonTransparent = valueForKey(uiconfig, "virtualButtonTransparent");

    Object privacyStatusBarColorWithNav = valueForKey(uiconfig, "privacyStatusBarColorWithNav");
    Object privacyStatusBarDarkMode = valueForKey(uiconfig, "privacyStatusBarDarkMode");
    Object privacyStatusBarTransparent = valueForKey(uiconfig, "privacyStatusBarTransparent");
    Object privacyStatusBarHidden = valueForKey(uiconfig, "privacyStatusBarHidden");
    Object privacyVirtualButtonTransparent = valueForKey(uiconfig, "privacyVirtualButtonTransparent");

    Object needStartAnim = valueForKey(uiconfig, "needStartAnim");
    Object needCloseAnim = valueForKey(uiconfig, "needCloseAnim");

    Object popViewConfig = valueForKey(uiconfig, "popViewConfig");

    Object privacyHintToast = valueForKey(uiconfig, "privacyHintToast");

    Object privacyItem = valueForKey(uiconfig, "privacyItem");

    Object setIsPrivacyViewDarkMode = valueForKey(uiconfig, "setIsPrivacyViewDarkMode");


    /************* 状态栏 ***************/
    if (statusBarColorWithNav != null) {
      builder.setStatusBarColorWithNav((Boolean) statusBarColorWithNav);
    }

    if (statusBarDarkMode != null) {
      builder.setStatusBarDarkMode((Boolean) statusBarDarkMode);
    }

    if (statusBarTransparent != null) {
      builder.setStatusBarTransparent((Boolean) statusBarTransparent);
    }

    if (statusBarHidden != null) {
      builder.setStatusBarHidden((Boolean) statusBarHidden);
    }

    if (virtualButtonTransparent != null) {
      builder.setVirtualButtonTransparent((Boolean) virtualButtonTransparent);
    }

    /************** web页 ***************/
    if (privacyStatusBarColorWithNav != null) {
      builder.setPrivacyStatusBarColorWithNav((Boolean) privacyStatusBarColorWithNav);
    }

    if (privacyStatusBarDarkMode != null) {
      builder.setPrivacyStatusBarDarkMode((Boolean) privacyStatusBarDarkMode);
    }

    if (privacyStatusBarTransparent != null) {
      builder.setPrivacyStatusBarTransparent((Boolean) privacyStatusBarTransparent);
    }

    if (privacyStatusBarHidden != null) {
      builder.setPrivacyStatusBarHidden((Boolean) privacyStatusBarHidden);
    }

    if (privacyVirtualButtonTransparent != null) {
      builder.setPrivacyVirtualButtonTransparent((Boolean) privacyVirtualButtonTransparent);
    }

    /************** 动画支持 ***************/
    if (needStartAnim != null) {
      builder.setNeedStartAnim((Boolean) needStartAnim);
    }
    if (needCloseAnim != null) {
      builder.setNeedCloseAnim((Boolean) needCloseAnim);
    }

    int enterA;
    int exitA;

    if (enterAnim != null && exitAnim != null) {
      enterA = ResourceUtil.getAnimId(context, (String) enterAnim);
      exitA = ResourceUtil.getAnimId(context, (String) exitAnim);
      if (enterA >= 0 && exitA >= 0) {
        builder.overridePendingTransition(enterA, exitA);
      }
    }

    /************** 背景 ***************/
    if (authBackgroundImage != null) {
      int res_id = getResourceByReflect((String) authBackgroundImage);
      if (res_id > 0) {
        builder.setAuthBGImgPath((String) authBackgroundImage);
      }
    }

    if (authBGGifPath != null) {
      int res_id = getResourceByReflect((String) authBGGifPath);
      if (res_id > 0) {
        builder.setAuthBGGifPath((String) authBGGifPath);
      }
    }

    if (authBGVideoPath != null) {
      if (!((String)authBGVideoPath).startsWith("http"))
        authBGVideoPath = "android.resource://"+context.getPackageName()+"/raw/"+authBGVideoPath;
      builder.setAuthBGVideoPath((String) authBGVideoPath, (String) authBGVideoImgPath);
    }

    /************** nav ***************/
    if (navHidden != null) {
      builder.setNavHidden((Boolean) navHidden);
    }
    if (navReturnBtnHidden != null) {
      builder.setNavReturnBtnHidden((Boolean) navReturnBtnHidden);
    }
    if (navTransparent != null) {
      builder.setNavTransparent((Boolean) navTransparent);
    }
    if (navColor != null) {
      builder.setNavColor(exchangeObject(navColor));
    }
    if (navText != null) {
      builder.setNavText((String) navText);
    }
    if (navTextColor != null) {
      builder.setNavTextColor(exchangeObject(navTextColor));
    }
    if (navTextBold != null) {
      builder.setNavTextBold((Boolean) navTextBold);
    }
    if (navReturnImgPath != null) {
      builder.setNavReturnImgPath((String) navReturnImgPath);
    }

    /************** logo ***************/
    if (logoWidth != null) {
      builder.setLogoWidth((Integer) logoWidth);
    }
    if (logoHeight != null) {
      builder.setLogoHeight((Integer) logoHeight);
    }
    if (logoOffsetY != null) {
      builder.setLogoOffsetY((Integer) logoOffsetY);
    }
    if (logoOffsetX != null) {
      builder.setLogoOffsetX((Integer) logoOffsetX);
    }
    if (logoHidden != null) {
      builder.setLogoHidden((Boolean) logoHidden);
    }
    if (logoImgPath != null) {
      int res_id = getResourceByReflect((String) logoImgPath);
      if (res_id > 0) {
        builder.setLogoImgPath((String) logoImgPath);
      }
    }
    if (logoOffsetBottomY != null) {
      builder.setLogoOffsetBottomY((Integer) logoOffsetBottomY);
    }

    /************** number ***************/
    if (numberFieldOffsetBottomY != null) {
      builder.setNumberFieldOffsetBottomY((Integer) numberFieldOffsetBottomY);
    }
    if (numFieldOffsetY != null) {
      builder.setNumFieldOffsetY((Integer) numFieldOffsetY);
    }
    if (numFieldOffsetX != null) {
      builder.setNumFieldOffsetX((Integer) numFieldOffsetX);
    }
    if (numberFieldWidth != null) {
      builder.setNumberFieldWidth((Integer) numberFieldWidth);
    }
    if (numberFieldHeight != null) {
      builder.setNumberFieldHeight((Integer) numberFieldHeight);
    }
    if (numberColor != null) {
      builder.setNumberColor(exchangeObject(numberColor));
    }
    if (numberSize != null) {
      builder.setNumberSize((Number) numberSize);
    }
    if (numberTextBold != null) {
      builder.setNumberTextBold((Boolean) numberTextBold);
    }


    /************** slogan ***************/
    if (sloganOffsetY != null) {
      builder.setSloganOffsetY((Integer) sloganOffsetY);
    }
    if (sloganOffsetX != null) {
      builder.setSloganOffsetX((Integer) sloganOffsetX);
    }
    if (sloganBottomOffsetY != null) {
      builder.setSloganBottomOffsetY((Integer) sloganBottomOffsetY);
    }
    if (sloganTextSize != null) {
      builder.setSloganTextSize((Integer) sloganTextSize);
    }
    if (sloganTextColor != null) {
      builder.setSloganTextColor(exchangeObject(sloganTextColor));
    }
    if (sloganHidden != null) {
      builder.setSloganHidden((Boolean) sloganHidden);
    }
    if (sloganTextBold != null) {
      builder.setSloganTextBold((Boolean) sloganTextBold);
    }


    /************** login btn ***************/
    if (logBtnOffsetY != null) {
      builder.setLogBtnOffsetY((Integer) logBtnOffsetY);
    }
    if (logBtnOffsetX != null) {
      builder.setLogBtnOffsetX((Integer) logBtnOffsetX);
    }
    if (logBtnBottomOffsetY != null) {
      builder.setLogoOffsetY(-1);
      builder.setLogBtnBottomOffsetY((Integer) logBtnBottomOffsetY);
    }
    if (logBtnWidth != null) {
      builder.setLogBtnWidth((Integer) logBtnWidth);
    }
    if (logBtnHeight != null) {
      builder.setLogBtnHeight((Integer) logBtnHeight);
    }
    if (logBtnText != null) {
      builder.setLogBtnText((String) logBtnText);
    }
    if (logBtnTextSize != null) {
      builder.setLogBtnTextSize((Integer) logBtnTextSize);
    }
    if (logBtnTextColor != null) {
      builder.setLogBtnTextColor(exchangeObject(logBtnTextColor));
    }
    if (logBtnTextBold != null) {
      builder.setLogBtnTextBold((Boolean) logBtnTextBold);
    }
    if (logBtnBackgroundPath != null) {
      int res_id = getResourceByReflect((String) logBtnBackgroundPath);
      if (res_id > 0) {
        builder.setLogBtnImgPath((String) logBtnBackgroundPath);
      }
    }

    /************** check box ***************/
    builder.setPrivacyCheckboxHidden((Boolean) privacyCheckboxHidden);
    if (privacyCheckboxSize != null) {
      builder.setPrivacyCheckboxSize((Integer) privacyCheckboxSize);
    }
    if (uncheckedImgPath != null) {
      int res_id = getResourceByReflect((String) uncheckedImgPath);
      if (res_id > 0) {
        builder.setUncheckedImgPath((String) uncheckedImgPath);
      }
    }
    if (checkedImgPath != null) {
      int res_id = getResourceByReflect((String) checkedImgPath);
      if (res_id > 0) {
        builder.setCheckedImgPath((String) checkedImgPath);
      }
    }

    /************** privacy ***************/
    if (privacyOffsetY != null) {
      //设置隐私条款相对于授权页面底部下边缘y偏移
      builder.setPrivacyOffsetY((Integer) privacyOffsetY);
    } else {
      if (privacyTopOffsetY != null) {
        //设置隐私条款相对导航栏下端y轴偏移。since 2.4.8
        builder.setPrivacyTopOffsetY((Integer) privacyTopOffsetY);
      }
    }
    if (privacyOffsetX != null) {
      builder.setPrivacyOffsetX((Integer) privacyOffsetX);
    }
    if (privacyCheckboxSize != null) {
      builder.setPrivacyCheckboxSize((Integer) privacyCheckboxSize);
    }
    if (privacyTextSize != null) {
      builder.setPrivacyTextSize((Integer) privacyTextSize);
    }
    if (privacyText != null) {
      ArrayList<String> privacyTextList = (ArrayList) privacyText;
      privacyTextList.addAll(Arrays.asList("", "", "", ""));
      builder.setPrivacyText(privacyTextList.get(0), privacyTextList.get(1));
    }
    if (privacyTextBold != null) {
      builder.setPrivacyTextBold((Boolean) privacyTextBold);
    }
    if (privacyUnderlineText != null) {
      builder.setPrivacyUnderlineText((Boolean) privacyUnderlineText);
    }

    builder.setPrivacyTextCenterGravity((Boolean) privacyTextCenterGravity);
    builder.setPrivacyWithBookTitleMark((Boolean) privacyWithBookTitleMark);
    builder.setPrivacyCheckboxInCenter((Boolean) privacyCheckboxInCenter);
    builder.setPrivacyState((Boolean) privacyState);

    if (privacyItem != null) {
      try {
        JSONArray jsonArray = new JSONArray((String) privacyItem);
        int length = jsonArray.length();
        JSONObject jsonObject;
        PrivacyBean privacyBean;
        ArrayList<PrivacyBean> privacyBeans = new ArrayList<>(length);
        for (int i = 0; i < length; i++) {
          jsonObject = jsonArray.optJSONObject(i);
          privacyBean = new PrivacyBean(jsonObject.optString("name"), jsonObject.optString("url"),
                  jsonObject.optString("separator"));

          privacyBeans.add(privacyBean);
        }

        builder.setPrivacyNameAndUrlBeanList(privacyBeans);
      } catch (JSONException e) {
        e.printStackTrace();
      }
    }

    int baseColor = -10066330;
    int color = -16007674;
    if (CLAUSE_BASE_COLOR != null) {
      if (CLAUSE_BASE_COLOR instanceof Long) {
        baseColor = ((Long) CLAUSE_BASE_COLOR).intValue();
      } else {
        baseColor = (Integer) CLAUSE_BASE_COLOR;
      }
    }
    if (CLAUSE_COLOR != null) {
      if (CLAUSE_COLOR instanceof Long) {
        color = ((Long) CLAUSE_COLOR).intValue();
      } else {
        color = (Integer) CLAUSE_COLOR;
      }
    }
    builder.setAppPrivacyColor(baseColor, color);

    /************** 隐私 web 页面 ***************/
    if (privacyNavColor != null) {
      builder.setPrivacyNavColor(exchangeObject(privacyNavColor));
    }
    if (privacyNavTitleTextSize != null) {
      builder.setPrivacyNavTitleTextSize(exchangeObject(privacyNavTitleTextSize));
    }
    if (privacyNavTitleTextColor != null) {
      builder.setPrivacyNavTitleTextColor(exchangeObject(privacyNavTitleTextColor));
    }
//        if (privacyNavTitleTitle1 != null) {
//            builder.setAppPrivacyNavTitle1((String) privacyNavTitleTitle1);
//        }
//        if (privacyNavTitleTitle2 != null) {
//            builder.setAppPrivacyNavTitle2((String) privacyNavTitleTitle2);
//        }

    if (privacyNavTitleTextBold != null) {
      builder.setPrivacyNavTitleTextBold((Boolean) privacyNavTitleTextBold);
    }

    if (privacyNavReturnBtnPath != null) {
      int res_id = getResourceByReflect((String) privacyNavReturnBtnPath);
      if (res_id > 0) {
        builder.setPrivacyNavReturnBtnPath((String) privacyNavReturnBtnPath);
      }
    }

    builder.enableHintToast((Boolean) privacyHintToast, null);
    /************** 授权页弹窗模式 ***************/
    if (popViewConfig != null) {
      Map popViewConfigMap = (Map) popViewConfig;
      Object isPopViewTheme = valueForKey(popViewConfigMap, "isPopViewTheme");
      if ((Boolean) isPopViewTheme) {
        Object width = valueForKey(popViewConfigMap, "width");
        Object height = valueForKey(popViewConfigMap, "height");
        Object offsetCenterX = valueForKey(popViewConfigMap, "offsetCenterX");
        Object offsetCenterY = valueForKey(popViewConfigMap, "offsetCenterY");
        Object isBottom = valueForKey(popViewConfigMap, "isBottom");

        builder.setDialogTheme((int) width, (int) height, (int) offsetCenterX, (int) offsetCenterY, (Boolean) isBottom);

      }
    }

    Object privacyCheckDialogConfig = valueForKey(uiconfig, "privacyCheckDialogConfig");

    /************** 协议的二次弹窗配置 ***************/
    if (privacyCheckDialogConfig != null) {
      Map privacyCheckDialogConfigMap = (Map) privacyCheckDialogConfig;
      Object enablePrivacyCheckDialog = valueForKey(privacyCheckDialogConfigMap, "enablePrivacyCheckDialog");
      if ((Boolean) enablePrivacyCheckDialog) {
        Object width = valueForKey(privacyCheckDialogConfigMap, "width");
        Object height = valueForKey(privacyCheckDialogConfigMap, "height");
        Object offsetX = valueForKey(privacyCheckDialogConfigMap, "offsetX");
        Object offsetY = valueForKey(privacyCheckDialogConfigMap, "offsetY");
        Object gravity = valueForKey(privacyCheckDialogConfigMap, "gravity");

        if(width !=null){
          builder.setPrivacyCheckDialogWidth((int) width);
        }
        if(height !=null) {
          builder.setPrivacyCheckDialogHeight((int) height);
        }
        if(offsetX !=null) {
          builder.setPrivacyCheckDialogOffsetX((int) offsetX);
        }
        if(offsetX !=null) {
          builder.setPrivacyCheckDialogOffsetY((int) offsetY);
        }
        if(gravity !=null) {
          builder.setprivacyCheckDialogGravity(getAlignmentFromString((String) gravity));
        }

        Object dialogTitle = valueForKey(privacyCheckDialogConfigMap, "title");
        if(dialogTitle !=null) {
          builder.setPrivacyCheckDialogTitleText((String) dialogTitle);
        }


        Object titleTextSize = valueForKey(privacyCheckDialogConfigMap, "titleTextSize");
        if(titleTextSize !=null) {
          builder.setPrivacyCheckDialogTitleTextSize(exchangeObject(titleTextSize));
        }

        Object titleTextColor = valueForKey(privacyCheckDialogConfigMap, "titleTextColor");
        Object contentTextSize = valueForKey(privacyCheckDialogConfigMap, "contentTextSize");

        builder.enablePrivacyCheckDialog(true);

        if(titleTextColor != null){
          builder.setPrivacyCheckDialogTitleTextColor(exchangeObject(titleTextColor));
        }
        Object gravity_privacyCheckDialog = valueForKey(privacyCheckDialogConfigMap, "gravity");
        if(gravity_privacyCheckDialog != null){
          builder.setPrivacyCheckDialogContentTextGravity(getAlignmentFromString((String) gravity_privacyCheckDialog));
        }
        if(contentTextSize != null){
          builder.setPrivacyCheckDialogContentTextSize(exchangeObject(contentTextSize));
        }

        Object dialogLoginBtnText = valueForKey(privacyCheckDialogConfigMap, "logBtnText");
        Object logBtnImgPath = valueForKey(privacyCheckDialogConfigMap, "logBtnImgPath");
        Object logBtnTextColor_dialog = valueForKey(privacyCheckDialogConfigMap, "logBtnTextColor");
        Object logBtnMarginL = valueForKey(privacyCheckDialogConfigMap, "logBtnMarginL");
        Object logBtnMarginR = valueForKey(privacyCheckDialogConfigMap, "logBtnMarginR");
        Object logBtnMarginT = valueForKey(privacyCheckDialogConfigMap, "logBtnMarginT");
        Object logBtnMarginB = valueForKey(privacyCheckDialogConfigMap, "logBtnMarginB");
        Object dialogLogBtnWidth = valueForKey(privacyCheckDialogConfigMap, "logBtnWidth");
        Object dialogLogBtnHeight = valueForKey(privacyCheckDialogConfigMap, "logBtnHeight");
        Object privacyBackgroundColor = valueForKey(privacyCheckDialogConfigMap, "privacyBackgroundColor");
        Object privacyBackgroundPath = valueForKey(privacyCheckDialogConfigMap, "privacyBackgroundPath");

        if(dialogLoginBtnText !=null) {
          builder.setPrivacyCheckDialogLogBtnText((String) dialogLoginBtnText);
        }
        if(logBtnImgPath != null){
          int res_id_logBtnImgPath = getResourceByReflect((String) logBtnImgPath);
          if (res_id_logBtnImgPath > 0) {
            builder.setPrivacyCheckDialogLogBtnImgPath((String) logBtnImgPath);
          }
        }
        if (logBtnTextColor_dialog != null){
          builder.setPrivacyCheckDialoglogBtnTextColor(exchangeObject(logBtnTextColor_dialog));
        }
        if(logBtnMarginL !=null) {
          builder.setPrivacyCheckDialogLogBtnMarginL((int) logBtnMarginL);
        }
        if(logBtnMarginR !=null) {
          builder.setPrivacyCheckDialogLogBtnMarginR((int) logBtnMarginR);
        }
        if(logBtnMarginT !=null) {
          builder.setPrivacyCheckDialogLogBtnMarginT((int) logBtnMarginT);
        }
        if(logBtnMarginB !=null) {
          builder.setPrivacyCheckDialogLogBtnMarginB((int) logBtnMarginB);
        }
        if(dialogLogBtnWidth !=null) {
          builder.setPrivacyCheckDialogLogBtnWidth((int) dialogLogBtnWidth);
        }
        if(dialogLogBtnHeight !=null) {
          builder.setPrivacyCheckDialogLogBtnHeight((int) dialogLogBtnHeight);
        }

        if(privacyBackgroundColor !=null) {
          if (privacyBackgroundColor instanceof Long) {
            builder.setPrivacyCheckDialogBackgroundColor(((Long) privacyBackgroundColor).intValue());
          } else {
            builder.setPrivacyCheckDialogBackgroundColor((int) privacyBackgroundColor);
          }
        }
        if(privacyBackgroundPath != null){
          int res_id_privacyBackgroundPath = getResourceByReflect((String) privacyBackgroundPath);
          if (res_id_privacyBackgroundPath > 0) {
            builder.setPrivacyCheckDialogBackgroundImgPath((String) privacyBackgroundPath);
          }
        }
        Object widgets = valueForKey(privacyCheckDialogConfigMap,"widgets");
        if (widgets != null) {
          List<Map> widgetList = (List) widgets;
          for (Map widgetMap : widgetList) {
            /// 新增自定义的控件
            String type = (String) widgetMap.get("type");
            if (type.equals("textView")) {
              addCustomTextWidgets(widgetMap, builder, true);
            } else if (type.equals("button")) {
              addCustomButtonWidgets(widgetMap, builder, true);
            } else {
              Log.e(TAG, "don't support widget");
            }
          }
        }
      }
    }

    /************** 协议页面是否支持暗黑模式 ***************/
    if (setIsPrivacyViewDarkMode != null) {
      builder.setIsPrivacyViewDarkMode((Boolean)setIsPrivacyViewDarkMode);
    }


    /************** SMS UI配置***************/
    Object smsUIConfig = valueForKey(uiconfig, "smsUIConfig");

    if (smsUIConfig != null) {
      Map smsUIConfigMap = (Map) smsUIConfig;
      Object enableSMSService = valueForKey(smsUIConfigMap, "enableSMSService");
      if (enableSMSService != null && (Boolean) enableSMSService) {

        Object smsNavText = valueForKey(smsUIConfigMap, "smsNavText");
        Object smsSloganTextSize = valueForKey(smsUIConfigMap, "smsSloganTextSize");
        Object isSmsSloganHidden = valueForKey(smsUIConfigMap, "isSmsSloganHidden");
        Object isSmsSloganTextBold = valueForKey(smsUIConfigMap, "isSmsSloganTextBold");
        Object smsSloganOffsetX = valueForKey(smsUIConfigMap, "smsSloganOffsetX");
        Object smsSloganOffsetY = valueForKey(smsUIConfigMap, "smsSloganOffsetY");
        Object smsSloganOffsetBottomY = valueForKey(smsUIConfigMap, "smsSloganOffsetBottomY");
        Object smsSloganTextColor = valueForKey(smsUIConfigMap, "smsSloganTextColor");
        Object smsLogoWidth = valueForKey(smsUIConfigMap, "smsLogoWidth");
        Object smsLogoHeight = valueForKey(smsUIConfigMap, "smsLogoHeight");
        Object smsLogoOffsetX = valueForKey(smsUIConfigMap, "smsLogoOffsetX");
        Object smsLogoOffsetY = valueForKey(smsUIConfigMap, "smsLogoOffsetY");
        Object smsLogoOffsetBottomY = valueForKey(smsUIConfigMap, "smsLogoOffsetBottomY");
        Object isSmsLogoHidden = valueForKey(smsUIConfigMap, "isSmsLogoHidden");
        Object smsLogoResName = valueForKey(smsUIConfigMap, "smsLogoResName");

        if(smsNavText !=null){
          builder.setSmsNavText((String) smsNavText);
        }
        if(smsSloganTextSize !=null){
          builder.setSmsSloganTextSize((Integer) smsSloganTextSize);
        }
        if(isSmsSloganHidden !=null){
          builder.setSmsSloganHidden((Boolean) isSmsSloganHidden);
        }
        if(isSmsSloganTextBold !=null){
          builder.setSmsSloganTextBold((Boolean) isSmsSloganTextBold);
        }
        if(smsSloganOffsetX !=null){
          builder.setSmsSloganOffsetX((Integer) smsSloganOffsetX);
        }
        if(smsSloganOffsetY !=null){
          builder.setSmsSloganOffsetY((Integer) smsSloganOffsetY);
        }
        if(smsSloganOffsetBottomY !=null){
          builder.setSmsSloganOffsetBottomY((Integer) smsSloganOffsetBottomY);
        }
        if(smsSloganTextColor !=null){
          builder.setSmsSloganTextColor((Integer) smsSloganTextColor);
        }
        if(smsLogoWidth !=null){
          builder.setSmsLogoWidth((Integer) smsLogoWidth);
        }
        if(smsLogoHeight !=null){
          builder.setSmsLogoHeight((Integer) smsLogoHeight);
        }
        if(smsLogoOffsetX !=null){
          builder.setSmsLogoOffsetX((Integer) smsLogoOffsetX);
        }
        if(smsLogoOffsetY !=null){
          builder.setSmsLogoOffsetY((Integer) smsLogoOffsetY);
        }
        if(smsLogoOffsetBottomY !=null){
          builder.setSmsLogoOffsetBottomY((Integer) smsLogoOffsetBottomY);
        }
        if(isSmsLogoHidden !=null){
          builder.setSmsLogoHidden((Boolean) isSmsLogoHidden);
        }
        if(smsLogoResName !=null){
          int res_id_smsLogoPath = getResourceByReflect((String) smsLogoResName);
          if (res_id_smsLogoPath > 0) {
            builder.setSmsLogoImgPath((String) smsLogoResName);
          }
        }


        Object smsPhoneTextViewOffsetX = valueForKey(smsUIConfigMap, "smsPhoneTextViewOffsetX");
        Object smsPhoneTextViewOffsetY = valueForKey(smsUIConfigMap, "smsPhoneTextViewOffsetY");
        Object smsPhoneTextViewTextSize = valueForKey(smsUIConfigMap, "smsPhoneTextViewTextSize");
        Object smsPhoneTextViewTextColor = valueForKey(smsUIConfigMap, "smsPhoneTextViewTextColor");
        Object smsPhoneInputViewOffsetX = valueForKey(smsUIConfigMap, "smsPhoneInputViewOffsetX");
        Object smsPhoneInputViewOffsetY = valueForKey(smsUIConfigMap, "smsPhoneInputViewOffsetY");
        Object smsPhoneInputViewWidth = valueForKey(smsUIConfigMap, "smsPhoneInputViewWidth");
        Object smsPhoneInputViewHeight = valueForKey(smsUIConfigMap, "smsPhoneInputViewHeight");
        Object smsPhoneInputViewTextColor = valueForKey(smsUIConfigMap, "smsPhoneInputViewTextColor");
        Object smsPhoneInputViewTextSize = valueForKey(smsUIConfigMap, "smsPhoneInputViewTextSize");
        Object smsVerifyCodeTextViewOffsetX = valueForKey(smsUIConfigMap, "smsVerifyCodeTextViewOffsetX");
        Object smsVerifyCodeTextViewOffsetY = valueForKey(smsUIConfigMap, "smsVerifyCodeTextViewOffsetY");
        Object smsVerifyCodeTextViewTextSize = valueForKey(smsUIConfigMap, "smsVerifyCodeTextViewTextSize");
        Object smsVerifyCodeTextViewTextColor = valueForKey(smsUIConfigMap, "smsVerifyCodeTextViewTextColor");
        Object smsVerifyCodeEditTextViewTextSize = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewTextSize");
        Object smsVerifyCodeEditTextViewTextColor = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewTextColor");
        Object smsVerifyCodeEditTextViewOffsetX = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewOffsetX");
        Object smsVerifyCodeEditTextViewOffsetY = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewOffsetY");
        Object smsVerifyCodeEditTextViewOffsetR = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewOffsetR");
        Object smsVerifyCodeEditTextViewWidth = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewWidth");
        Object smsVerifyCodeEditTextViewHeight = valueForKey(smsUIConfigMap, "smsVerifyCodeEditTextViewHeight");
        Object smsGetVerifyCodeTextViewOffsetX = valueForKey(smsUIConfigMap, "smsGetVerifyCodeTextViewOffsetX");
        Object smsGetVerifyCodeTextViewOffsetY = valueForKey(smsUIConfigMap, "smsGetVerifyCodeTextViewOffsetY");
        Object smsGetVerifyCodeTextViewTextSize = valueForKey(smsUIConfigMap, "smsGetVerifyCodeTextViewTextSize");
        Object smsGetVerifyCodeTextViewTextColor = valueForKey(smsUIConfigMap, "smsGetVerifyCodeTextViewTextColor");
        Object smsGetVerifyCodeTextViewOffsetR = valueForKey(smsUIConfigMap, "smsGetVerifyCodeTextViewOffsetR");
        Object smsGetVerifyCodeBtnBackgroundPath = valueForKey(smsUIConfigMap, "smsGetVerifyCodeBtnBackgroundPath");

        if(smsPhoneTextViewOffsetX !=null){
          builder.setSmsPhoneTextViewOffsetX((Integer) smsPhoneTextViewOffsetX);
        }
        if(smsPhoneTextViewOffsetY !=null){
          builder.setSmsPhoneTextViewOffsetY((Integer) smsPhoneTextViewOffsetY);
        }
        if(smsPhoneTextViewTextSize !=null){
          builder.setSmsPhoneTextViewTextSize((Integer) smsPhoneTextViewTextSize);
        }
        if(smsPhoneTextViewTextColor !=null){
          builder.setSmsPhoneTextViewTextColor((Integer) smsPhoneTextViewTextColor);
        }
        if(smsPhoneInputViewOffsetX !=null){
          builder.setSmsPhoneInputViewOffsetX((Integer) smsPhoneInputViewOffsetX);
        }
        if(smsPhoneInputViewOffsetY !=null){
          builder.setSmsPhoneInputViewOffsetY((Integer) smsPhoneInputViewOffsetY);
        }
        if(smsPhoneInputViewWidth !=null){
          builder.setSmsPhoneInputViewWidth((Integer) smsPhoneInputViewWidth);
        }
        if(smsPhoneInputViewHeight !=null){
          builder.setSmsPhoneInputViewHeight((Integer) smsPhoneInputViewHeight);
        }
        if(smsPhoneInputViewTextColor !=null){
          builder.setSmsPhoneInputViewTextColor((Integer) smsPhoneInputViewTextColor);
        }
        if(smsPhoneInputViewTextSize !=null){
          builder.setSmsPhoneInputViewTextSize((Integer) smsPhoneInputViewTextSize);
        }
        if(smsVerifyCodeTextViewOffsetX !=null){
          builder.setSmsVerifyCodeTextViewOffsetX((Integer) smsVerifyCodeTextViewOffsetX);
        }
        if(smsVerifyCodeTextViewOffsetY !=null){
          builder.setSmsVerifyCodeTextViewOffsetY((Integer) smsVerifyCodeTextViewOffsetY);
        }
        if(smsVerifyCodeTextViewTextSize !=null){
          builder.setSmsVerifyCodeTextSizeTextSize((Integer) smsVerifyCodeTextViewTextSize);
        }
        if(smsVerifyCodeTextViewTextColor !=null){
          builder.setSmsVerifyCodeTextViewTextColor((Integer) smsVerifyCodeTextViewTextColor);
        }
        if(smsVerifyCodeEditTextViewTextSize !=null){
          builder.setSmsVerifyCodeEditTextViewTextSize((Integer) smsVerifyCodeEditTextViewTextSize);
        }
        if(smsVerifyCodeEditTextViewTextColor !=null){
          builder.setSmsVerifyCodeEditTextViewTextColor((Integer) smsVerifyCodeEditTextViewTextColor);
        }
        if(smsVerifyCodeEditTextViewOffsetX !=null){
          builder.setSmsVerifyCodeEditTextViewTextOffsetX((Integer) smsVerifyCodeEditTextViewOffsetX);
        }
        if(smsVerifyCodeEditTextViewOffsetY !=null){
          builder.setSmsVerifyCodeEditTextViewOffsetY((Integer) smsVerifyCodeEditTextViewOffsetY);
        }
        if(smsVerifyCodeEditTextViewOffsetR !=null){
          builder.setSmsVerifyCodeEditTextViewOffsetR((Integer) smsVerifyCodeEditTextViewOffsetR);
        }
        if(smsVerifyCodeEditTextViewWidth !=null){
          builder.setSmsVerifyCodeEditTextViewWidth((Integer) smsVerifyCodeEditTextViewWidth);
        }
        if(smsVerifyCodeEditTextViewHeight !=null){
          builder.setSmsVerifyCodeEditTextViewHeight((Integer) smsVerifyCodeEditTextViewHeight);
        }
        if(smsGetVerifyCodeTextViewOffsetX !=null){
          builder.setSmsGetVerifyCodeTextViewOffsetX((Integer) smsGetVerifyCodeTextViewOffsetX);
        }
        if(smsGetVerifyCodeTextViewOffsetY !=null){
          builder.setSmsGetVerifyCodeTextViewOffsetY((Integer) smsGetVerifyCodeTextViewOffsetY);
        }
        if(smsGetVerifyCodeTextViewTextSize !=null){
          builder.setSmsGetVerifyCodeTextSize((Integer) smsGetVerifyCodeTextViewTextSize);
        }
        if(smsGetVerifyCodeTextViewTextColor !=null){
          builder.setSmsGetVerifyCodeTextViewTextColor((Integer) smsGetVerifyCodeTextViewTextColor);
        }
//                if(smsGetVerifyCodeTextViewOffsetR !=null){
//                    builder.setSmsGetVerifyCodeTextViewOffsetR((Integer) smsGetVerifyCodeTextViewOffsetR);
//                }
        if(smsGetVerifyCodeBtnBackgroundPath !=null){
          int res_id_smsGetVerifyCodeBtnBackgroundPath = getResourceByReflect((String) smsGetVerifyCodeBtnBackgroundPath);
          if (res_id_smsGetVerifyCodeBtnBackgroundPath > 0) {
            builder.setSmsGetVerifyCodeBtnBackgroundPath((String) smsGetVerifyCodeBtnBackgroundPath);
          }
        }


        Object smsLogBtnOffsetX = valueForKey(smsUIConfigMap, "smsLogBtnOffsetX");
        Object smsLogBtnOffsetY = valueForKey(smsUIConfigMap, "smsLogBtnOffsetY");
        Object smsLogBtnWidth = valueForKey(smsUIConfigMap, "smsLogBtnWidth");
        Object smsLogBtnHeight = valueForKey(smsUIConfigMap, "smsLogBtnHeight");
        Object smsLogBtnTextSize = valueForKey(smsUIConfigMap, "smsLogBtnTextSize");
        Object smsLogBtnBottomOffsetY = valueForKey(smsUIConfigMap, "smsLogBtnBottomOffsetY");
        Object smsLogBtnText = valueForKey(smsUIConfigMap, "smsLogBtnText");
        Object smsLogBtnTextColor = valueForKey(smsUIConfigMap, "smsLogBtnTextColor");
        Object isSmsLogBtnTextBold = valueForKey(smsUIConfigMap, "isSmsLogBtnTextBold");
        Object smsLogBtnBackgroundPath = valueForKey(smsUIConfigMap, "smsLogBtnBackgroundPath");
        Object smsFirstSeperLineOffsetX = valueForKey(smsUIConfigMap, "smsFirstSeperLineOffsetX");
        Object smsFirstSeperLineOffsetY = valueForKey(smsUIConfigMap, "smsFirstSeperLineOffsetY");
        Object smsFirstSeperLineOffsetR = valueForKey(smsUIConfigMap, "smsFirstSeperLineOffsetR");
        Object smsFirstSeperLineColor = valueForKey(smsUIConfigMap, "smsFirstSeperLineColor");
        Object smsSecondSeperLineOffsetX = valueForKey(smsUIConfigMap, "smsSecondSeperLineOffsetX");
        Object smsSecondSeperLineOffsetY = valueForKey(smsUIConfigMap, "smsSecondSeperLineOffsetY");
        Object smsSecondSeperLineOffsetR = valueForKey(smsUIConfigMap, "smsSecondSeperLineOffsetR");
        Object smsSecondSeperLineColor = valueForKey(smsUIConfigMap, "smsSecondSeperLineColor");
        Object isSmsPrivacyTextGravityCenter = valueForKey(smsUIConfigMap, "isSmsPrivacyTextGravityCenter");
        Object smsPrivacyOffsetX = valueForKey(smsUIConfigMap, "smsPrivacyOffsetX");
        Object smsPrivacyOffsetY = valueForKey(smsUIConfigMap, "smsPrivacyOffsetY");
        Object smsPrivacyTopOffsetY = valueForKey(smsUIConfigMap, "smsPrivacyTopOffsetY");
        Object smsPrivacyMarginL = valueForKey(smsUIConfigMap, "smsPrivacyMarginL");
        Object smsPrivacyMarginR = valueForKey(smsUIConfigMap, "smsPrivacyMarginR");
        Object smsPrivacyMarginT = valueForKey(smsUIConfigMap, "smsPrivacyMarginT");
        Object smsPrivacyMarginB = valueForKey(smsUIConfigMap, "smsPrivacyMarginB");
        Object smsPrivacyCheckboxSize = valueForKey(smsUIConfigMap, "smsPrivacyCheckboxSize");
        Object isSmsPrivacyCheckboxInCenter = valueForKey(smsUIConfigMap, "isSmsPrivacyCheckboxInCenter");
        Object smsPrivacyCheckboxMargin = valueForKey(smsUIConfigMap, "smsPrivacyCheckboxMargin");
        Object smsPrivacyBeanList = valueForKey(smsUIConfigMap, "smsPrivacyBeanList");
        Object smsPrivacyClauseStart = valueForKey(smsUIConfigMap, "smsPrivacyClauseStart");
        Object smsPrivacyClauseEnd = valueForKey(smsUIConfigMap, "smsPrivacyClauseEnd");
        Object smsPrivacyUncheckedMsg = valueForKey(smsUIConfigMap, "smsPrivacyUncheckedMsg");
        Object smsGetCodeFailMsg = valueForKey(smsUIConfigMap, "smsGetCodeFailMsg");
        Object smsPhoneInvalidMsg = valueForKey(smsUIConfigMap, "smsPhoneInvalidMsg");

        if(smsLogBtnOffsetX !=null){
          builder.setSmsLogBtnOffsetX((Integer) smsLogBtnOffsetX);
        }
        if(smsLogBtnOffsetY !=null){
          builder.setSmsLogBtnOffsetY((Integer) smsLogBtnOffsetY);
        }
        if(smsLogBtnWidth !=null){
          builder.setSmsLogBtnWidth((Integer) smsLogBtnWidth);
        }
        if(smsLogBtnHeight !=null){
          builder.setSmsLogBtnHeight((Integer) smsLogBtnHeight);
        }
        if(smsLogBtnTextSize !=null){
          builder.setSmsLogBtnTextSize((Integer) smsLogBtnTextSize);
        }
        if(smsLogBtnBottomOffsetY !=null){
          builder.setSmsLogBtnBottomOffsetY((Integer) smsLogBtnBottomOffsetY);
        }
        if(smsLogBtnText !=null){
          builder.setSmsLogBtnText((String) smsLogBtnText);
        }
        if(smsLogBtnTextColor !=null){
          builder.setSmsLogBtnTextColor((Integer) smsLogBtnTextColor);
        }
        if(isSmsLogBtnTextBold !=null){
          builder.isSmsLogBtnTextBold((Boolean) isSmsLogBtnTextBold);
        }
        if(smsLogBtnBackgroundPath !=null){
          int res_id_smsLogBtnBackgroundPath = getResourceByReflect((String) smsLogBtnBackgroundPath);
          if (res_id_smsLogBtnBackgroundPath > 0) {
            builder.setSmsLogBtnBackgroundPath((String) smsLogBtnBackgroundPath);
          }
        }
        if(smsFirstSeperLineOffsetX !=null){
          builder.setSmsFirstSeperLineOffsetX((Integer) smsFirstSeperLineOffsetX);
        }
        if(smsFirstSeperLineOffsetY !=null){
          builder.setSmsFirstSeperLineOffsetY((Integer) smsFirstSeperLineOffsetY);
        }
        if(smsFirstSeperLineOffsetR !=null){
          builder.setSmsFirstSeperLineOffsetR((Integer) smsFirstSeperLineOffsetR);
        }
        if(smsFirstSeperLineColor !=null){
          builder.setSmsFirstSeperLineColor((Integer) smsFirstSeperLineColor);
        }
        if(smsSecondSeperLineOffsetX !=null){
          builder.setSmsSecondSeperLineOffsetX((Integer) smsSecondSeperLineOffsetX);
        }
        if(smsSecondSeperLineOffsetY !=null){
          builder.setSmsSecondSeperLineOffsetY((Integer) smsSecondSeperLineOffsetY);
        }
        if(smsSecondSeperLineOffsetR !=null){
          builder.setSmsSecondSeperLineOffsetR((Integer) smsSecondSeperLineOffsetR);
        }
        if(smsSecondSeperLineColor !=null){
          builder.setSmsSecondSeperLineColor((Integer) smsSecondSeperLineColor);
        }
        if(isSmsPrivacyTextGravityCenter !=null){
          builder.isSmsPrivacyTextGravityCenter((Boolean) isSmsPrivacyTextGravityCenter);
        }
        if(smsPrivacyOffsetX !=null){
          builder.setSmsPrivacyOffsetX((Integer) smsPrivacyOffsetX);
        }
        if(smsPrivacyOffsetY !=null){
          builder.setSmsPrivacyOffsetY((Integer) smsPrivacyOffsetY);
        }
        if(smsPrivacyTopOffsetY !=null){
          builder.setSmsPrivacyTopOffsetY((Integer) smsPrivacyTopOffsetY);
        }
        if(smsPrivacyMarginL !=null){
          builder.setSmsPrivacyMarginL((Integer) smsPrivacyMarginL);
        }
        if(smsPrivacyMarginR !=null){
          builder.setSmsPrivacyMarginR((Integer) smsPrivacyMarginR);
        }
        if(smsPrivacyMarginT !=null){
          builder.setSmsPrivacyMarginT((Integer) smsPrivacyMarginT);
        }
        if(smsPrivacyMarginB !=null){
          builder.setSmsPrivacyMarginB((Integer) smsPrivacyMarginB);
        }
        if(smsPrivacyCheckboxSize !=null){
          builder.setSmsPrivacyCheckboxSize((Integer) smsPrivacyCheckboxSize);
        }
        if(isSmsPrivacyCheckboxInCenter !=null){
          builder.isSmsPrivacyCheckboxInCenter((Boolean) isSmsPrivacyCheckboxInCenter);
        }
        if(smsPrivacyCheckboxMargin !=null){
          ArrayList<Integer> smsPrivacyCheckboxMarginArray = (ArrayList) smsPrivacyCheckboxMargin;
          int[] intArray = new int[smsPrivacyCheckboxMarginArray.size()];
          for (int i = 0; i < smsPrivacyCheckboxMarginArray.size(); i++) {
            intArray[i] = smsPrivacyCheckboxMarginArray.get(i);
          }
          builder.setSmsPrivacyCheckboxMargin(intArray);
        }
        if (smsPrivacyBeanList != null) {
          try {
            JSONArray jsonArray = new JSONArray((String) smsPrivacyBeanList);
            int length = jsonArray.length();
            JSONObject jsonObject;
            PrivacyBean privacyBean;
            ArrayList<PrivacyBean> privacyBeans = new ArrayList<>(length);
            for (int i = 0; i < length; i++) {
              jsonObject = jsonArray.optJSONObject(i);
              privacyBean = new PrivacyBean(jsonObject.optString("name"), jsonObject.optString("url"),
                      jsonObject.optString("separator"));

              privacyBeans.add(privacyBean);
            }

            builder.setSmsPrivacyBeanList(privacyBeans);
          } catch (JSONException e) {
            e.printStackTrace();
          }
        }
        if(smsPrivacyClauseStart !=null){
          builder.setSmsPrivacyClauseStart((String) smsPrivacyClauseStart);
        }
        if(smsPrivacyClauseEnd !=null){
          builder.setSmsPrivacyClauseEnd((String) smsPrivacyClauseEnd);
        }
        builder.setSmsGetVerifyCodeDialog(true,Toast.makeText(context,smsPhoneInvalidMsg != null ? (String) smsPhoneInvalidMsg :"请输入正确的手机号",Toast.LENGTH_SHORT));

        builder.setSmsClickActionListener(new SmsClickActionListener() {
          @Override
          public void onClicked(int Code, String msg, Context context, Activity activity, Boolean isUnchecked, List<PrivacyBean> beanArrayList, JVerifyLoginBtClickCallback jVerifyLoginBtClickCallback) {
            Log.d(TAG, msg);
            if (!isUnchecked){
              Toast.makeText(context, smsPrivacyUncheckedMsg != null ? (String) smsPrivacyUncheckedMsg : "请先勾选协议",Toast.LENGTH_SHORT).show();
            }else if(Code ==3005){
              Toast.makeText(context, smsGetCodeFailMsg != null ? (String) smsGetCodeFailMsg : "获取验证码失败",Toast.LENGTH_SHORT).show();
              jVerifyLoginBtClickCallback.login();
            }else {
              jVerifyLoginBtClickCallback.login();
            }

          }
        });
      }
    }

  }

  /** 添加自定义 widget 到 SDK 原有的授权界面里 */

  /**
   * 添加自定义 TextView
   */
  private void addCustomTextWidgets(Map para, JVerifyUIConfig.Builder builder, boolean isDialog) {
    Log.d(TAG, "addCustomTextView " + para);

    TextView customView = new TextView(context);
    ;

    //设置text
    final String title = (String) para.get("title");
    customView.setText(title);

    //设置字体颜色
    Object titleColor = para.get("titleColor");
    if (titleColor != null) {
      if (titleColor instanceof Long) {
        customView.setTextColor(((Long) titleColor).intValue());
      } else {
        customView.setTextColor((Integer) titleColor);
      }
    }

    //设置字体大小
    Object font = para.get("titleFont");
    if (font != null) {
      double titleFont = (double) font;
      if (titleFont > 0) {
        customView.setTextSize((float) titleFont);
      }
    }

    //设置背景颜色
    Object backgroundColor = para.get("backgroundColor");
    if (backgroundColor != null) {
      if (backgroundColor instanceof Long) {
        customView.setBackgroundColor(((Long) backgroundColor).intValue());
      } else {
        customView.setBackgroundColor((Integer) backgroundColor);
      }
    }

    //下划线
    Boolean isShowUnderline = (Boolean) para.get("isShowUnderline");
    if (isShowUnderline) {
      customView.getPaint().setFlags(Paint.UNDERLINE_TEXT_FLAG);//下划线
      customView.getPaint().setAntiAlias(true);//抗锯齿
    }

    //设置对齐方式
    Object alignmet = para.get("textAlignment");
    if (alignmet != null) {
      String textAlignment = (String) alignmet;
      int gravity = getAlignmentFromString(textAlignment);
      customView.setGravity(gravity);
    }

    boolean isSingleLine = (Boolean) para.get("isSingleLine");
    customView.setSingleLine(isSingleLine);//设置是否单行显示，多余的就 ...

    int lines = (int) para.get("lines");
    customView.setLines(lines);//设置行数

    // 位置
    int left = (int) para.get("left");
    int top = (int) para.get("top");
    int width = (int) para.get("width");
    int height = (int) para.get("height");

    RelativeLayout.LayoutParams mLayoutParams1 = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
    mLayoutParams1.leftMargin = dp2Pix(context, (float) left);
    mLayoutParams1.topMargin = dp2Pix(context, (float) top);
    if (width > 0) {
      mLayoutParams1.width = dp2Pix(context, (float) width);
    }
    if (height > 0) {
      mLayoutParams1.height = dp2Pix(context, (float) height);
      ;
    }
    customView.setLayoutParams(mLayoutParams1);

    /// 点击事件 id
    String widgetId = (String) para.get("widgetId");
    final HashMap jsonMap = new HashMap();
    jsonMap.put("widgetId", widgetId);


    if (isDialog) {
      builder.addCustomViewToCheckDialog(customView, new JVerifyUIClickCallback() {
        @Override
        public void onClicked(Context context, View view) {
          Log.d(TAG, "onClicked dialog button widget.");
          runMainThread(jsonMap, null, "onReceiveClickWidgetEvent");
        }
      });
    } else {
      builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
        @Override
        public void onClicked(Context context, View view) {
          Log.d(TAG, "onClicked text widget.");
          channel.invokeMethod("onReceiveClickWidgetEvent", jsonMap);
        }
      });
    }

  }

  /**
   * 添加自定义 button
   */
  private void addCustomButtonWidgets(Map para, JVerifyUIConfig.Builder builder, boolean isDialog) {
    Log.d(TAG, "addCustomButtonWidgets: para = " + para);

    Button customView = new Button(context);

    //设置text
    final String title = (String) para.get("title");
    customView.setText(title);

    //设置字体颜色
    Object titleColor = para.get("titleColor");
    if (titleColor != null) {
      if (titleColor instanceof Long) {
        customView.setTextColor(((Long) titleColor).intValue());
      } else {
        customView.setTextColor((Integer) titleColor);
      }
    }

    //设置字体大小
    Object font = para.get("titleFont");
    if (font != null) {
      double titleFont = (double) font;
      if (titleFont > 0) {
        customView.setTextSize((float) titleFont);
      }
    }


    //设置背景颜色
    Object backgroundColor = para.get("backgroundColor");
    if (backgroundColor != null) {
      if (backgroundColor instanceof Long) {
        customView.setBackgroundColor(((Long) backgroundColor).intValue());
      } else {
        customView.setBackgroundColor((Integer) backgroundColor);
      }
    }

    // 设置背景图（只支持 button 设置）
    String btnNormalImageName = (String) para.get("btnNormalImageName");
    String btnPressedImageName = (String) para.get("btnPressedImageName");
    if (btnNormalImageName != null) {
      if (btnPressedImageName == null) {
        btnPressedImageName = btnNormalImageName;
      }
      setButtonSelector(customView, btnNormalImageName, btnPressedImageName);
    }

    //下划线
    Boolean isShowUnderline = (Boolean) para.get("isShowUnderline");
    if (isShowUnderline) {
      customView.getPaint().setFlags(Paint.UNDERLINE_TEXT_FLAG);//下划线
      customView.getPaint().setAntiAlias(true);//抗锯齿
    }

    //设置对齐方式
    Object alignmet = para.get("textAlignment");
    if (alignmet != null) {
      String textAlignment = (String) alignmet;
      int gravity = getAlignmentFromString(textAlignment);
      customView.setGravity(gravity);
    }

    boolean isSingleLine = (Boolean) para.get("isSingleLine");
    customView.setSingleLine(isSingleLine);//设置是否单行显示，多余的就 ...

    int lines = (int) para.get("lines");
    customView.setLines(lines);//设置行数


    // 位置
    int left = (int) para.get("left");
    int top = (int) para.get("top");
    int width = (int) para.get("width");
    int height = (int) para.get("height");

    RelativeLayout.LayoutParams mLayoutParams1 = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
    mLayoutParams1.leftMargin = dp2Pix(context, (float) left);
    mLayoutParams1.topMargin = dp2Pix(context, (float) top);


    //在内容下方
    Boolean belowTheDialogContent = (Boolean) para.get("belowTheDialogContent");
    if (belowTheDialogContent) {
      mLayoutParams1.addRule(RelativeLayout.BELOW, 2002);
    }

    if (width > 0) {
      mLayoutParams1.width = dp2Pix(context, (float) width);
    }
    if (height > 0) {
      mLayoutParams1.height = dp2Pix(context, (float) height);
      ;
    }
    customView.setLayoutParams(mLayoutParams1);


    /// 点击事件 id
    String widgetId = (String) para.get("widgetId");
    final HashMap jsonMap = new HashMap();
    jsonMap.put("widgetId", widgetId);

    if (isDialog) {
      builder.addCustomViewToCheckDialog(customView, new JVerifyUIClickCallback() {
        @Override
        public void onClicked(Context context, View view) {
          Log.d(TAG, "onClicked dialog button widget.");
          runMainThread(jsonMap, null, "onReceiveClickWidgetEvent");
        }
      });
    } else {
      builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
        @Override
        public void onClicked(Context context, View view) {
          Log.d(TAG, "onClicked button widget.");
          runMainThread(jsonMap, null, "onReceiveClickWidgetEvent");
        }
      });
    }

  }


  /**
   * 获取对齐方式
   */
  private int getAlignmentFromString(String alignmet) {
    int a = 0;
    if (alignmet != null) {
      switch (alignmet) {
        case "left":
          a = Gravity.LEFT;
          break;
        case "top":
          a = Gravity.TOP;
          break;
        case "right":
          a = Gravity.RIGHT;
          break;
        case "bottom":
          a = Gravity.BOTTOM;
          break;
        case "center":
          a = Gravity.CENTER;
          break;
        default:
          a = Gravity.NO_GRAVITY;
          break;
      }
    }
    return a;
  }


  private Object valueForKey(Map para, String key) {
    if (para != null && para.containsKey(key)) {
      return para.get(key);
    } else {
      return null;
    }
  }

  private Object getValueByKey(MethodCall call, String key) {
    if (call != null && call.hasArgument(key)) {
      return call.argument(key);
    } else {
      return null;
    }
  }

  /**
   * 设置 button 背景图片点击效果
   *
   * @param button          按钮
   * @param normalImageName 常态下背景图
   * @param pressImageName  点击时背景图
   */
  private void setButtonSelector(Button button, String normalImageName, String pressImageName) {
    Log.d(TAG, "setButtonSelector normalImageName=" + normalImageName + "，pressImageName=" + pressImageName);

    StateListDrawable drawable = new StateListDrawable();

    Resources res = context.getResources();

    final int normal_resId = getResourceByReflect(normalImageName);
    final int select_resId = getResourceByReflect(pressImageName);

    Bitmap normal_bmp = BitmapFactory.decodeResource(res, normal_resId);
    Drawable normal_drawable = new BitmapDrawable(res, normal_bmp);

    Bitmap select_bmp = BitmapFactory.decodeResource(res, select_resId);
    Drawable select_drawable = new BitmapDrawable(res, select_bmp);

    // 未选中
    drawable.addState(new int[]{-android.R.attr.state_pressed}, normal_drawable);
    //选中
    drawable.addState(new int[]{android.R.attr.state_pressed}, select_drawable);

    button.setBackground(drawable);
  }

  /**
   * 像素转化成 pix
   */
  private int dp2Pix(Context context, float dp) {
    try {
      float density = context.getResources().getDisplayMetrics().density;
      return (int) (dp * density + 0.5F);
    } catch (Exception e) {
      return (int) dp;
    }
  }

  private Integer exchangeObject(Object ob) {
    if (ob instanceof Long) {
      return ((Long) ob).intValue();
    } else {
      return (Integer) ob;
    }
  }

  /**
   * 获取图片名称获取图片的资源id的方法
   *
   * @param imageName 图片名
   * @return resid
   */
  private int getResourceByReflect(String imageName) {

    Class drawable = R.drawable.class;
    Field field = null;
    int r_id = 0;

    if (imageName == null) {
      return r_id;
    }

    try {
      field = drawable.getField(imageName);
      r_id = field.getInt(field.getName());
    } catch (Exception e) {
      r_id = 0;
      //Log.d(TAG, "image【"+imageName + "】field no found!");
    }

    if (r_id == 0) {
      r_id = context.getResources().getIdentifier(imageName, "drawable", context.getPackageName());
      //Log.d(TAG, "image【"+ imageName + "】 drawable found ! r_id = " + r_id);
    }

    if (r_id == 0) {
      r_id = context.getResources().getIdentifier(imageName, "mipmap", context.getPackageName());
      //Log.d(TAG, "image【"+ imageName + "】 mipmap found! r_id = " + r_id);
    }
    if (r_id == 0) {
      Log.d(TAG, "image【" + imageName + "】field no found!");
    }
    return r_id;
  }

}
