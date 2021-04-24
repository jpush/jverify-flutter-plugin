package com.jiguang.jverify;

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
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import cn.jiguang.verifysdk.api.AuthPageEventListener;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyUIClickCallback;
import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.LoginSettings;
import cn.jiguang.verifysdk.api.PreLoginListener;
import cn.jiguang.verifysdk.api.RequestCallback;
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
        } else if (call.method.equals("isInitSuccess")) {
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
            public void onResult(int code, String content, String operator) {

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
            public void onResult(int code, String message) {

                if (code == 7000) {//code: 返回码，7000代表获取成功，其他为失败，详见错误码描述
                    Log.d(TAG, "verify success, message =" + message);
                } else {
                    Log.e(TAG, "verify fail，code=" + code + ", message =" + message);
                }
                Map<String, Object> map = new HashMap<>();
                map.put(j_code_key, code);
                map.put(j_msg_key, message);

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

        LoginSettings settings = new LoginSettings();
        settings.setAutoFinish((Boolean) autoFinish);
        settings.setTimeout(timeOut);
        settings.setAuthPageEventListener(new AuthPageEventListener() {
            @Override
            public void onEvent(int cmd, String msg) {
                Log.d(TAG, "Action - AuthPageEventListener: cmd = " + cmd);
                /// 事件
                final HashMap jsonMap = new HashMap();
                jsonMap.put(j_code_key, cmd);
                jsonMap.put(j_msg_key, msg);

                runMainThread(jsonMap, null, "onReceiveAuthPageEvent");
            }
        });

        JVerificationInterface.loginAuth(context, settings, new VerifyListener() {
            @Override
            public void onResult(int code, String content, String operator) {
                if (code == 6000) {
                    Log.d(TAG, "code=" + code + ", token=" + content + " ,operator=" + operator);
                } else {
                    Log.d(TAG, "code=" + code + ", message=" + content);
                }
                Map<String, Object> map = new HashMap<>();
                map.put(j_code_key, code);
                map.put(j_msg_key, content);
                map.put(j_opr_key, operator);
                if (isSync) {
                    // 通过 channel 返回
                    runMainThread(map, null, "onReceiveLoginAuthCallBackEvent");
                } else {
                    // 通过回调返回
                    runMainThread(map, result, null);
                }
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
                    addCustomTextWidgets(widgetMap, builder);
                } else if (type.equals("button")) {
                    addCustomButtonWidgets(widgetMap, builder);
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
                    addCustomTextWidgets(widgetMap, portraitBuilder);
                    if (isAutorotate) {
                        addCustomTextWidgets(widgetMap, landscapeBuilder);
                    }
                } else if (type.equals("button")) {
                    addCustomButtonWidgets(widgetMap, portraitBuilder);
                    if (isAutorotate) {
                        addCustomButtonWidgets(widgetMap, landscapeBuilder);
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

        Object navColor = valueForKey(uiconfig, "navColor");
        Object navText = valueForKey(uiconfig, "navText");
        Object navTextColor = valueForKey(uiconfig, "navTextColor");
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

        Object numberColor = valueForKey(uiconfig, "numberColor");
        Object numberSize = valueForKey(uiconfig, "numberSize");
        Object numFieldOffsetY = valueForKey(uiconfig, "numFieldOffsetY");
        Object numFieldOffsetX = valueForKey(uiconfig, "numFieldOffsetX");
        Object numberFieldWidth = valueForKey(uiconfig, "numberFieldWidth");
        Object numberFieldHeight = valueForKey(uiconfig, "numberFieldHeight");


        Object logBtnText = valueForKey(uiconfig, "logBtnText");
        Object logBtnOffsetY = valueForKey(uiconfig, "logBtnOffsetY");
        Object logBtnOffsetX = valueForKey(uiconfig, "logBtnOffsetX");
        Object logBtnWidth = valueForKey(uiconfig, "logBtnWidth");
        Object logBtnHeight = valueForKey(uiconfig, "logBtnHeight");
        Object logBtnTextSize = valueForKey(uiconfig, "logBtnTextSize");
        Object logBtnTextColor = valueForKey(uiconfig, "logBtnTextColor");
        Object logBtnBackgroundPath = valueForKey(uiconfig, "logBtnBackgroundPath");

        Object uncheckedImgPath = valueForKey(uiconfig, "uncheckedImgPath");
        Object checkedImgPath = valueForKey(uiconfig, "checkedImgPath");

        Object privacyTopOffsetY = valueForKey(uiconfig, "privacyTopOffsetY");
        Object privacyOffsetY = valueForKey(uiconfig, "privacyOffsetY");
        Object privacyOffsetX = valueForKey(uiconfig, "privacyOffsetX");
        Object CLAUSE_NAME = valueForKey(uiconfig, "clauseName");
        Object CLAUSE_URL = valueForKey(uiconfig, "clauseUrl");
        Object CLAUSE_BASE_COLOR = valueForKey(uiconfig, "clauseBaseColor");
        Object CLAUSE_COLOR = valueForKey(uiconfig, "clauseColor");
        Object CLAUSE_NAME_TWO = valueForKey(uiconfig, "clauseNameTwo");
        Object CLAUSE_URL_TWO = valueForKey(uiconfig, "clauseUrlTwo");
        Object privacyTextCenterGravity = valueForKey(uiconfig, "privacyTextCenterGravity");
        Object privacyText = valueForKey(uiconfig, "privacyText");
        Object privacyTextSize = valueForKey(uiconfig, "privacyTextSize");
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

        Object privacyNavColor = valueForKey(uiconfig, "privacyNavColor");
        Object privacyNavTitleTextColor = valueForKey(uiconfig, "privacyNavTitleTextColor");
        Object privacyNavTitleTextSize = valueForKey(uiconfig, "privacyNavTitleTextSize");
        Object privacyNavReturnBtnImage = valueForKey(uiconfig, "privacyNavReturnBtnImage");
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

        /************** number ***************/
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


        /************** slogan ***************/
        if (sloganOffsetY != null) {
            builder.setSloganOffsetY((Integer) sloganOffsetY);
        }
        if (sloganOffsetX != null) {
            builder.setSloganOffsetX((Integer) sloganOffsetX);
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


        /************** login btn ***************/
        if (logBtnOffsetY != null) {
            builder.setLogBtnOffsetY((Integer) logBtnOffsetY);
        }
        if (logBtnOffsetX != null) {
            builder.setLogBtnOffsetX((Integer) logBtnOffsetX);
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
            builder.setPrivacyText(privacyTextList.get(0), privacyTextList.get(1), privacyTextList.get(2), privacyTextList.get(3));
        }

        builder.setPrivacyTextCenterGravity((Boolean) privacyTextCenterGravity);
        builder.setPrivacyWithBookTitleMark((Boolean) privacyWithBookTitleMark);
        builder.setPrivacyCheckboxInCenter((Boolean) privacyCheckboxInCenter);
        builder.setPrivacyState((Boolean) privacyState);

        if (CLAUSE_NAME != null && CLAUSE_URL != null) {
            builder.setAppPrivacyOne((String) CLAUSE_NAME, (String) CLAUSE_URL);
        }
        int baseColor = -10066330;
        ;
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
        if (CLAUSE_NAME_TWO != null && CLAUSE_URL_TWO != null) {
            builder.setAppPrivacyTwo((String) CLAUSE_NAME_TWO, (String) CLAUSE_URL_TWO);
        }

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
        if (privacyNavTitleTitle1 != null) {
            builder.setAppPrivacyNavTitle1((String) privacyNavTitleTitle1);
        }
        if (privacyNavTitleTitle2 != null) {
            builder.setAppPrivacyNavTitle2((String) privacyNavTitleTitle2);
        }

        if (privacyNavReturnBtnImage != null) {
            int res_id = getResourceByReflect((String) privacyNavReturnBtnImage);
            if (res_id > 0) {
                ImageView view = new ImageView(context);
                view.setImageResource(res_id);
                builder.setPrivacyNavReturnBtn(view);
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
    }

    /** 添加自定义 widget 到 SDK 原有的授权界面里 */

    /**
     * 添加自定义 TextView
     */
    private void addCustomTextWidgets(Map para, JVerifyUIConfig.Builder builder) {
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

        builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
            @Override
            public void onClicked(Context context, View view) {
                Log.d(TAG, "onClicked text widget.");
                channel.invokeMethod("onReceiveClickWidgetEvent", jsonMap);
            }
        });
    }

    /**
     * 添加自定义 button
     */
    private void addCustomButtonWidgets(Map para, JVerifyUIConfig.Builder builder) {
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
        if (btnPressedImageName == null) {
            btnPressedImageName = btnNormalImageName;
        }
        setButtonSelector(customView, btnNormalImageName, btnPressedImageName);

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

        builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
            @Override
            public void onClicked(Context context, View view) {
                Log.d(TAG, "onClicked button widget.");
                runMainThread(jsonMap, null, "onReceiveClickWidgetEvent");
            }
        });
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
