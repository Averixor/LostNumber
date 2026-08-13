package com.averixor.lostnumber.firebase;

import android.app.Activity;
import android.os.CancellationSignal;
import android.util.Log;
import androidx.credentials.ClearCredentialStateRequest;
import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.ClearCredentialException;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;
import com.google.android.libraries.identity.googleid.GetGoogleIdOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GoogleAuthProvider;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Google Sign-In via Credential Manager → Firebase Auth (Auth-only; no Firestore).
 */
public class LostNumberFirebasePlugin extends GodotPlugin {
  private static final String TAG = "LostNumberFirebase";
  private static final String SIGNAL_AUTH_RESULT = "auth_result";

  private FirebaseAuth firebaseAuth;
  private CredentialManager credentialManager;
  private boolean firebaseReady = false;
  private String lastError = "";
  private String webClientId = "";
  private final ExecutorService credentialExecutor = Executors.newSingleThreadExecutor();

  public LostNumberFirebasePlugin(Godot godot) {
    super(godot);
  }

  @Override
  public String getPluginName() {
    return "LostNumberFirebase";
  }

  @Override
  public Set<SignalInfo> getPluginSignals() {
    return Collections.singleton(new SignalInfo(SIGNAL_AUTH_RESULT, String.class));
  }

  @Override
  public void onGodotSetupCompleted() {
    super.onGodotSetupCompleted();
    ensureFirebase();
  }

  private synchronized boolean ensureFirebase() {
    if (firebaseReady && firebaseAuth != null && credentialManager != null) {
      return true;
    }
    Activity activity = getActivity();
    if (activity == null) {
      lastError = "no_activity";
      return false;
    }
    try {
      if (FirebaseApp.getApps(activity).isEmpty()) {
        FirebaseApp.initializeApp(activity);
      }
      if (FirebaseApp.getApps(activity).isEmpty()) {
        lastError = "firebase_not_configured";
        Log.w(TAG, "FirebaseApp not configured (missing google-services.json merge?)");
        return false;
      }
      firebaseAuth = FirebaseAuth.getInstance();
      webClientId = resolveWebClientId(activity);
      if (webClientId == null || webClientId.isEmpty() || webClientId.startsWith("YOUR_")) {
        lastError = "missing_web_client_id";
        Log.w(TAG, "default_web_client_id missing — add google-services.json / OAuth client");
        return false;
      }
      credentialManager = CredentialManager.create(activity);
      firebaseReady = true;
      lastError = "";
      return true;
    } catch (Exception e) {
      lastError = "firebase_init_failed";
      Log.w(TAG, "Firebase init failed", e);
      return false;
    }
  }

  private String resolveWebClientId(Activity activity) {
    int resId =
        activity
            .getResources()
            .getIdentifier("default_web_client_id", "string", activity.getPackageName());
    if (resId == 0) {
      return "";
    }
    try {
      return activity.getString(resId);
    } catch (Exception e) {
      return "";
    }
  }

  @UsedByGodot
  public boolean isAvailable() {
    return ensureFirebase();
  }

  @UsedByGodot
  public String getLastError() {
    return lastError == null ? "" : lastError;
  }

  @UsedByGodot
  public boolean isSignedIn() {
    if (!ensureFirebase()) {
      return false;
    }
    return firebaseAuth.getCurrentUser() != null;
  }

  @UsedByGodot
  public String getUserJson() {
    if (!ensureFirebase()) {
      return userPayload("logged_out", null, lastError);
    }
    FirebaseUser user = firebaseAuth.getCurrentUser();
    if (user == null) {
      return userPayload("logged_out", null, "");
    }
    return userPayload("logged_in", user, "");
  }

