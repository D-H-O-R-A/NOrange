package com.harshRajpurohit.freeVpn;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.Gravity;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;

public class VirtualCameraActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor("#0D1117"));
        root.setGravity(Gravity.CENTER);
        root.setPadding(40, 60, 40, 60);

        TextView header = new TextView(this);
        header.setText("📷 Hide Protocol - Câmera Virtualizada");
        header.setTextColor(Color.WHITE);
        header.setTextSize(18f);
        header.setTypeface(null, Typeface.BOLD);
        header.setGravity(Gravity.CENTER);
        root.addView(header);

        File virtualFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
        final Bitmap loadedBitmap = virtualFile.exists()
                ? BitmapFactory.decodeFile(virtualFile.getAbsolutePath())
                : createPlaceholderBitmap();

        ImageView preview = new ImageView(this);
        LinearLayout.LayoutParams imgParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f);
        imgParams.setMargins(0, 32, 0, 32);
        preview.setLayoutParams(imgParams);
        preview.setImageBitmap(loadedBitmap);
        root.addView(preview);

        Button btnConfirm = new Button(this);
        btnConfirm.setText("✅ Usar Esta Foto Virtual na Captura");
        btnConfirm.setBackgroundColor(Color.parseColor("#1E88E5"));
        btnConfirm.setTextColor(Color.WHITE);
        btnConfirm.setPadding(30, 24, 30, 24);
        btnConfirm.setOnClickListener(v -> deliverVirtualFrame(virtualFile, loadedBitmap));
        root.addView(btnConfirm);

        Button btnCancel = new Button(this);
        btnCancel.setText("Cancelar");
        btnCancel.setTextColor(Color.LTGRAY);
        btnCancel.setBackgroundColor(Color.TRANSPARENT);
        btnCancel.setOnClickListener(v -> {
            setResult(Activity.RESULT_CANCELED);
            finish();
        });
        root.addView(btnCancel);

        setContentView(root);
    }

    private void deliverVirtualFrame(File virtualFile, Bitmap bitmap) {
        try {
            Intent intent = getIntent();
            Uri outputUri = null;
            if (intent != null && intent.getExtras() != null) {
                outputUri = intent.getParcelableExtra(MediaStore.EXTRA_OUTPUT);
            }

            if (outputUri != null) {
                try (OutputStream out = getContentResolver().openOutputStream(outputUri)) {
                    if (out != null) {
                        if (virtualFile.exists()) {
                            try (FileInputStream in = new FileInputStream(virtualFile)) {
                                byte[] buf = new byte[8192];
                                int len;
                                while ((len = in.read(buf)) > 0) {
                                    out.write(buf, 0, len);
                                }
                            }
                        } else {
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out);
                        }
                        out.flush();
                    }
                }
            }

            Bitmap thumb = Bitmap.createScaledBitmap(bitmap, 240, 240, true);
            Intent resultIntent = new Intent();
            resultIntent.putExtra("data", thumb);
            setResult(Activity.RESULT_OK, resultIntent);
            Toast.makeText(this, "Foto virtualizada enviada com sucesso!", Toast.LENGTH_SHORT).show();
            finish();
        } catch (Exception e) {
            Toast.makeText(this, "Erro ao enviar foto virtual: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            setResult(Activity.RESULT_CANCELED);
            finish();
        }
    }

    private Bitmap createPlaceholderBitmap() {
        Bitmap bmp = Bitmap.createBitmap(640, 480, Bitmap.Config.ARGB_8888);
        bmp.eraseColor(Color.parseColor("#1565C0"));
        return bmp;
    }
}
