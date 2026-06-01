package com.example.flower_shop;

import android.app.Activity;
import android.content.ClipData;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.print.PageRange;
import android.print.PrintAttributes;
import android.print.PrintDocumentAdapter;
import android.print.PrintDocumentInfo;
import android.print.PrintManager;
import android.provider.MediaStore;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String SECURITY_CHANNEL = "florashop/security";
    private static final String FILE_ACTIONS_CHANNEL = "florashop/file_actions";
    private static final String APP_FOLDER = "FloraShop";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            SECURITY_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (!"setSecureScreen".equals(call.method)) {
                result.notImplemented();
                return;
            }

            final Boolean enabled = call.arguments();
            runOnUiThread(() -> {
                if (Boolean.TRUE.equals(enabled)) {
                    getWindow().setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    );
                } else {
                    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                }
                result.success(null);
            });
        });

        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            FILE_ACTIONS_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if ("saveFile".equals(call.method)) {
                handleSaveFile(call, result);
                return;
            }

            if ("shareFile".equals(call.method)) {
                handleShareFile(call, result);
                return;
            }

            if ("printFile".equals(call.method)) {
                handlePrintFile(call, result);
                return;
            }

            result.notImplemented();
        });
    }

    private void handleSaveFile(MethodCall call, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                FilePayload payload = readPayload(call);
                SavedFile savedFile;
                try {
                    savedFile = writeToPublicStorage(payload);
                } catch (Exception publicSaveError) {
                    savedFile = writeToAppExternalStorage(payload);
                }
                final SavedFile finalSavedFile = savedFile;
                runOnUiThread(() -> result.success(finalSavedFile.displayPath));
            } catch (Exception e) {
                runOnUiThread(() -> result.error(
                    "SAVE_FAILED",
                    e.getMessage() == null ? "File belum bisa disimpan." : e.getMessage(),
                    null
                ));
            }
        }).start();
    }

    private void handleShareFile(MethodCall call, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                FilePayload payload = readPayload(call);
                SavedFile savedFile = writeToShareCache(payload);
                runOnUiThread(() -> shareSavedFile(payload, savedFile, result));
            } catch (Exception e) {
                runOnUiThread(() -> result.error(
                    "SHARE_FAILED",
                    e.getMessage() == null ? "File belum bisa dibagikan." : e.getMessage(),
                    null
                ));
            }
        }).start();
    }

    private void handlePrintFile(MethodCall call, MethodChannel.Result result) {
        try {
            FilePayload payload = readPayload(call);
            PrintManager printManager = (PrintManager) getSystemService(PRINT_SERVICE);
            if (printManager == null) {
                result.error("PRINT_UNAVAILABLE", "Layanan printer Android tidak tersedia.", null);
                return;
            }

            String jobName = payload.fileName.replace(".pdf", "");
            printManager.print(
                jobName,
                new PdfBytesPrintAdapter(payload.fileName, payload.bytes),
                new PrintAttributes.Builder()
                    .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                    .build()
            );
            result.success(null);
        } catch (Exception e) {
            result.error(
                "PRINT_FAILED",
                e.getMessage() == null ? "Pilihan printer belum bisa dibuka." : e.getMessage(),
                null
            );
        }
    }

    private FilePayload readPayload(MethodCall call) {
        byte[] bytes = call.argument("bytes");
        String fileName = call.argument("fileName");
        String mimeType = call.argument("mimeType");
        String collection = call.argument("collection");
        String text = call.argument("text");
        String subject = call.argument("subject");

        if (bytes == null || bytes.length == 0) {
            throw new IllegalArgumentException("File struk kosong.");
        }

        if (fileName == null || fileName.trim().isEmpty()) {
            throw new IllegalArgumentException("Nama file struk belum valid.");
        }

        if (mimeType == null || mimeType.trim().isEmpty()) {
            throw new IllegalArgumentException("Format file struk belum valid.");
        }

        return new FilePayload(
            bytes,
            fileName,
            mimeType,
            "pictures".equals(collection),
            text == null ? "" : text,
            subject == null ? "" : subject
        );
    }

    private SavedFile writeToPublicStorage(FilePayload payload) throws Exception {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return writeWithMediaStore(payload);
        }

        return writeLegacyFile(payload);
    }

    private SavedFile writeWithMediaStore(FilePayload payload) throws Exception {
        ContentResolver resolver = getContentResolver();
        String parentDir = payload.isImage
            ? Environment.DIRECTORY_PICTURES
            : Environment.DIRECTORY_DOWNLOADS;

        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, payload.fileName);
        values.put(MediaStore.MediaColumns.MIME_TYPE, payload.mimeType);
        values.put(
            MediaStore.MediaColumns.RELATIVE_PATH,
            parentDir + File.separator + APP_FOLDER
        );
        values.put(MediaStore.MediaColumns.IS_PENDING, 1);

        Uri collectionUri = payload.isImage
            ? MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            : MediaStore.Downloads.EXTERNAL_CONTENT_URI;

        Uri uri = resolver.insert(collectionUri, values);
        if (uri == null) {
            throw new IllegalStateException("Android belum memberi lokasi penyimpanan.");
        }

        try (OutputStream stream = resolver.openOutputStream(uri)) {
            if (stream == null) {
                throw new IllegalStateException("File struk belum bisa dibuka.");
            }
            stream.write(payload.bytes);
        }

        ContentValues pendingDone = new ContentValues();
        pendingDone.put(MediaStore.MediaColumns.IS_PENDING, 0);
        resolver.update(uri, pendingDone, null, null);

        return new SavedFile(
            uri,
            parentDir + File.separator + APP_FOLDER + File.separator + payload.fileName
        );
    }

    private SavedFile writeLegacyFile(FilePayload payload) throws Exception {
        String parentDir = payload.isImage
            ? Environment.DIRECTORY_PICTURES
            : Environment.DIRECTORY_DOWNLOADS;
        File dir = new File(
            Environment.getExternalStoragePublicDirectory(parentDir),
            APP_FOLDER
        );

        if (!dir.exists() && !dir.mkdirs()) {
            throw new IllegalStateException("Folder FloraShop belum bisa dibuat.");
        }

        File file = new File(dir, payload.fileName);
        try (FileOutputStream stream = new FileOutputStream(file)) {
            stream.write(payload.bytes);
        }

        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DATA, file.getAbsolutePath());
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, payload.fileName);
        values.put(MediaStore.MediaColumns.MIME_TYPE, payload.mimeType);

        Uri collectionUri = payload.isImage
            ? MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            : MediaStore.Files.getContentUri("external");
        Uri uri = getContentResolver().insert(collectionUri, values);

        return new SavedFile(
            uri == null ? Uri.fromFile(file) : uri,
            file.getAbsolutePath()
        );
    }

    private SavedFile writeToAppExternalStorage(FilePayload payload) throws Exception {
        String parentDir = payload.isImage
            ? Environment.DIRECTORY_PICTURES
            : Environment.DIRECTORY_DOWNLOADS;
        File baseDir = getExternalFilesDir(parentDir);
        if (baseDir == null) {
            baseDir = getFilesDir();
        }

        File dir = new File(baseDir, APP_FOLDER);
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IllegalStateException("Folder struk belum bisa dibuat.");
        }

        File file = new File(dir, payload.fileName);
        try (FileOutputStream stream = new FileOutputStream(file)) {
            stream.write(payload.bytes);
        }

        return new SavedFile(Uri.fromFile(file), file.getAbsolutePath());
    }

    private SavedFile writeToShareCache(FilePayload payload) throws Exception {
        File dir = new File(getCacheDir(), "receipts");
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IllegalStateException("Folder cache struk belum bisa dibuat.");
        }

        File file = new File(dir, payload.fileName);
        try (FileOutputStream stream = new FileOutputStream(file)) {
            stream.write(payload.bytes);
        }

        Uri uri = FileProvider.getUriForFile(
            this,
            getPackageName() + ".fileprovider",
            file
        );

        return new SavedFile(uri, file.getAbsolutePath());
    }

    private void shareSavedFile(
        FilePayload payload,
        SavedFile savedFile,
        MethodChannel.Result result
    ) {
        try {
            Activity activity = this;
            Intent sendIntent = new Intent(Intent.ACTION_SEND);
            sendIntent.setType(payload.mimeType);
            sendIntent.putExtra(Intent.EXTRA_STREAM, savedFile.uri);
            sendIntent.setClipData(
                ClipData.newUri(getContentResolver(), payload.fileName, savedFile.uri)
            );
            if (!payload.text.isEmpty()) {
                sendIntent.putExtra(Intent.EXTRA_TEXT, payload.text);
            }
            if (!payload.subject.isEmpty()) {
                sendIntent.putExtra(Intent.EXTRA_SUBJECT, payload.subject);
            }
            sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

            Intent chooser = Intent.createChooser(sendIntent, payload.subject);
            activity.startActivity(chooser);
            result.success(null);
        } catch (Exception e) {
            result.error(
                "SHARE_FAILED",
                e.getMessage() == null ? "Menu bagikan belum bisa dibuka." : e.getMessage(),
                null
            );
        }
    }

    private static class FilePayload {
        final byte[] bytes;
        final String fileName;
        final String mimeType;
        final boolean isImage;
        final String text;
        final String subject;

        FilePayload(
            byte[] bytes,
            String fileName,
            String mimeType,
            boolean isImage,
            String text,
            String subject
        ) {
            this.bytes = bytes;
            this.fileName = fileName;
            this.mimeType = mimeType;
            this.isImage = isImage;
            this.text = text;
            this.subject = subject;
        }
    }

    private static class SavedFile {
        final Uri uri;
        final String displayPath;

        SavedFile(Uri uri, String displayPath) {
            this.uri = uri;
            this.displayPath = displayPath;
        }
    }

    private static class PdfBytesPrintAdapter extends PrintDocumentAdapter {
        private final String fileName;
        private final byte[] bytes;

        PdfBytesPrintAdapter(String fileName, byte[] bytes) {
            this.fileName = fileName;
            this.bytes = bytes;
        }

        @Override
        public void onLayout(
            PrintAttributes oldAttributes,
            PrintAttributes newAttributes,
            CancellationSignal cancellationSignal,
            LayoutResultCallback callback,
            Bundle extras
        ) {
            if (cancellationSignal.isCanceled()) {
                callback.onLayoutCancelled();
                return;
            }

            PrintDocumentInfo info = new PrintDocumentInfo.Builder(fileName)
                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                .setPageCount(PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
                .build();
            callback.onLayoutFinished(info, true);
        }

        @Override
        public void onWrite(
            PageRange[] pages,
            ParcelFileDescriptor destination,
            CancellationSignal cancellationSignal,
            WriteResultCallback callback
        ) {
            if (cancellationSignal.isCanceled()) {
                callback.onWriteCancelled();
                return;
            }

            try (FileOutputStream stream =
                     new FileOutputStream(destination.getFileDescriptor())) {
                stream.write(bytes);
                callback.onWriteFinished(new PageRange[]{PageRange.ALL_PAGES});
            } catch (IOException e) {
                callback.onWriteFailed(e.getMessage());
            }
        }
    }
}
