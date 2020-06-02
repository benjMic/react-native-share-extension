package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import android.graphics.Bitmap;
import java.io.InputStream;


public class ShareModule extends ReactContextBaseJavaModule {


  public ShareModule(ReactApplicationContext reactContext) {
      super(reactContext);
  }

  @Override
  public String getName() {
      return "ReactNativeShareExtension";
  }

  @ReactMethod
  public void close() {
    getCurrentActivity().finish();
  }

  @ReactMethod
  public void data(Promise promise) {
      promise.resolve(processIntent());
  }

  public WritableMap processIntent() {
      WritableMap map = Arguments.createMap();

      String value = "";
      String type = "";
      String action = "";

      Activity currentActivity = getCurrentActivity();

      if (currentActivity != null) {
        Intent intent = currentActivity.getIntent();
        action = intent.getAction();
        type = intent.getType();
        if (type == null) {
          type = "";
        }
        if (Intent.ACTION_SEND.equals(action) && "text/plain".equals(type)) {
          value = intent.getStringExtra(Intent.EXTRA_TEXT);
        }
        else if (Intent.ACTION_SEND.equals(action) && 
            (   "application/pdf".equals(type)
                || "application/msword".equals(type)
                || "application/vnd.openxmlformats-officedocument.wordprocessingml.document".equals(type)
                || "application/vnd.oasis.opendocument.text".equals(type)
                || "application/vnd.ms-excel".equals(type)
                || "application/excel".equals(type)
                || "application/xlsx".equals(type)
                || "application/x-msexcel".equals(type)
                || "application/x-excel".equals(type)
                || "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".equals(type)
                || "application/vnd.ms-excel.sheet.macroEnabled.12".equals(type)
                || "application/vnd.ms-excel.sheet.macroenabled.12".equals(type)
                || "application/vnd.ms-excel.template.macroenabled.12".equals(type)
                || "application/vnd.openxmlformats-officedocument.spreadsheetml.template".equals(type)
                || "application/vnd.ms-excel.template.macroEnabled.12".equals(type)
                || "application/xml".equals(type)
                || "text/xml".equals(type)
                || "application/vnd.ms-excel.sheet.binary.macroEnabled.12".equals(type)
                || "application/vnd.ms-excel.addin.macroEnabled.12".equals(type)
                || "application/vnd.ms-powerpoint".equals(type)
                || "application/vnd.openxmlformats-officedocument.presentationml.presentation".equals(type)
                || "image/jpeg".equals(type)
                || "image/png".equals(type)
                || "application/zip".equals(type)
                || "application/x-compressed".equals(type)
                || "application/x-zip-compressed".equals(type)
                || "image/tiff".equals(type)
                || "image/x-tiff".equals(type)
                || "text/plain".equals(type)
                || "application/vnd.ms-outlook".equals(type)
                || "application/octet-stream".equals(type)
                || "application/vnd.ms-office".equals(type)
                || "application/rtf".equals(type)
                || "text/html".equals(type)
                || "text/rtf".equals(type)
                || "text/csv".equals(type)
         ) ) {
          Uri uri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
         value = "file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri);

       } else {
         value = "";
       }
      } else {
        value = "";
        type = "";
      }

      map.putString("type", type);
      map.putString("value",value);

      return map;
  }
}
