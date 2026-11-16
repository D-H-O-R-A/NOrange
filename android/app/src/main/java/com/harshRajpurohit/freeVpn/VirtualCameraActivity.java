package com.harshRajpurohit.freeVpn;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import android.content.ClipData;
import android.media.ExifInterface;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.view.Surface;
import android.view.WindowInsets;
import androidx.core.content.FileProvider;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Locale;

public class VirtualCameraActivity extends Activity {
    public static final String PREFS_VCAM = "norange_vcam_state";
    public static final String KEY_VCAM_ENABLED = "vcam_enabled";
    public static final String ACTION_VCAM_SYNC = "norangeVcamTransformSync";
    private static final int PICK_IMAGE_REQ = 301;
    private static final int MAX_VCAM_DIMENSION = 1280;

    private ImageView preview;
    private TextView liveTelemetryBadge;
    private Button btnConfirmAction;
    private Bitmap rawBitmap;
    private Bitmap currentTransformedBitmap;

    private float scaleX = 1.0f;
    private float scaleY = 1.0f;
    private float offsetX = 0.0f;
    private float offsetY = 0.0f;
    private float rotation = 0.0f;
    private boolean flipH = false;
    private boolean flipV = false;
    private float perspectivePitch = 0.0f;
    private float perspectiveYaw = 0.0f;

    private ScaleGestureDetector scaleDetector;
    private float lastTouchX = 0f;
    private float lastTouchY = 0f;
    private boolean isDragging = false;

