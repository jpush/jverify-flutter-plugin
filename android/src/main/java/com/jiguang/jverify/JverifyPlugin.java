package com.jiguang.jverify;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Paint;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.StateListDrawable;
import android.media.Image;
import android.nfc.Tag;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.view.View;
import android.widget.TextView;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import cn.jiguang.api.JCoreInterface;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyUIClickCallback;
import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.PreLoginListener;
import cn.jiguang.verifysdk.api.VerifyListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** JverifyPlugin */
public class JverifyPlugin implements MethodCallHandler {

  // 定义日志 TAG
  private  static  final String TAG = "| JVER | Android | -";


  /// 统一 key
  private static  String j_result_key = "result";
  /// 错误码
  private static  String  j_code_key = "code";
  /// 回调的提示信息，统一返回 flutter 为 message
  private static  String  j_msg_key  = "message";
  /// 运营商信息
  private static  String  j_opr_key  = "operator";
  // 默认超时时间
  private  static  int j_default_timeout = 5000;


  private Context context;
  private MethodChannel channel;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "jverify");
    channel.setMethodCallHandler(new JverifyPlugin(registrar,channel));
  }

  private JverifyPlugin(Registrar registrar,MethodChannel channel){
    this.context = registrar.context();
    this.channel = channel;
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d(TAG,"onMethodCall:" + call.method);

    if (call.method.equals("setup")) {
      setup(call,result);
    }else if (call.method.equals("setDebugMode")) {
      setDebugMode(call, result);
    }else if (call.method.equals("isInitSuccess")) {
      isInitSuccess(call, result);
    }else if (call.method.equals("checkVerifyEnable")) {
      checkVerifyEnable(call,result);
    }else if (call.method.equals("getToken")) {
      getToken(call,result);
    }else if (call.method.equals("verifyNumber")) {
      verifyNumber(call,result);
    }else if (call.method.equals("loginAuth")) {
      loginAuth(call, result);
    }else  if (call.method.equals("preLogin")) {
      preLogin(call, result);
    }else if (call.method.equals("dismissLoginAuthView")) {
      dismissLoginAuthView(call, result);
    }else if (call.method.equals("setCustomUI")) {
//      setCustomUI(call,result);
    }else if (call.method.equals("setCustomAuthViewAllWidgets")) {
      setCustomAuthViewAllWidgets(call,result);
    }else {
      result.notImplemented();
    }
  }

  /** SDK 初始换  */
  private void setup(MethodCall call,Result result){
    Log.d(TAG,"Action - setup:");
    JVerificationInterface.init(context);
  }

  /** SDK设置debug模式 */
  private void setDebugMode(MethodCall call,Result result){
    Log.d(TAG,"Action - setDebugMode:");
    Object enable =  getValueByKey(call,"debug");
    if (enable != null){
      JVerificationInterface.setDebugMode((Boolean) enable);
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key,enable);
    result.success(map);
  }

  /** 获取 SDK 初始化是否成功标识 */
  private  boolean isInitSuccess(MethodCall call, Result result) {
    Log.d(TAG,"Action - isInitSuccess:");
    boolean isSuccess = JVerificationInterface.isInitSuccess();
    if (!isSuccess) {
      Log.d( TAG, "SDK 初始化失败: ");
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key, isSuccess);
    result.success(map);

    return isSuccess;
  }


  /** SDK 判断网络环境是否支持 */
  private boolean checkVerifyEnable(MethodCall call,Result result){
    Log.d(TAG,"Action - checkVerifyEnable:");
    boolean verifyEnable = JVerificationInterface.checkVerifyEnable(context);
    if (!verifyEnable) {
      Log.d( TAG, "当前网络环境不支持");
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key, verifyEnable);
    result.success(map);

    return verifyEnable;
  }

  /** SDK获取号码认证token*/
  private void getToken(MethodCall call, final Result result) {
    Log.d(TAG,"Action - getToken:");

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      String timeOutString = call.argument("timeOut");

      try {
        timeOut = Integer.valueOf(timeOutString);
      } catch (Exception e) {
        Log.e(TAG,"timeOut type error.");
      }
    }


    JVerificationInterface.getToken(context, timeOut, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        if (code == 2000){//code: 返回码，2000代表获取成功，其他为失败
          Log.d(TAG, "token=" + content + ", operator=" + operator);
        } else {
          Log.e(TAG, "code=" + code + ", message=" + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);
      }
    });
  }

  /** SDK 发起号码认证 */
  private void verifyNumber(MethodCall call, final Result result) {
    Log.d(TAG,"Action - verifyNumber:");

    String token = null;
    if (call.hasArgument("token")){
      token = call.argument("token");
    }
    String phone = null;
    if (call.hasArgument("phone")){
      phone = call.argument("phone");
    }
    if (phone == null || phone.isEmpty() || phone.length() == 0) {
      Log.e(TAG,"phone can not be nil.");
      return;
    }
    JVerificationInterface.verifyNumber(context, token, phone, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        if (code == 1000){//code: 返回码，1000代表验证一致，1001代表验证不一致，其他为失败，详见错误码描述
          Log.d(TAG, "verify consistent, operator=" + operator);
        } else if (code == 1001) {
          Log.d(TAG, "verify not consistent");
        } else {
          Log.e(TAG, "code=" + code + ", message=" + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);
      }
    });
  }

  /** SDK 一键登录预取号 */
  private  void  preLogin(MethodCall call,final Result result) {
    Log.d(TAG,"Action - preLogin:" + call.arguments);

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      Integer value = call.argument("timeOut");
      timeOut = value;
    }

    JVerificationInterface.preLogin(context, timeOut, new PreLoginListener() {
      @Override
      public void onResult(int code, String message) {

        if (code == 7000){//code: 返回码，7000代表获取成功，其他为失败，详见错误码描述
          Log.d(TAG, "verify consistent, message =" + message);
        }else {
          Log.e(TAG, "code=" + code + ", message =" + message);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,message);
        result.success(map);
      }
    });
  }


  /** SDK请求授权一键登录 */
  private void loginAuth(MethodCall call,final Result result){
    Log.d(TAG,"Action - loginAuth:");

    Object autoFinish =  getValueByKey(call,"autoDismiss");

    JVerificationInterface.loginAuth(context, (Boolean)autoFinish, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        //code: 返回码，6000代表loginToken获取成功，6001代表loginToken获取失败
        if (code == 6000){
          Log.d(TAG, "code = " + code + ", token = " + content +" ,operator = " + operator);
        }else{
          Log.e(TAG, "code = " + code + ", message = " + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);

      }
    });
  }
  /** SDK关闭授权页面 */
  private  void dismissLoginAuthView(MethodCall call, Result result) {
    Log.d(TAG,"Action - dismissLoginAuthView:");

    JVerificationInterface.dismissLoginAuthActivity();
  }

  /** 自定义授权界面 UI 、添加自定义控件*/
  private void  setCustomAuthViewAllWidgets(MethodCall call, Result result) {
    Log.d(TAG,"setCustomAuthViewAllWidgets:");

    Map uiconfig = call.argument("uiconfig");
    List<Map> widgetList = call.argument("widgets");


    JVerifyUIConfig.Builder builder =  new JVerifyUIConfig.Builder();

    /// 布局 SDK 授权界面原有 UI
    layoutOriginOuthView(uiconfig, builder);

    for (Map widgetMap : widgetList) {

      /// 新增自定义的控件
      String type = (String) widgetMap.get("type");
      if (type.equals("textView")) {
        addCustomTextWidgets(widgetMap, builder);
      }else if (type.equals("button")) {
        addCustomButtonWidgets(widgetMap, builder);
      }else {
        Log.e(TAG,"don't support widget");
        return;
      }
    }

    JVerificationInterface.setCustomUIWithConfig(builder.build());
  }

  /** 自定义 SDK 原有的授权界面里的 UI */
  private  void layoutOriginOuthView(Map uiconfig, JVerifyUIConfig.Builder builder) {
    Log.d(TAG,"layoutOriginOuthView:");

    Object navColor = valueForKey(uiconfig,"navColor");
    Object navText = valueForKey(uiconfig,"navText");
    Object navTextColor = valueForKey(uiconfig,"navTextColor");
    Object navReturnImgPath = valueForKey(uiconfig,"navReturnImgPath");
    Object logoImgPath = valueForKey(uiconfig,"logoImgPath");
    Object logoWidth = valueForKey(uiconfig,"logoWidth");
    Object logoHeight = valueForKey(uiconfig,"logoHeight");
    Object logoOffsetY = valueForKey(uiconfig,"logoOffsetY");
    Object logoHidden = valueForKey(uiconfig,"logoHidden");
    Object numberColor = valueForKey(uiconfig,"numberColor");
    Object numFieldOffsetY = valueForKey(uiconfig,"numFieldOffsetY");
    Object logBtnText = valueForKey(uiconfig,"logBtnText");
    Object logBtnOffsetY = valueForKey(uiconfig,"logBtnOffsetY");
    Object logBtnTextColor = valueForKey(uiconfig,"logBtnTextColor");
    Object logBtnBackgroundPath = valueForKey(uiconfig,"logBtnBackgroundPath");
    Object uncheckedImgPath = valueForKey(uiconfig,"uncheckedImgPath");
    Object checkedImgPath = valueForKey(uiconfig,"checkedImgPath");
    Object privacyOffsetY = valueForKey(uiconfig,"privacyOffsetY");
    Object CLAUSE_NAME = valueForKey(uiconfig,"clauseName");
    Object CLAUSE_URL = valueForKey(uiconfig,"clauseUrl");
    Object CLAUSE_BASE_COLOR = valueForKey(uiconfig,"clauseBaseColor");
    Object CLAUSE_COLOR = valueForKey(uiconfig,"clauseColor");
    Object CLAUSE_NAME_TWO = valueForKey(uiconfig,"clauseNameTwo");
    Object CLAUSE_URL_TWO = valueForKey(uiconfig,"clauseUrlTwo");
    Object sloganOffsetY = valueForKey(uiconfig,"sloganOffsetY");
    Object sloganTextColor = valueForKey(uiconfig,"sloganTextColor");
    Object privacyState = valueForKey(uiconfig,"privacyState");


    if (navColor != null){
      if (navColor instanceof Long){
        builder.setNavColor(((Long) navColor).intValue());
      }else {
        builder.setNavColor((Integer) navColor);
      }

    }
    if (navText != null){
      builder.setNavText((String) navText);
    }
    if (navTextColor != null){
      if (navTextColor instanceof Long){
        builder.setNavTextColor(((Long) navTextColor).intValue());
      }else {
        builder.setNavTextColor((Integer) navTextColor);
      }
    }
    if (navReturnImgPath != null){
      builder.setNavReturnImgPath((String) navReturnImgPath);
    }
    if (logoImgPath != null ){
      builder.setLogoImgPath((String)logoImgPath);
    }
    if (logoWidth != null){
      if (logoWidth instanceof Long){
        builder.setLogoWidth(((Long) logoWidth).intValue());
      }else {
        builder.setLogoWidth((Integer) logoWidth);
      }
    }
    if (logoHeight != null){
      if (logoHeight instanceof Long){
        builder.setLogoHeight(((Long) logoHeight).intValue());
      }else {
        builder.setLogoHeight((Integer) logoHeight);
      }
    }
    if (logoOffsetY != null){
      if (logoOffsetY instanceof Long){
        builder.setLogoOffsetY(((Long) logoOffsetY).intValue());
      }else {
        builder.setLogoOffsetY((Integer) logoOffsetY);
      }
    }
    if (logoHidden != null){
      builder.setLogoHidden((Boolean)logoHidden);
    }
    if (numberColor != null){
      if (numberColor instanceof Long){
        builder.setNumberColor(((Long) numberColor).intValue());
      }else {
        builder.setNumberColor((Integer) numberColor);
      }
    }
    if (numFieldOffsetY != null){
      if (numFieldOffsetY instanceof Long){
        builder.setNumFieldOffsetY(((Long) numFieldOffsetY).intValue());
      }else {
        builder.setNumFieldOffsetY((Integer) numFieldOffsetY);
      }
    }
    if (logBtnText != null){
      builder.setLogBtnText((String) logBtnText);
    }
    if (logBtnOffsetY != null){
      if (logBtnOffsetY instanceof Long){
        builder.setLogBtnOffsetY(((Long) logBtnOffsetY).intValue());
      }else {
        builder.setLogBtnOffsetY((Integer) logBtnOffsetY);
      }
    }
    if (logBtnTextColor != null){
      if (logBtnTextColor instanceof Long){
        builder.setLogBtnTextColor(((Long) logBtnTextColor).intValue());
      }else {
        builder.setLogBtnTextColor((Integer) logBtnTextColor);
      }
    }
    if (logBtnBackgroundPath != null){
      builder.setLogBtnImgPath((String) logBtnBackgroundPath);
    }
    if (uncheckedImgPath != null){
      builder.setUncheckedImgPath((String) uncheckedImgPath);
    }
    if (checkedImgPath != null){
      builder.setCheckedImgPath((String) checkedImgPath);
    }
    if (privacyOffsetY != null){
      if (privacyOffsetY instanceof Long){
        builder.setPrivacyOffsetY(((Long) privacyOffsetY).intValue());
      }else {
        builder.setPrivacyOffsetY((Integer) privacyOffsetY);
      }
    }
    if (CLAUSE_NAME != null && CLAUSE_URL != null){
      builder.setAppPrivacyOne( (String) CLAUSE_NAME, (String) CLAUSE_URL);
    }
    int baseColor = -10066330;;
    int color = -16007674;
    if (CLAUSE_BASE_COLOR != null ){
      if (CLAUSE_BASE_COLOR instanceof Long){
        baseColor = ((Long) CLAUSE_BASE_COLOR).intValue();
      }else {
        baseColor = (Integer) CLAUSE_BASE_COLOR;
      }
    }
    if (CLAUSE_COLOR!= null){
      if (CLAUSE_COLOR instanceof Long){
        color = ((Long) CLAUSE_COLOR).intValue();
      }else {
        color = (Integer) CLAUSE_COLOR;
      }
    }
    builder.setAppPrivacyColor(baseColor,color);
    if (CLAUSE_NAME_TWO != null && CLAUSE_URL_TWO != null){
      builder.setAppPrivacyTwo( (String) CLAUSE_NAME_TWO, (String) CLAUSE_URL_TWO);
    }

    if (sloganOffsetY!= null){
      if (sloganOffsetY instanceof Long){
        builder.setSloganOffsetY(((Long) sloganOffsetY).intValue());
      }else {
        builder.setSloganOffsetY((Integer) sloganOffsetY);
      }
    }
    if (sloganTextColor != null){
      if (sloganTextColor instanceof Long){
        builder.setSloganTextColor(((Long) sloganTextColor).intValue());
      }else {
        builder.setSloganTextColor((Integer) sloganTextColor);
      }
    }

    boolean isPrivacyState = (Boolean) privacyState;
    builder.setPrivacyState(isPrivacyState);
  }

  /** 添加自定义 widget 到 SDK 原有的授权界面里 */

  /** 添加自定义 TextView、Button 控件到 SDK 原有的授权界面里*/
  private  void addCustomTextWidgets(Map para, JVerifyUIConfig.Builder builder) {
    Log.d(TAG,"addCustomTextView " + para);

    TextView customView = new TextView(context);;

    //设置text
    final String title = (String) para.get("title");
    customView.setText(title);

    //设置字体颜色
    Object titleColor = para.get("titleColor");
    if (titleColor != null){
      if (titleColor instanceof Long){
        customView.setTextColor(((Long) titleColor).intValue());
      }else {
        customView.setTextColor((Integer) titleColor);
      }
    }

    //设置字体大小
    Object font = para.get("titleFont");
    if (font != null) {
      double titleFont = (double)font;
      if (titleFont > 0){
        customView.setTextSize((float)titleFont);
      }
    }

    //设置背景颜色
    Object backgroundColor = para.get("backgroundColor");
    if (backgroundColor != null){
      if (backgroundColor instanceof Long){
        customView.setBackgroundColor(((Long) backgroundColor).intValue());
      }else {
        customView.setBackgroundColor((Integer) backgroundColor);
      }
    }

    //下划线
    Boolean isShowUnderline = (Boolean)para.get("isShowUnderline");
    if (isShowUnderline) {
      customView.getPaint().setFlags(Paint.UNDERLINE_TEXT_FLAG);//下划线
      customView.getPaint().setAntiAlias(true);//抗锯齿
    }

    //设置对齐方式
    Object alignmet = para.get("textAlignment");
    if (alignmet != null) {
      String textAlignment = (String)alignmet;
      int gravity = getAlignmentFromString(textAlignment);
      customView.setGravity(gravity);
    }

    boolean isSingleLine = (Boolean)para.get("isSingleLine");
    customView.setSingleLine(isSingleLine);//设置是否单行显示，多余的就 ...

    int lines = (int)para.get("lines");
    customView.setLines(lines);//设置行数

    // 位置
    int left = (int)para.get("left");
    int top = (int)para.get("top");
    int width = (int)para.get("width");
    int height = (int)para.get("height");

    RelativeLayout.LayoutParams mLayoutParams1 = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT,RelativeLayout.LayoutParams.WRAP_CONTENT);
    mLayoutParams1.leftMargin = dp2Pix(context, (float)left);
    mLayoutParams1.topMargin = dp2Pix(context, (float)top);
    if (width > 0) {
      mLayoutParams1.width = dp2Pix(context,(float)width);
    }
    if (height > 0) {
      mLayoutParams1.height = dp2Pix(context,(float)height);;
    }
    customView.setLayoutParams(mLayoutParams1);

    /// 点击事件 id
    String widgetId = (String) para.get("widgetId");
    final HashMap jsonMap = new HashMap();
    jsonMap.put("widgetId", widgetId);

    builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
      @Override
      public void onClicked(Context context, View view) {
        Log.d(TAG,"onClicked text widget.");
        channel.invokeMethod("onReceiveClickWidgetEvent", jsonMap);
      }
    });
  }

  private  void addCustomButtonWidgets(Map para, JVerifyUIConfig.Builder builder) {
    Log.d(TAG,"addCustomButtonWidgets: para = " + para);

    Button customView = new Button(context);

    //设置text
    final String title = (String) para.get("title");
    customView.setText(title);

    //设置字体颜色
    Object titleColor = para.get("titleColor");
    if (titleColor != null){
      if (titleColor instanceof Long){
        customView.setTextColor(((Long) titleColor).intValue());
      }else {
        customView.setTextColor((Integer) titleColor);
      }
    }

    //设置字体大小
    Object font = para.get("titleFont");
    if (font != null) {
      double titleFont = (double)font;
      if (titleFont > 0){
        customView.setTextSize((float)titleFont);
      }
    }


    //设置背景颜色
    Object backgroundColor = para.get("backgroundColor");
    if (backgroundColor != null){
      if (backgroundColor instanceof Long){
        customView.setBackgroundColor(((Long) backgroundColor).intValue());
      }else {
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
    Boolean isShowUnderline = (Boolean)para.get("isShowUnderline");
    if (isShowUnderline) {
      customView.getPaint().setFlags(Paint.UNDERLINE_TEXT_FLAG);//下划线
      customView.getPaint().setAntiAlias(true);//抗锯齿
    }

    //设置对齐方式
    Object alignmet = para.get("textAlignment");
    if (alignmet != null) {
      String textAlignment = (String)alignmet;
      int gravity = getAlignmentFromString(textAlignment);
      customView.setGravity(gravity);
    }

    boolean isSingleLine = (Boolean)para.get("isSingleLine");
    customView.setSingleLine(isSingleLine);//设置是否单行显示，多余的就 ...

    int lines = (int)para.get("lines");
    customView.setLines(lines);//设置行数


    // 位置
    int left = (int)para.get("left");
    int top = (int)para.get("top");
    int width = (int)para.get("width");
    int height = (int)para.get("height");

    RelativeLayout.LayoutParams mLayoutParams1 = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT,RelativeLayout.LayoutParams.WRAP_CONTENT);
    mLayoutParams1.leftMargin = dp2Pix(context, (float)left);
    mLayoutParams1.topMargin = dp2Pix(context, (float)top);
    if (width > 0) {
      mLayoutParams1.width = dp2Pix(context,(float)width);
    }
    if (height > 0) {
      mLayoutParams1.height = dp2Pix(context,(float)height);;
    }
    customView.setLayoutParams(mLayoutParams1);


    /// 点击事件 id
    String widgetId = (String) para.get("widgetId");
    final HashMap jsonMap = new HashMap();
    jsonMap.put("widgetId", widgetId);

    builder.addCustomView(customView, false, new JVerifyUIClickCallback() {
      @Override
      public void onClicked(Context context, View view) {
        Log.d(TAG,"onClicked button widget.");
        channel.invokeMethod("onReceiveClickWidgetEvent", jsonMap);
      }
    });
  }


  /** 获取对齐方式*/
  private int getAlignmentFromString(String alignmet) {
    int a = 0;
    if (alignmet != null) {
      switch (alignmet){
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


  private Object valueForKey(Map para,String key){
    if (para != null && para.containsKey(key)){
      return  para.get(key);
    }else {
      return null;
    }
  }

  private Object getValueByKey(MethodCall call,String key){
    if (call != null && call.hasArgument(key)){
      return  call.argument(key);
    }else {
      return null;
    }
  }

  /**
   * 设置 button 背景图片点击效果
   *
   * @param button 按钮
   * @param normalImageName 常态下背景图
   * @param pressImageName 点击时背景图
   */
  private void setButtonSelector(Button button,String normalImageName,String pressImageName) {
    Log.d(TAG,"setButtonSelector normalImageName=" + normalImageName + "，pressImageName="+ pressImageName);

    StateListDrawable drawable = new StateListDrawable();

    Resources res = context.getResources();

    final int normal_resId = getResourceByReflect(normalImageName);
    final int select_resId = getResourceByReflect(pressImageName);

    Bitmap normal_bmp = BitmapFactory.decodeResource(res, normal_resId);
    Drawable normal_drawable = new BitmapDrawable(res, normal_bmp);

    Bitmap select_bmp = BitmapFactory.decodeResource(res, select_resId);
    Drawable select_drawable = new BitmapDrawable(res, select_bmp);

    // 未选中
    drawable.addState(new int[]{-android.R.attr.state_pressed},normal_drawable);
    //选中
    drawable.addState(new int[]{android.R.attr.state_pressed},select_drawable);

    button.setBackground(drawable);
  }

  /** 像素转化成 pix*/
  private int dp2Pix(Context context, float dp) {
    try {
      float density = context.getResources().getDisplayMetrics().density;
      return (int)(dp * density + 0.5F);
    } catch (Exception e) {
      return (int)dp;
    }
  }

  /**
   * 获取图片名称获取图片的资源id的方法
   * @param imageName 图片名
   * @return resid
   */
  private int getResourceByReflect(String imageName){

    Class drawable  =  R.drawable.class;
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
      Log.e(TAG, "image【"+imageName + "】field no found!");
    }

    if (r_id == 0) {
      r_id = context.getResources().getIdentifier(imageName, "drawable",context.getPackageName());
      Log.d(TAG, "image【"+ imageName + "】 drawable found ! r_id = " + r_id);
    }

    if (r_id == 0) {
      r_id = context.getResources().getIdentifier(imageName, "mipmap",context.getPackageName());
      Log.d(TAG, "image【"+ imageName + "】 mipmap found! r_id = " + r_id);
    }

    return r_id;
  }
}
