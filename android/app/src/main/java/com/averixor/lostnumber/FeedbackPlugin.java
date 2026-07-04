package com.averixor.lostnumber;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "Feedback")
public class FeedbackPlugin extends Plugin {
    private static final String TAG = "LostNumberFeedback";
    private static final String ANALYTICS_EVENT = "feedback_button_click";

    @PluginMethod
    public void openEmail(PluginCall call) {
        Log.i(TAG, ANALYTICS_EVENT);
        String email = call.getString("email", "rsabergman@gmail.com");
        String subject = call.getString("subject", "Відгук про застосунок");
        String body = call.getString("body", "");
        String chooserTitle = call.getString("chooserTitle", "Оберіть поштовий клієнт");
        String errorMessage = call.getString("errorMessage", "Будь ласка, встановіть поштовий клієнт");

        if (body == null || body.trim().isEmpty()) {
            String versionName = "";
            try {
                versionName =
                    getContext()
                        .getPackageManager()
                        .getPackageInfo(getContext().getPackageName(), 0)
                        .versionName;
            } catch (PackageManager.NameNotFoundException ignored) {}

            body =
                "Опишіть тут ваш відгук або проблему:\n\n"
                    + "-------------------------------------\n"
                    + "Пристрій: "
                    + Build.MANUFACTURER
                    + " "
                    + Build.MODEL
                    + "\n"
                    + "Версія Android: "
                    + Build.VERSION.RELEASE
                    + "\n"
                    + "Версія застосунку: "
                    + versionName;
        }

        Intent emailIntent = new Intent(Intent.ACTION_SENDTO);
        emailIntent.setData(Uri.parse("mailto:" + email));
        emailIntent.putExtra(Intent.EXTRA_SUBJECT, subject);
        emailIntent.putExtra(Intent.EXTRA_TEXT, body);

        try {
            getActivity().startActivity(Intent.createChooser(emailIntent, chooserTitle));
            JSObject result = new JSObject();
            result.put("opened", true);
            call.resolve(result);
        } catch (ActivityNotFoundException e) {
            call.reject(errorMessage);
        }
    }
}