    private final BroadcastReceiver syncReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent != null && "external".equals(intent.getStringExtra("source"))) {
                loadSavedTransformParams( VirtualCameraActivity.this );
                loadInitialBitmaps();
                rebuildAndSaveFrame(false);
            }
        }
    };

    private int dp(float v) {
        return Math.round(v * getResources().getDisplayMetrics().density);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        loadSavedTransformParams(this);
        loadInitialBitmaps();

        LocalBroadcastManager.getInstance(this).registerReceiver(
                syncReceiver,
                new IntentFilter(ACTION_VCAM_SYNC)
        );

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor("#060608"));
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setPadding(dp(16), dp(20), dp(16), dp(16));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            root.setOnApplyWindowInsetsListener((v, insets) -> {
                int top = dp(20);
                int bottom = dp(16);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    android.graphics.Insets sys = insets.getInsets(
                            WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout()
                    );
                    top = Math.max(top, sys.top + dp(10));
                    bottom = Math.max(bottom, sys.bottom + dp(10));
                } else {
                    top = Math.max(top, insets.getSystemWindowInsetTop() + dp(10));
                    bottom = Math.max(bottom, insets.getSystemWindowInsetBottom() + dp(10));
                }
                v.setPadding(dp(16), top, dp(16), bottom);
                return insets;
            });
        }

        // Header Row with Live Indicator Dot
        LinearLayout headerRow = new LinearLayout(this);
        headerRow.setOrientation(LinearLayout.HORIZONTAL);
        headerRow.setGravity(Gravity.CENTER);

        View liveDot = new View(this);
        GradientDrawable dotBg = new GradientDrawable();
        dotBg.setShape(GradientDrawable.OVAL);
        dotBg.setColor(Color.parseColor("#FF6B00"));
        liveDot.setBackground(dotBg);
        LinearLayout.LayoutParams dotLp = new LinearLayout.LayoutParams(dp(9), dp(9));
        dotLp.setMargins(0, 0, dp(8), 0);
        liveDot.setLayoutParams(dotLp);
        headerRow.addView(liveDot);

        TextView header = new TextView(this);
        header.setText("NOrange • Câmera Virtual em Tempo Real");
        header.setTextColor(Color.parseColor("#F8FAFC"));
        header.setTextSize(15.5f);
        header.setTypeface(null, Typeface.BOLD);
        headerRow.addView(header);
        root.addView(headerRow);

        String action = getIntent() != null ? getIntent().getAction() : "";
        String reqType = getIntent() != null ? getIntent().getType() : "";
        boolean isVideoIntent = MediaStore.ACTION_VIDEO_CAPTURE.equals(action)
                || "android.media.action.VIDEO_CAMERA".equals(action)
                || (reqType != null && reqType.toLowerCase(Locale.US).startsWith("video/"));
        boolean isCaptureRequest = MediaStore.ACTION_IMAGE_CAPTURE.equals(action)
                || "android.media.action.IMAGE_CAPTURE_SECURE".equals(action)
                || MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA.equals(action)
                || "android.media.action.STILL_IMAGE_CAMERA_SECURE".equals(action)
                || MediaStore.ACTION_VIDEO_CAPTURE.equals(action)
                || "android.media.action.VIDEO_CAMERA".equals(action)
                || Intent.ACTION_GET_CONTENT.equals(action)
                || Intent.ACTION_PICK.equals(action);

        TextView subHeader = new TextView(this);
        subHeader.setText(isVideoIntent
                ? "App solicitou vídeo: ajuste o quadro virtual em tempo real para gerar e enviar o MP4"
                : (isCaptureRequest
                ? "App solicitou a câmera/mídia: arraste ou ajuste em tempo real antes de enviar"
                : "Arraste ou faça pinça direto na imagem ou use os ícones vetoriais para ajustar em tempo real"));
        subHeader.setTextColor(Color.parseColor("#9CA3AF"));
        subHeader.setTextSize(11f);
        subHeader.setGravity(Gravity.CENTER);
        subHeader.setPadding(0, dp(4), 0, dp(8));
        root.addView(subHeader);

        // Live Interactive Viewfinder Frame
        FrameLayout viewfinderFrame = new FrameLayout(this);
        LinearLayout.LayoutParams vfParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f);
        vfParams.setMargins(0, dp(4), 0, dp(8));
        viewfinderFrame.setLayoutParams(vfParams);

        GradientDrawable previewBg = new GradientDrawable();
        previewBg.setColor(Color.parseColor("#0B0D13"));
        previewBg.setCornerRadius(dp(14));
        previewBg.setStroke(dp(1.3f), Color.parseColor("#FF6B00"));
        viewfinderFrame.setBackground(previewBg);
        viewfinderFrame.setPadding(dp(4), dp(4), dp(4), dp(4));

        preview = new ImageView(this);
        FrameLayout.LayoutParams imgLp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        );
        preview.setLayoutParams(imgLp);
        preview.setScaleType(ImageView.ScaleType.FIT_CENTER);
        preview.setImageBitmap(currentTransformedBitmap);
        viewfinderFrame.addView(preview);

        // Top-Left HUD Badge showing real-time scale & position
        liveTelemetryBadge = new TextView(this);
        liveTelemetryBadge.setTextColor(Color.parseColor("#F8FAFC"));
        liveTelemetryBadge.setTextSize(10f);
        liveTelemetryBadge.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        liveTelemetryBadge.setPadding(dp(8), dp(4), dp(8), dp(4));
        GradientDrawable hudBg = new GradientDrawable();
        hudBg.setColor(Color.parseColor("#CC08090C"));
        hudBg.setCornerRadius(dp(8));
        hudBg.setStroke(dp(1), Color.parseColor("#44FF6B00"));
        liveTelemetryBadge.setBackground(hudBg);
        FrameLayout.LayoutParams hudLp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.TOP | Gravity.START
        );
        hudLp.setMargins(dp(8), dp(8), dp(8), dp(8));
        liveTelemetryBadge.setLayoutParams(hudLp);
        viewfinderFrame.addView(liveTelemetryBadge);
        updateHudBadgeText();

        // Interactive Touch Drag (Pan) + Pinch (Scale) directly on the Live Viewfinder
        scaleDetector = new ScaleGestureDetector(this, new ScaleGestureDetector.SimpleOnScaleGestureListener() {
            @Override
            public boolean onScale(ScaleGestureDetector detector) {
                float factor = detector.getScaleFactor();
                scaleX = Math.max(0.35f, Math.min(3.5f, scaleX * factor));
                scaleY = Math.max(0.35f, Math.min(3.5f, scaleY * factor));
                rebuildAndSaveFrame(true);
                return true;
            }
        });

        viewfinderFrame.setOnTouchListener((v, event) -> {
            scaleDetector.onTouchEvent(event);
            if (scaleDetector.isInProgress()) {
                isDragging = false;
                return true;
            }
            switch (event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    lastTouchX = event.getX();
                    lastTouchY = event.getY();
                    isDragging = true;
                    return true;
                case MotionEvent.ACTION_MOVE:
                    if (isDragging && event.getPointerCount() == 1) {
                        float dx = event.getX() - lastTouchX;
                        float dy = event.getY() - lastTouchY;
                        lastTouchX = event.getX();
                        lastTouchY = event.getY();
                        float vw = Math.max(1f, viewfinderFrame.getWidth());
                        float vh = Math.max(1f, viewfinderFrame.getHeight());
                        offsetX = Math.max(-1.0f, Math.min(1.0f, offsetX + (dx / (vw * 0.45f))));
                        offsetY = Math.max(-1.0f, Math.min(1.0f, offsetY + (dy / (vh * 0.45f))));
                        rebuildAndSaveFrame(true);
                    }
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    isDragging = false;
                    return true;
            }
            return true;
        });

        root.addView(viewfinderFrame);

        // Row 1: Move Left, Right, Up, Down (Vector Icons + Labels — Zero text arrows!)
        LinearLayout moveRow = createControlBar();
        moveRow.addView(createIconChipButton(VectorControlIconView.ICON_LEFT, "Esquerda", () -> {
            offsetX = Math.max(-1.0f, offsetX - 0.10f);
            rebuildAndSaveFrame(true);
        }));
        moveRow.addView(createIconChipButton(VectorControlIconView.ICON_RIGHT, "Direita", () -> {
            offsetX = Math.min(1.0f, offsetX + 0.10f);
            rebuildAndSaveFrame(true);
        }));
        moveRow.addView(createIconChipButton(VectorControlIconView.ICON_UP, "Cima", () -> {
            offsetY = Math.max(-1.0f, offsetY - 0.10f);
            rebuildAndSaveFrame(true);
        }));
        moveRow.addView(createIconChipButton(VectorControlIconView.ICON_DOWN, "Baixo", () -> {
            offsetY = Math.min(1.0f, offsetY + 0.10f);
            rebuildAndSaveFrame(true);
        }));
        root.addView(wrapHorizontalScroll(moveRow));

        // Row 2: Zoom +, Zoom -, Stretch H, Narrow H, Stretch V, Narrow V
        LinearLayout scaleRow = createControlBar();
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_ZOOM_IN, "Zoom +", () -> {
            scaleX = Math.min(3.5f, scaleX + 0.15f);
            scaleY = Math.min(3.5f, scaleY + 0.15f);
            rebuildAndSaveFrame(true);
        }));
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_ZOOM_OUT, "Zoom -", () -> {
            scaleX = Math.max(0.35f, scaleX - 0.15f);
            scaleY = Math.max(0.35f, scaleY - 0.15f);
            rebuildAndSaveFrame(true);
        }));
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_STRETCH_H, "Alargar H", () -> {
            scaleX = Math.min(3.5f, scaleX + 0.18f);
            rebuildAndSaveFrame(true);
        }));
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_NARROW_H, "Estreitar H", () -> {
            scaleX = Math.max(0.35f, scaleX - 0.18f);
            rebuildAndSaveFrame(true);
        }));
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_STRETCH_V, "Alargar V", () -> {
            scaleY = Math.min(3.5f, scaleY + 0.18f);
            rebuildAndSaveFrame(true);
        }));
        scaleRow.addView(createIconChipButton(VectorControlIconView.ICON_NARROW_V, "Estreitar V", () -> {
            scaleY = Math.max(0.35f, scaleY - 0.18f);
            rebuildAndSaveFrame(true);
        }));
        root.addView(wrapHorizontalScroll(scaleRow));

        // Row 2.5: 3D Perspective Transform (Nodding / Turning in 3D Perspective)
        LinearLayout perspRow = createControlBar();
        perspRow.addView(createIconChipButton(VectorControlIconView.ICON_PERSPECTIVE_LEFT, "Olhar Esq", () -> {
            perspectiveYaw = Math.max(-45f, perspectiveYaw - 7.5f);
            rebuildAndSaveFrame(true);
        }));
        perspRow.addView(createIconChipButton(VectorControlIconView.ICON_PERSPECTIVE_RIGHT, "Olhar Dir", () -> {
            perspectiveYaw = Math.min(45f, perspectiveYaw + 7.5f);
            rebuildAndSaveFrame(true);
        }));
        perspRow.addView(createIconChipButton(VectorControlIconView.ICON_PERSPECTIVE_UP, "Olhar Cima", () -> {
            perspectivePitch = Math.max(-45f, perspectivePitch - 7.5f);
            rebuildAndSaveFrame(true);
        }));
        perspRow.addView(createIconChipButton(VectorControlIconView.ICON_PERSPECTIVE_DOWN, "Olhar Baixo", () -> {
            perspectivePitch = Math.min(45f, perspectivePitch + 7.5f);
            rebuildAndSaveFrame(true);
        }));
        root.addView(wrapHorizontalScroll(perspRow));

        // Row 3: Rotate 90, Flip H, Flip V, Reset
        LinearLayout rotRow = createControlBar();
        rotRow.addView(createIconChipButton(VectorControlIconView.ICON_ROTATE, "Girar 90°", () -> {
            rotation = (rotation + 90f) % 360f;
            rebuildAndSaveFrame(true);
        }));
        rotRow.addView(createIconChipButton(VectorControlIconView.ICON_FLIP_H, "Espelhar H", () -> {
            flipH = !flipH;
            rebuildAndSaveFrame(true);
        }));
        rotRow.addView(createIconChipButton(VectorControlIconView.ICON_FLIP_V, "Espelhar V", () -> {
            flipV = !flipV;
            rebuildAndSaveFrame(true);
        }));
        rotRow.addView(createIconChipButton(VectorControlIconView.ICON_RESET, "Resetar", () -> {
            scaleX = 1.0f;
            scaleY = 1.0f;
            offsetX = 0.0f;
            offsetY = 0.0f;
            rotation = 0.0f;
            flipH = false;
            flipV = false;
            perspectivePitch = 0.0f;
            perspectiveYaw = 0.0f;
            rebuildAndSaveFrame(true);
        }));
        root.addView(wrapHorizontalScroll(rotRow));

        // Action Row: Pick Image on the spot + Confirm/Inject into Camera/Live
        LinearLayout actionRow = new LinearLayout(this);
        actionRow.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams actLp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        actLp.setMargins(0, dp(8), 0, dp(4));
        actionRow.setLayoutParams(actLp);

        Button btnPick = new Button(this);
        btnPick.setAllCaps(false);
        btnPick.setText("Escolher Foto Agora");
        btnPick.setTextColor(Color.parseColor("#F8FAFC"));
        btnPick.setTextSize(12f);
        GradientDrawable pickBg = new GradientDrawable();
        pickBg.setColor(Color.parseColor("#181B24"));
        pickBg.setCornerRadius(dp(12));
        pickBg.setStroke(dp(1), Color.parseColor("#FF8833"));
        btnPick.setBackground(pickBg);
        LinearLayout.LayoutParams pickLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        pickLp.setMargins(0, 0, dp(8), 0);
        btnPick.setLayoutParams(pickLp);
        btnPick.setOnClickListener(v -> {
            Intent pickIntent = createPhotoPickerIntent(this);
            startActivityForResult(pickIntent, PICK_IMAGE_REQ);
        });
        actionRow.addView(btnPick);

        btnConfirmAction = new Button(this);
        btnConfirmAction.setAllCaps(false);
        btnConfirmAction.setText(isVideoIntent
                ? "Gerar Vídeo MP4 & Enviar"
                : (isCaptureRequest ? "Capturar / Enviar ao App" : "Aplicar & Salvar na Galeria"));
        btnConfirmAction.setTextColor(Color.parseColor("#060608"));
        btnConfirmAction.setTextSize(12f);
        btnConfirmAction.setTypeface(null, Typeface.BOLD);
        GradientDrawable confBg = new GradientDrawable();
        confBg.setColor(Color.parseColor("#FF6B00"));
        confBg.setCornerRadius(dp(12));
        btnConfirmAction.setBackground(confBg);
        LinearLayout.LayoutParams confLp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.15f);
        btnConfirmAction.setLayoutParams(confLp);
        btnConfirmAction.setOnClickListener(v -> {
            getSharedPreferences(PREFS_VCAM, Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean(KEY_VCAM_ENABLED, true)
                    .apply();
            File virtualFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
            deliverVirtualFrame(virtualFile, currentTransformedBitmap);
        });
        actionRow.addView(btnConfirmAction);

        root.addView(actionRow);

        Button btnCancel = new Button(this);
        btnCancel.setAllCaps(false);
        btnCancel.setText("Fechar");
        btnCancel.setTextColor(Color.parseColor("#9CA3AF"));
        btnCancel.setBackgroundColor(Color.TRANSPARENT);
        btnCancel.setOnClickListener(v -> {
            setResult(Activity.RESULT_CANCELED);
            finish();
        });
        root.addView(btnCancel);

        setContentView(root);
    }

    private void updateHudBadgeText() {
        if (liveTelemetryBadge == null) return;
        int pctX = Math.round(scaleX * 100f);
        int pctY = Math.round(scaleY * 100f);
        int posX = Math.round(offsetX * 100f);
        int posY = Math.round(offsetY * 100f);
        liveTelemetryBadge.setText(String.format(
                Locale.US,
                "LIVE VCAM • Escala %d%%x%d%% • Pos (%+d, %+d) • %d°",
                pctX, pctY, posX, posY, Math.round(rotation)
        ));
    }

    private LinearLayout createControlBar() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        return row;
    }

    private HorizontalScrollView wrapHorizontalScroll(LinearLayout row) {
        HorizontalScrollView hsv = new HorizontalScrollView(this);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(0, dp(2.5f), 0, dp(2.5f));
        hsv.setLayoutParams(lp);
        hsv.addView(row);
        return hsv;
    }

    private LinearLayout createIconChipButton(int iconType, String label, Runnable onTap) {
        LinearLayout chip = new LinearLayout(this);
        chip.setOrientation(LinearLayout.HORIZONTAL);
        chip.setGravity(Gravity.CENTER_VERTICAL);
        chip.setPadding(dp(10), dp(6.5f), dp(10), dp(6.5f));

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        lp.setMargins(dp(3), 0, dp(3), 0);
        chip.setLayoutParams(lp);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.parseColor("#161922"));
        bg.setCornerRadius(dp(8));
        bg.setStroke(dp(1), Color.parseColor("#2A2F3D"));
        chip.setBackground(bg);

        VectorControlIconView iconView = new VectorControlIconView(this, iconType);
        LinearLayout.LayoutParams iconLp = new LinearLayout.LayoutParams(dp(14), dp(14));
        iconLp.setMargins(0, 0, dp(5), 0);
        iconView.setLayoutParams(iconLp);
        chip.addView(iconView);

        TextView tv = new TextView(this);
        tv.setText(label);
        tv.setTextColor(Color.parseColor("#F8FAFC"));
        tv.setTextSize(10.5f);
        tv.setTypeface(null, Typeface.BOLD);
        chip.addView(tv);

        chip.setOnClickListener(v -> onTap.run());
        return chip;
    }

    private void loadSavedTransformParams(Context ctx) {
        SharedPreferences sp = ctx.getSharedPreferences(PREFS_VCAM, Context.MODE_PRIVATE);
        scaleX = sp.getFloat("scaleX", 1.0f);
        scaleY = sp.getFloat("scaleY", 1.0f);
        offsetX = sp.getFloat("offsetX", 0.0f);
        offsetY = sp.getFloat("offsetY", 0.0f);
        rotation = sp.getFloat("rotation", 0.0f);
        flipH = sp.getBoolean("flipH", false);
        flipV = sp.getBoolean("flipV", false);
        perspectivePitch = sp.getFloat("pitch", 0.0f);
        perspectiveYaw = sp.getFloat("yaw", 0.0f);
    }

    public static void saveTransformParams(
            Context ctx,
            float sx,
            float sy,
            float ox,
            float oy,
            float rot,
            boolean fh,
            boolean fv,
            float pitch,
            float yaw
    ) {
        ctx.getSharedPreferences(PREFS_VCAM, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_VCAM_ENABLED, true)
                .putFloat("scaleX", sx)
                .putFloat("scaleY", sy)
                .putFloat("offsetX", ox)
                .putFloat("offsetY", oy)
                .putFloat("rotation", rot)
                .putBoolean("flipH", fh)
                .putBoolean("flipV", fv)
                .putFloat("pitch", pitch)
                .putFloat("yaw", yaw)
                .apply();
    }

    public static void saveTransformParams(
            Context ctx,
            float sx,
            float sy,
            float ox,
            float oy,
            float rot,
            boolean fh,
            boolean fv
    ) {
        saveTransformParams(ctx, sx, sy, ox, oy, rot, fh, fv, 0f, 0f);
    }

    private void loadInitialBitmaps() {
        File rawFile = new File(getFilesDir(), "virtual_camera_raw.jpg");
        File frameFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
        if (rawFile.exists()) {
            rawBitmap = decodeSampledBitmap(rawFile.getAbsolutePath());
        } else if (frameFile.exists()) {
            rawBitmap = decodeSampledBitmap(frameFile.getAbsolutePath());
        }
        if (rawBitmap == null) {
            rawBitmap = createPlaceholderBitmap();
        }
        currentTransformedBitmap = renderTransformedBitmap(
                rawBitmap, scaleX, scaleY, offsetX, offsetY, rotation, flipH, flipV, perspectivePitch, perspectiveYaw
        );
    }

    private void rebuildAndSaveFrame(boolean broadcastSync) {
        if (rawBitmap == null) return;
        currentTransformedBitmap = renderTransformedBitmap(
                rawBitmap, scaleX, scaleY, offsetX, offsetY, rotation, flipH, flipV, perspectivePitch, perspectiveYaw
        );
        if (preview != null) {
            preview.setImageBitmap(currentTransformedBitmap);
        }
        updateHudBadgeText();

        saveTransformParams(this, scaleX, scaleY, offsetX, offsetY, rotation, flipH, flipV, perspectivePitch, perspectiveYaw);

        File frameFile = new File(getFilesDir(), "virtual_camera_frame.jpg");
        try (FileOutputStream out = new FileOutputStream(frameFile)) {
            currentTransformedBitmap.compress(Bitmap.CompressFormat.JPEG, 92, out);
            out.flush();
        } catch (Exception ignored) {
        }

        if (broadcastSync) {
            Intent sync = new Intent(ACTION_VCAM_SYNC);
            sync.putExtra("source", "activity");
            LocalBroadcastManager.getInstance(this).sendBroadcast(sync);
        }
    }

    public static Bitmap renderTransformedBitmap(
            Bitmap src,
            float sx,
            float sy,
            float ox,
            float oy,
            float rot,
            boolean fh,
            boolean fv,
            float pitch,
            float yaw
    ) {
        int outW = Math.max(480, Math.min(1280, src.getWidth()));
        int outH = Math.max(480, Math.min(1280, src.getHeight()));
        Bitmap out = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(out);
        canvas.drawColor(Color.parseColor("#08090C"));

        Matrix m = new Matrix();
        float cx = src.getWidth() * 0.5f;
        float cy = src.getHeight() * 0.5f;

        m.postTranslate(-cx, -cy);
        float finalSx = sx * (fh ? -1f : 1f);
        float finalSy = sy * (fv ? -1f : 1f);
        m.postScale(finalSx, finalSy);
        m.postRotate(rot);

        // 3D Perspective Transform
        if (Math.abs(pitch) > 0.01f || Math.abs(yaw) > 0.01f) {
            android.graphics.Camera cam3d = new android.graphics.Camera();
            cam3d.save();
            cam3d.rotateX(pitch);
            cam3d.rotateY(yaw);
            Matrix m3d = new Matrix();
            cam3d.getMatrix(m3d);
            cam3d.restore();
            m.postConcat(m3d);
        }

        m.postTranslate(outW * 0.5f + (ox * outW * 0.45f), outH * 0.5f + (oy * outH * 0.45f));

        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
        canvas.drawBitmap(src, m, p);
        return out;
    }

    public static Bitmap renderTransformedBitmap(
            Bitmap src,
            float sx,
            float sy,
            float ox,
            float oy,
            float rot,
            boolean fh,
            boolean fv
    ) {
        return renderTransformedBitmap(src, sx, sy, ox, oy, rot, fh, fv, 0f, 0f);
    }

    public static Uri publishToMediaStore(Context context, Bitmap bitmap) {
        try {
            ContentResolver resolver = context.getContentResolver();
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, "NOrange_Virtual_Camera_" + System.currentTimeMillis() + ".jpg");
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_DCIM + "/Camera");
            }
            Uri uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri != null) {
                try (OutputStream out = resolver.openOutputStream(uri)) {
                    if (out != null) {
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out);
                        out.flush();
                    }
                }
                return uri;
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    /**
     * Seletor de foto que NUNCA lista a própria NOrange (evita loop no HyperOS/MIUI,
     * onde o PICK/GET_CONTENT image/* resolvia para a VirtualCameraActivity).
     */
    public static Intent createPhotoPickerIntent(Context ctx) {
        Intent pick = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        pick.setType("image/*");
        Intent chooser = Intent.createChooser(pick, "Escolher foto para a câmera virtual");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            chooser.putExtra(Intent.EXTRA_EXCLUDE_COMPONENTS, new android.content.ComponentName[]{
                    new android.content.ComponentName(ctx, VirtualCameraActivity.class)
            });
        }
        return chooser;
    }

    /**
     * Decodifica com downsample (max 1280px) e aplica rotação EXIF.
     * Fotos de 50MP (Redmi 13C) estouravam a memória com decodeFile direto.
     */
    public static Bitmap decodeSampledBitmap(String path) {
        try {
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(path, bounds);
            int maxSide = Math.max(bounds.outWidth, bounds.outHeight);
            int sample = 1;
            while (maxSide / (sample * 2) >= MAX_VCAM_DIMENSION) sample *= 2;
            BitmapFactory.Options opts = new BitmapFactory.Options();
            opts.inSampleSize = sample;
            Bitmap bmp = BitmapFactory.decodeFile(path, opts);
            if (bmp == null) return null;
            int degrees = 0;
            try {
                ExifInterface exif = new ExifInterface(path);
                int o = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
                if (o == ExifInterface.ORIENTATION_ROTATE_90) degrees = 90;
                else if (o == ExifInterface.ORIENTATION_ROTATE_180) degrees = 180;
                else if (o == ExifInterface.ORIENTATION_ROTATE_270) degrees = 270;
            } catch (Throwable ignored) {
            }
            if (degrees != 0) {
                Matrix m = new Matrix();
                m.postRotate(degrees);
                Bitmap rot = Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), m, true);
                if (rot != bmp) bmp.recycle();
                bmp = rot;
            }
            return bmp;
        } catch (Throwable t) {
            return null;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == PICK_IMAGE_REQ && resultCode == RESULT_OK && data != null && data.getData() != null) {
            Uri uri = data.getData();
            try {
                File rawDest = new File(getFilesDir(), "virtual_camera_raw.jpg");
                try (InputStream in = getContentResolver().openInputStream(uri);
                     FileOutputStream out = new FileOutputStream(rawDest)) {
                    if (in != null) {
                        byte[] buf = new byte[8192];
                        int len;
                        while ((len = in.read(buf)) > 0) {
                            out.write(buf, 0, len);
                        }
                    }
                }
                Bitmap decoded = decodeSampledBitmap(rawDest.getAbsolutePath());
                if (decoded == null) throw new IllegalStateException("formato de imagem não suportado");
                // Persist the already-rotated, downsampled bitmap as the raw source
                try (FileOutputStream out = new FileOutputStream(rawDest)) {
                    decoded.compress(Bitmap.CompressFormat.JPEG, 95, out);
                }
                rawBitmap = decoded;
                scaleX = 1.0f;
                scaleY = 1.0f;
                offsetX = 0.0f;
                offsetY = 0.0f;
                rotation = 0.0f;
                flipH = false;
                flipV = false;
                perspectivePitch = 0.0f;
                perspectiveYaw = 0.0f;
                rebuildAndSaveFrame(true);
                Toast.makeText(this, "Foto carregada! Arraste ou use os controles em tempo real.", Toast.LENGTH_SHORT).show();
            } catch (Throwable e) {
                Toast.makeText(this, "Erro ao carregar imagem: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    private void writeJpeg(Bitmap bitmap, OutputStream out) throws java.io.IOException {
        bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out);
        out.flush();
    }

    /** Encodes the transformed frame into a short H.264/MP4 clip (for VIDEO_CAPTURE requests). */
    private boolean encodeFrameToMp4(Bitmap frame, File outFile, int seconds) {
        MediaCodec codec = null;
        MediaMuxer muxer = null;
        Surface surface = null;
        try {
            int w = (frame.getWidth() / 2) * 2;
            int h = (frame.getHeight() / 2) * 2;
            Bitmap src = (w == frame.getWidth() && h == frame.getHeight())
                    ? frame : Bitmap.createScaledBitmap(frame, w, h, true);
            final int fps = 30;
            MediaFormat fmt = MediaFormat.createVideoFormat("video/avc", w, h);
            fmt.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface);
            fmt.setInteger(MediaFormat.KEY_BIT_RATE, 4_000_000);
            fmt.setInteger(MediaFormat.KEY_FRAME_RATE, fps);
            fmt.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1);
            codec = MediaCodec.createEncoderByType("video/avc");
            codec.configure(fmt, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
            surface = codec.createInputSurface();
            codec.start();
            muxer = new MediaMuxer(outFile.getAbsolutePath(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);

            MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
            int track = -1;
            boolean muxerStarted = false;
            int totalFrames = fps * Math.max(1, seconds);
            int fed = 0;
            boolean eosSent = false;
            boolean done = false;
            long deadline = System.currentTimeMillis() + 20000;
            while (!done && System.currentTimeMillis() < deadline) {
                if (fed < totalFrames) {
                    Canvas c = surface.lockCanvas(null);
                    try {
                        c.drawBitmap(src, 0, 0, null);
                    } finally {
                        surface.unlockCanvasAndPost(c);
                    }
                    fed++;
                } else if (!eosSent) {
                    codec.signalEndOfInputStream();
                    eosSent = true;
                }
                while (true) {
                    int idx = codec.dequeueOutputBuffer(info, eosSent ? 10000 : 2000);
                    if (idx == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        break;
                    } else if (idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        track = muxer.addTrack(codec.getOutputFormat());
                        muxer.start();
                        muxerStarted = true;
                    } else if (idx >= 0) {
                        ByteBuffer buf = codec.getOutputBuffer(idx);
                        if ((info.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) info.size = 0;
                        if (info.size > 0 && muxerStarted && buf != null) {
                            // Presentation time based on frame index → constant 30 fps playback
                            info.presentationTimeUs = (long) (Math.max(0, fed - 1)) * 1_000_000L / fps;
                            buf.position(info.offset);
                            buf.limit(info.offset + info.size);
                            muxer.writeSampleData(track, buf, info);
                        }
                        codec.releaseOutputBuffer(idx, false);
                        if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            done = true;
                            break;
                        }
                    }
                }
            }
            return muxerStarted && outFile.exists() && outFile.length() > 0;
        } catch (Throwable t) {
            return false;
        } finally {
            try { if (codec != null) { codec.stop(); codec.release(); } } catch (Throwable ignored) { }
            try { if (surface != null) surface.release(); } catch (Throwable ignored) { }
            try { if (muxer != null) { muxer.stop(); muxer.release(); } } catch (Throwable ignored) { }
        }
    }

    private Uri getRequestedOutputUri() {
        Intent intent = getIntent();
        Uri outputUri = null;
        if (intent == null) return null;
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                outputUri = intent.getParcelableExtra(MediaStore.EXTRA_OUTPUT, Uri.class);
            } else {
                outputUri = intent.getParcelableExtra(MediaStore.EXTRA_OUTPUT);
            }
        } catch (Throwable ignored) {
        }
        if (outputUri == null && intent.getClipData() != null && intent.getClipData().getItemCount() > 0) {
            outputUri = intent.getClipData().getItemAt(0).getUri();
        }
        return outputUri;
    }

    private void deliverVirtualFrame(File virtualFile, Bitmap bitmap) {
        final String action = getIntent() != null ? getIntent().getAction() : "";
        final boolean wantsVideo = MediaStore.ACTION_VIDEO_CAPTURE.equals(action)
                || "android.media.action.VIDEO_CAMERA".equals(action)
                || (getIntent() != null && getIntent().getType() != null
                && getIntent().getType().toLowerCase(Locale.US).startsWith("video/"));
        final boolean isPicker = Intent.ACTION_GET_CONTENT.equals(action) || Intent.ACTION_PICK.equals(action);

        rebuildAndSaveFrame(true);
        final Bitmap frame = currentTransformedBitmap;
        if (frame == null) {
            Toast.makeText(this, "Nenhuma imagem para entregar.", Toast.LENGTH_SHORT).show();
            return;
        }
        if (btnConfirmAction != null) {
            btnConfirmAction.setEnabled(false);
            btnConfirmAction.setText(wantsVideo ? "Gerando vídeo..." : "Enviando...");
        }

        new Thread(() -> {
            Uri resultUri = null;
            String mime = "image/jpeg";
            Bitmap thumb = null;
            String error = null;
            try {
                Uri requested = getRequestedOutputUri();
                if (wantsVideo) {
                    mime = "video/mp4";
                    File tmp = new File(getCacheDir(), "norange_vcam_" + System.currentTimeMillis() + ".mp4");
                    if (!encodeFrameToMp4(frame, tmp, 3)) {
                        throw new IllegalStateException("codec de vídeo indisponível");
                    }
                    if (requested != null) {
                        try (InputStream in = new FileInputStream(tmp);
                             OutputStream out = getContentResolver().openOutputStream(requested, "wt")) {
                            byte[] buf = new byte[16384];
                            int len;
                            while (out != null && (len = in.read(buf)) > 0) out.write(buf, 0, len);
                            if (out != null) out.flush();
                        }
                        resultUri = requested;
                    } else {
                        File shared = new File(getFilesDir(), "virtual_camera_clip.mp4");
                        try (InputStream in = new FileInputStream(tmp);
                             FileOutputStream out = new FileOutputStream(shared)) {
                            byte[] buf = new byte[16384];
                            int len;
                            while ((len = in.read(buf)) > 0) out.write(buf, 0, len);
                        }
                        resultUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", shared);
                    }
                    tmp.delete();
                } else {
                    Uri saved = publishToMediaStore(this, frame);
                    if (requested != null && !isPicker) {
                        try (OutputStream out = getContentResolver().openOutputStream(requested, "wt")) {
                            if (out != null) writeJpeg(frame, out);
                            resultUri = requested;
                        } catch (Throwable t1) {
                            try (OutputStream out = getContentResolver().openOutputStream(requested)) {
                                if (out != null) writeJpeg(frame, out);
                                resultUri = requested;
                            } catch (Throwable t2) {
                                error = "app de destino negou gravação";
                            }
                        }
                    }
                    if (resultUri == null) {
                        // Mesma imagem via FileProvider (read grant) caso MediaStore/EXTRA_OUTPUT falhem
                        if (virtualFile != null && virtualFile.exists()) {
                            try {
                                resultUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", virtualFile);
                            } catch (Throwable ignored) {
                            }
                        }
                        if (resultUri == null) resultUri = saved;
                    }
                    thumb = Bitmap.createScaledBitmap(frame,
                            Math.min(frame.getWidth(), 320), Math.min(frame.getHeight(), 320), true);
                }
            } catch (Throwable t) {
                error = t.getMessage() == null ? t.getClass().getSimpleName() : t.getMessage();
            }

            final Uri fUri = resultUri;
            final String fMime = mime;
            final Bitmap fThumb = thumb;
            final String fError = error;
            runOnUiThread(() -> {
                if (fUri == null) {
                    Toast.makeText(this, "Falha ao entregar câmera virtual: " + fError, Toast.LENGTH_LONG).show();
                    if (btnConfirmAction != null) {
                        btnConfirmAction.setEnabled(true);
                        btnConfirmAction.setText("Tentar novamente");
                    }
                    return;
                }
                Intent resultIntent = new Intent();
                if (fThumb != null) resultIntent.putExtra("data", fThumb);
                resultIntent.setDataAndType(fUri, fMime);
                resultIntent.setClipData(ClipData.newUri(getContentResolver(), "media", fUri));
                resultIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                setResult(Activity.RESULT_OK, resultIntent);
                Toast.makeText(this, "Câmera virtualizada entregue com sucesso!", Toast.LENGTH_SHORT).show();
                finish();
            });
        }, "norange-vcam-deliver").start();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(syncReceiver);
        } catch (Exception ignored) {
        }
    }

    private Bitmap createPlaceholderBitmap() {
        Bitmap bmp = Bitmap.createBitmap(640, 480, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bmp);
        c.drawColor(Color.parseColor("#101218"));
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setColor(Color.parseColor("#FF6B00"));
        p.setStyle(Paint.Style.STROKE);
        p.setStrokeWidth(8f);
        c.drawCircle(320f, 240f, 96f, p);
        return bmp;
    }

    /**
     * Custom Vector Icon Renderer for Camera Transform Controls (Zero text/unicode arrows).
     */
    public static class VectorControlIconView extends View {
        public static final int ICON_LEFT = 1;
        public static final int ICON_RIGHT = 2;
        public static final int ICON_UP = 3;
        public static final int ICON_DOWN = 4;
        public static final int ICON_ZOOM_IN = 5;
        public static final int ICON_ZOOM_OUT = 6;
        public static final int ICON_STRETCH_H = 7;
        public static final int ICON_NARROW_H = 8;
        public static final int ICON_STRETCH_V = 9;
        public static final int ICON_NARROW_V = 10;
        public static final int ICON_ROTATE = 11;
        public static final int ICON_FLIP_H = 12;
        public static final int ICON_FLIP_V = 13;
        public static final int ICON_RESET = 14;
        public static final int ICON_PERSPECTIVE_LEFT = 15;
        public static final int ICON_PERSPECTIVE_RIGHT = 16;
        public static final int ICON_PERSPECTIVE_UP = 17;
        public static final int ICON_PERSPECTIVE_DOWN = 18;

        private final int iconType;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private final RectF arcRect = new RectF();

        public VectorControlIconView(Context context, int iconType) {
            super(context);
            this.iconType = iconType;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeCap(Paint.Cap.ROUND);
            paint.setStrokeJoin(Paint.Join.ROUND);
            paint.setStrokeWidth(Math.max(2f, w * 0.13f));
            paint.setColor(Color.parseColor("#FF8833"));

            path.reset();
            switch (iconType) {
                case ICON_LEFT:
                    canvas.drawLine(w * 0.82f, h * 0.5f, w * 0.20f, h * 0.5f, paint);
                    path.moveTo(w * 0.48f, h * 0.22f);
                    path.lineTo(w * 0.18f, h * 0.5f);
                    path.lineTo(w * 0.48f, h * 0.78f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_RIGHT:
                    canvas.drawLine(w * 0.18f, h * 0.5f, w * 0.80f, h * 0.5f, paint);
                    path.moveTo(w * 0.52f, h * 0.22f);
                    path.lineTo(w * 0.82f, h * 0.5f);
                    path.lineTo(w * 0.52f, h * 0.78f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_UP:
                    canvas.drawLine(w * 0.5f, h * 0.82f, w * 0.5f, h * 0.20f, paint);
                    path.moveTo(w * 0.22f, h * 0.48f);
                    path.lineTo(w * 0.5f, h * 0.18f);
                    path.lineTo(w * 0.78f, h * 0.48f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_DOWN:
                    canvas.drawLine(w * 0.5f, h * 0.18f, w * 0.5f, h * 0.80f, paint);
                    path.moveTo(w * 0.22f, h * 0.52f);
                    path.lineTo(w * 0.5f, h * 0.82f);
                    path.lineTo(w * 0.78f, h * 0.52f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_ZOOM_IN:
                    canvas.drawCircle(w * 0.44f, h * 0.44f, w * 0.28f, paint);
                    canvas.drawLine(w * 0.65f, h * 0.65f, w * 0.86f, h * 0.86f, paint);
                    canvas.drawLine(w * 0.44f, h * 0.30f, w * 0.44f, h * 0.58f, paint);
                    canvas.drawLine(w * 0.30f, h * 0.44f, w * 0.58f, h * 0.44f, paint);
                    break;
                case ICON_ZOOM_OUT:
                    canvas.drawCircle(w * 0.44f, h * 0.44f, w * 0.28f, paint);
                    canvas.drawLine(w * 0.65f, h * 0.65f, w * 0.86f, h * 0.86f, paint);
                    canvas.drawLine(w * 0.30f, h * 0.44f, w * 0.58f, h * 0.44f, paint);
                    break;
                case ICON_STRETCH_H:
                    canvas.drawLine(w * 0.14f, h * 0.5f, w * 0.86f, h * 0.5f, paint);
                    path.moveTo(w * 0.34f, h * 0.28f);
                    path.lineTo(w * 0.12f, h * 0.5f);
                    path.lineTo(w * 0.34f, h * 0.72f);
                    path.moveTo(w * 0.66f, h * 0.28f);
                    path.lineTo(w * 0.88f, h * 0.5f);
                    path.lineTo(w * 0.66f, h * 0.72f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_NARROW_H:
                    canvas.drawLine(w * 0.08f, h * 0.5f, w * 0.38f, h * 0.5f, paint);
                    canvas.drawLine(w * 0.92f, h * 0.5f, w * 0.62f, h * 0.5f, paint);
                    path.moveTo(w * 0.24f, h * 0.30f);
                    path.lineTo(w * 0.42f, h * 0.5f);
                    path.lineTo(w * 0.24f, h * 0.70f);
                    path.moveTo(w * 0.76f, h * 0.30f);
                    path.lineTo(w * 0.58f, h * 0.5f);
                    path.lineTo(w * 0.76f, h * 0.70f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_STRETCH_V:
                    canvas.drawLine(w * 0.5f, h * 0.14f, w * 0.5f, h * 0.86f, paint);
                    path.moveTo(w * 0.28f, h * 0.34f);
                    path.lineTo(w * 0.5f, h * 0.12f);
                    path.lineTo(w * 0.72f, h * 0.34f);
                    path.moveTo(w * 0.28f, h * 0.66f);
                    path.lineTo(w * 0.5f, h * 0.88f);
                    path.lineTo(w * 0.72f, h * 0.66f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_NARROW_V:
                    canvas.drawLine(w * 0.5f, h * 0.08f, w * 0.5f, h * 0.38f, paint);
                    canvas.drawLine(w * 0.5f, h * 0.92f, w * 0.5f, h * 0.62f, paint);
                    path.moveTo(w * 0.30f, h * 0.24f);
                    path.lineTo(w * 0.5f, h * 0.42f);
                    path.lineTo(w * 0.70f, h * 0.24f);
                    path.moveTo(w * 0.30f, h * 0.76f);
                    path.lineTo(w * 0.5f, h * 0.58f);
                    path.lineTo(w * 0.70f, h * 0.76f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_ROTATE:
                case ICON_RESET:
                    arcRect.set(w * 0.18f, h * 0.18f, w * 0.82f, h * 0.82f);
                    canvas.drawArc(arcRect, -90f, 270f, false, paint);
                    path.moveTo(w * 0.46f, h * 0.08f);
                    path.lineTo(w * 0.68f, h * 0.20f);
                    path.lineTo(w * 0.46f, h * 0.34f);
                    canvas.drawPath(path, paint);
                    break;
                case ICON_FLIP_H:
                    canvas.drawLine(w * 0.5f, h * 0.14f, w * 0.5f, h * 0.86f, paint);
                    path.moveTo(w * 0.16f, h * 0.72f);
                    path.lineTo(w * 0.38f, h * 0.5f);
                    path.lineTo(w * 0.16f, h * 0.28f);
                    path.close();
                    path.moveTo(w * 0.84f, h * 0.72f);
                    path.lineTo(w * 0.62f, h * 0.5f);
                    path.lineTo(w * 0.84f, h * 0.28f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
                case ICON_FLIP_V:
                    canvas.drawLine(w * 0.14f, h * 0.5f, w * 0.86f, h * 0.5f, paint);
                    path.moveTo(w * 0.28f, h * 0.16f);
                    path.lineTo(w * 0.5f, h * 0.38f);
                    path.lineTo(w * 0.72f, h * 0.16f);
                    path.close();
                    path.moveTo(w * 0.28f, h * 0.84f);
                    path.lineTo(w * 0.5f, h * 0.62f);
                    path.lineTo(w * 0.72f, h * 0.84f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
                case ICON_PERSPECTIVE_LEFT:
                    path.moveTo(w * 0.22f, h * 0.32f);
                    path.lineTo(w * 0.78f, h * 0.18f);
                    path.lineTo(w * 0.78f, h * 0.82f);
                    path.lineTo(w * 0.22f, h * 0.68f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
                case ICON_PERSPECTIVE_RIGHT:
                    path.moveTo(w * 0.22f, h * 0.18f);
                    path.lineTo(w * 0.78f, h * 0.32f);
                    path.lineTo(w * 0.78f, h * 0.68f);
                    path.lineTo(w * 0.22f, h * 0.82f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
                case ICON_PERSPECTIVE_UP:
                    path.moveTo(w * 0.32f, h * 0.22f);
                    path.lineTo(w * 0.68f, h * 0.22f);
                    path.lineTo(w * 0.82f, h * 0.78f);
                    path.lineTo(w * 0.18f, h * 0.78f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
                case ICON_PERSPECTIVE_DOWN:
                    path.moveTo(w * 0.18f, h * 0.22f);
                    path.lineTo(w * 0.82f, h * 0.22f);
                    path.lineTo(w * 0.68f, h * 0.78f);
                    path.lineTo(w * 0.32f, h * 0.78f);
                    path.close();
                    canvas.drawPath(path, paint);
                    break;
            }
        }
    }
}