  @UsedByGodot
  public void signInGoogle() {
    Activity activity = getActivity();
    if (activity == null) {
      emitAuth("error", null, "no_activity");
      return;
    }
    if (!ensureFirebase() || credentialManager == null) {
      emitAuth("error", null, lastError.isEmpty() ? "firebase_not_configured" : lastError);
      return;
    }
    emitAuth("signing_in", null, "");

    GetGoogleIdOption googleIdOption =
        new GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(webClientId)
            .setAutoSelectEnabled(false)
            .build();
    GetCredentialRequest request =
        new GetCredentialRequest.Builder().addCredentialOption(googleIdOption).build();

    CancellationSignal cancellationSignal = new CancellationSignal();
    credentialManager.getCredentialAsync(
        activity,
        request,
        cancellationSignal,
        credentialExecutor,
        new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
          @Override
          public void onResult(GetCredentialResponse result) {
            handleCredentialResponse(result);
          }

          @Override
          public void onError(GetCredentialException e) {
            if (e instanceof GetCredentialCancellationException) {
              emitAuth("logged_out", null, "cancelled");
            } else {
              String msg = e.getMessage();
              emitAuth("error", null, msg == null ? "credential_failed" : msg);
            }
          }
        });
  }

  private void handleCredentialResponse(GetCredentialResponse result) {
    Activity activity = getActivity();
    if (activity == null || firebaseAuth == null) {
      emitAuth("error", null, "no_activity");
      return;
    }
    try {
      Credential credential = result.getCredential();
      if (!(credential instanceof CustomCredential)
          || !GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(
              credential.getType())) {
        emitAuth("error", null, "unexpected_credential_type");
        return;
      }
      GoogleIdTokenCredential googleIdTokenCredential =
          GoogleIdTokenCredential.createFrom(credential.getData());
      String idToken = googleIdTokenCredential.getIdToken();
      if (idToken == null || idToken.isEmpty()) {
        emitAuth("error", null, "missing_id_token");
        return;
      }
      AuthCredential firebaseCredential = GoogleAuthProvider.getCredential(idToken, null);
      firebaseAuth
          .signInWithCredential(firebaseCredential)
          .addOnCompleteListener(
              activity,
              authTask -> {
                if (authTask.isSuccessful()) {
                  emitAuth("logged_in", firebaseAuth.getCurrentUser(), "");
                } else {
                  Exception ex = authTask.getException();
                  String msg = ex != null ? ex.getMessage() : "auth_failed";
                  emitAuth("error", null, msg == null ? "auth_failed" : msg);
                }
              });
    } catch (Exception e) {
      Log.w(TAG, "handleCredentialResponse failed", e);
      emitAuth("error", null, "credential_parse_failed");
    }
  }

  @UsedByGodot
  public void signOut() {
    if (!ensureFirebase()) {
      emitAuth("error", null, lastError.isEmpty() ? "firebase_not_configured" : lastError);
      return;
    }
    Activity activity = getActivity();
    firebaseAuth.signOut();
    if (credentialManager != null && activity != null) {
      CancellationSignal cancellationSignal = new CancellationSignal();
      credentialManager.clearCredentialStateAsync(
          new ClearCredentialStateRequest(),
          cancellationSignal,
          credentialExecutor,
          new CredentialManagerCallback<Void, ClearCredentialException>() {
            @Override
            public void onResult(Void unused) {
              emitAuth("logged_out", null, "");
            }

            @Override
            public void onError(ClearCredentialException e) {
              // Local Firebase session already cleared.
              emitAuth("logged_out", null, "");
            }
          });
    } else {
      emitAuth("logged_out", null, "");
    }
  }

  private void emitAuth(String status, FirebaseUser user, String error) {
    String json = userPayload(status, user, error);
    lastError = error == null ? "" : error;
    try {
      emitSignal(SIGNAL_AUTH_RESULT, json);
    } catch (Exception e) {
      Log.w(TAG, "emitSignal failed", e);
    }
  }

  private static String userPayload(String status, FirebaseUser user, String error) {
    JSONObject obj = new JSONObject();
    try {
      obj.put("status", status == null ? "" : status);
      obj.put("error", error == null ? "" : error);
      if (user != null) {
        obj.put("uid", user.getUid() == null ? "" : user.getUid());
        obj.put("displayName", user.getDisplayName() == null ? "" : user.getDisplayName());
        // Do not persist email into our own files; still expose for in-memory UI label.
        obj.put("email", user.getEmail() == null ? "" : user.getEmail());
      } else {
        obj.put("uid", "");
        obj.put("displayName", "");
        obj.put("email", "");
      }
    } catch (JSONException e) {
      return "{\"status\":\"error\",\"error\":\"json_encode_failed\",\"uid\":\"\",\"displayName\":\"\",\"email\":\"\"}";
    }
    return obj.toString();
  }
}
