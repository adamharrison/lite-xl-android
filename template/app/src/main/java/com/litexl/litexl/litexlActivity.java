package com.litexl.litexl;

import org.libsdl.app.SDLActivity;
import android.content.res.AssetManager;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import android.os.Bundle;
import android.util.Log;
import android.os.Environment;
import android.view.View;
import android.app.ActionBar;
import android.view.WindowManager;
import android.view.WindowInsetsController;
import android.view.WindowInsets;
import android.os.Build;
import java.io.File;

public class litexlActivity extends SDLActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        String prefix = getExternalFilesDir(null) + "";
        String userdir = getExternalFilesDir("user") + "";
        String libdir = getApplicationInfo().nativeLibraryDir;
        File file = new File(getExternalFilesDir("files") + "");
        try {
            if (!file.exists() && !file.mkdirs())
                throw new IOException("Can't make directory " + file.getPath());
            copyDirectoryOrFile(getAssets(), "data", getExternalFilesDir("share") + "/lite-xl");
            copyDirectoryOrFile(getAssets(), "user", userdir);
        } catch (IOException e) {
            Log.e("assetManager", "Failed to copy assets: " + e.getMessage());
        }
        super.onCreate(savedInstanceState);
        Log.i("litexl", "Setting LITE_PREFIX to " + prefix);
        nativeSetenv("LITE_PREFIX", prefix);
        Log.i("litexl", "Setting HOME to " + prefix);
        nativeSetenv("HOME", prefix);
        Log.i("litexl", "Setting LITE_SCALE to 1.0");
        nativeSetenv("LITE_SCALE", "2.0");
        Log.i("litexl", "Setting LITE_USERDIR to " + userdir);
        nativeSetenv("LITE_USERDIR", userdir);
        Log.i("litexl", "Setting PATH to " + libdir);
        nativeSetenv("PATH", libdir);

        int currentApiVersion = android.os.Build.VERSION.SDK_INT;
        if (currentApiVersion >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(false);
            WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            final int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
            getWindow().getDecorView().setSystemUiVisibility(flags);
        }
    }

    protected String[] getArguments() {
        String[] args = new String[1];
        args[0] = getExternalFilesDir("files") + "";
        return args;
    }

    private void copyFile(AssetManager assetManager, String source, String target) throws IOException  {
        Log.i("assetManager", "Copying file " + source + " to " + target);
        InputStream in = assetManager.open(source);
        FileOutputStream out = new FileOutputStream(target);
        byte[] buffer = new byte[1024];
        int read;
        while((read = in.read(buffer)) != -1){
            out.write(buffer, 0, read);
        }
        in.close();
        out.flush();
        out.close();
    }

    private void copyDirectoryOrFile(AssetManager assetManager, String source, String target) throws IOException {
        Log.i("assetManager", "Copying assets from " + source);
        String[] files = assetManager.list(source);
        String transformedTarget = target + "/" + source.substring(source.indexOf("/") + 1);
        if (files.length == 0) {
           copyFile(assetManager, source, transformedTarget);
        } else {
            Log.i("assetManager", "Copying directory " + source + " to " + transformedTarget);
            File directory = new File(transformedTarget);
            if (!directory.exists() && !directory.mkdirs())
                throw new IOException("Can't make directory " + transformedTarget);
            for (String file : files)
                copyDirectoryOrFile(assetManager, source != "" ? source + "/" + file : file, target);
        }
    }
}
