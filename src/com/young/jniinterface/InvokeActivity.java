package com.young.jniinterface;

import android.app.Activity;
import android.os.Bundle;

public class InvokeActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_downcall);
    }
}
