package com.averixor.lostnumber;

import android.content.Context;
import android.util.Log;
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Capacitor → Godot save migration helper.
 * Search order: explicit export files → shared_prefs XML → WebView LevelDB heuristic.
 */
public class LostNumberMigrationPlugin extends GodotPlugin {
  private static final String TAG = "LostNumberMigration";
  private static final String SAVE_KEY = "lostNumberSave";
  private static final String EXPORT_FILENAME = "lostnumber_legacy_export.json";

  public LostNumberMigrationPlugin(Godot godot) {
    super(godot);
  }

  @Override
  public String getPluginName() {
    return "LostNumberMigration";
  }

  @UsedByGodot
  public String exportLegacySave() {
    try {
      Context ctx = getActivity().getApplicationContext();
      File filesDir = ctx.getFilesDir();

      for (String name :
          new String[] {
            EXPORT_FILENAME,
            "legacy_capacitor_save.json",
            "imported_save.json",
            "lostNumberSave.json"
          }) {
        String json = readTextFile(new File(filesDir, name));
        if (isLikelySave(json)) {
          Log.i(TAG, "Found save in files/" + name);
          cacheExport(filesDir, json);
          return json;
        }
      }

      String prefsJson = scanSharedPreferences(ctx);
      if (isLikelySave(prefsJson)) {
        Log.i(TAG, "Found save in shared_prefs");
        cacheExport(filesDir, prefsJson);
        return prefsJson;
      }

      String ldbJson = scanWebViewLevelDb(ctx);
      if (isLikelySave(ldbJson)) {
        Log.i(TAG, "Found save via WebView LevelDB heuristic");
        cacheExport(filesDir, ldbJson);
        return ldbJson;
      }

      Log.i(TAG, "No Capacitor save found");
      return "";
    } catch (Exception e) {
      Log.w(TAG, "exportLegacySave failed", e);
      return "";
    }
  }

  private void cacheExport(File filesDir, String json) {
    try {
      File out = new File(filesDir, EXPORT_FILENAME);
      try (FileOutputStream fos = new FileOutputStream(out, false)) {
        fos.write(json.getBytes(StandardCharsets.UTF_8));
      }
    } catch (Exception e) {
      Log.w(TAG, "cacheExport failed", e);
    }
  }

  private static boolean isLikelySave(String json) {
    if (json == null || json.isEmpty()) return false;
    return json.contains("\"version\"")
        && (json.contains("currentLevel") || json.contains("current_level"))
        && json.contains("grid");
  }

  private static String readTextFile(File file) {
    if (file == null || !file.exists() || !file.canRead()) return "";
    try {
      StringBuilder sb = new StringBuilder();
      try (BufferedReader reader =
          new BufferedReader(
              new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8))) {
        String line;
        while ((line = reader.readLine()) != null) {
          sb.append(line);
        }
      }
      return sb.toString().trim();
    } catch (Exception e) {
      return "";
    }
  }

  private static String scanSharedPreferences(Context ctx) {
    File prefsDir = new File(ctx.getApplicationInfo().dataDir, "shared_prefs");
    if (!prefsDir.isDirectory()) return "";
    File[] files = prefsDir.listFiles();
    if (files == null) return "";
    for (File xml : files) {
      String text = readTextFile(xml);
      if (!text.contains(SAVE_KEY) && !text.contains("currentLevel")) continue;
      String extracted = extractJsonObject(text);
      if (isLikelySave(extracted)) return extracted;
    }
    return "";
  }

  private static String scanWebViewLevelDb(Context ctx) {
    File base = new File(ctx.getApplicationInfo().dataDir, "app_webview");
    if (!base.exists()) return "";
    List<File> ldbFiles = new ArrayList<>();
    collectLdbFiles(base, ldbFiles);
    for (File ldb : ldbFiles) {
      try {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        try (FileInputStream fis = new FileInputStream(ldb)) {
          byte[] chunk = new byte[8192];
          int read;
          while ((read = fis.read(chunk)) != -1) {
            buffer.write(chunk, 0, read);
          }
        }
        String blob = new String(buffer.toByteArray(), StandardCharsets.ISO_8859_1);
        int keyIdx = blob.indexOf(SAVE_KEY);
        if (keyIdx >= 0) {
          String tail = blob.substring(keyIdx);
          String extracted = extractJsonObject(tail);
          if (isLikelySave(extracted)) return extracted;
        }
        int versionIdx = blob.indexOf("\"version\":2");
        if (versionIdx >= 0) {
          String extracted = extractJsonObject(blob.substring(versionIdx - 1));
          if (isLikelySave(extracted)) return extracted;
        }
      } catch (Exception ignored) {
        // continue scanning other ldb files
      }
    }
    return "";
  }

  private static void collectLdbFiles(File dir, List<File> out) {
    File[] children = dir.listFiles();
    if (children == null) return;
    for (File child : children) {
      if (child.isDirectory()) {
        collectLdbFiles(child, out);
      } else if (child.getName().endsWith(".ldb") || child.getName().endsWith(".log")) {
        out.add(child);
      }
    }
  }

  /** Best-effort JSON object extraction from mixed binary/text blobs. */
  private static String extractJsonObject(String text) {
    int start = text.indexOf('{');
    if (start < 0) return "";
    int depth = 0;
    for (int i = start; i < text.length(); i++) {
      char c = text.charAt(i);
      if (c == '{') depth++;
      else if (c == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }
    return "";
  }
}
