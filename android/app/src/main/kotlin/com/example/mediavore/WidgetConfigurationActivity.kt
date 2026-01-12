package com.example.mediavore

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray

class WidgetConfigurationActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var isWatchNext = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.widget_config)

        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val appWidgetManager = AppWidgetManager.getInstance(this)
        val info = appWidgetManager.getAppWidgetInfo(appWidgetId)
        val className = info?.provider?.className ?: ""
        isWatchNext = className.contains("WatchNext")

        val rootLayout = findViewById<View>(R.id.config_root)
        val header = findViewById<TextView>(R.id.config_header)
        val listSection = findViewById<View>(R.id.config_list_section)
        val listSpinner = findViewById<Spinner>(R.id.config_list_spinner)
        val modeGroup = findViewById<RadioGroup>(R.id.config_mode_group)
        val gridSection = findViewById<View>(R.id.config_grid_cols_section)
        val gridLabel = findViewById<TextView>(R.id.config_grid_cols_label)
        val gridSeekBar = findViewById<SeekBar>(R.id.config_grid_cols_seekbar)
        val hideUnreleased = findViewById<CheckBox>(R.id.config_hide_unreleased)
        val saveButton = findViewById<Button>(R.id.config_save_button)

        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        // SYNC THEME
        val bgColor = prefs.getString("theme_primary_bg", "#121212") ?: "#121212"
        val accentColor = prefs.getString("theme_accent", "#4CAF50") ?: "#4CAF50"
        val textColor = prefs.getString("theme_text_primary", "#FFFFFF") ?: "#FFFFFF"
        
        try {
            rootLayout.setBackgroundColor(Color.parseColor(bgColor))
            header.setTextColor(Color.parseColor(textColor))
            gridLabel.setTextColor(Color.parseColor(textColor))
            hideUnreleased.setTextColor(Color.parseColor(textColor))
            val accentInt = Color.parseColor(accentColor)
            saveButton.backgroundTintList = ColorStateList.valueOf(accentInt)
            hideUnreleased.buttonTintList = ColorStateList.valueOf(accentInt)
            gridSeekBar.progressTintList = ColorStateList.valueOf(accentInt)
            gridSeekBar.thumbTintList = ColorStateList.valueOf(accentInt)
            for (i in 0 until modeGroup.childCount) {
                val rb = modeGroup.getChildAt(i) as RadioButton
                rb.setTextColor(Color.parseColor(textColor))
                rb.buttonTintList = ColorStateList.valueOf(accentInt)
            }
        } catch (e: Exception) {}

        if (isWatchNext) {
            header.text = "Watch Next Config"
            listSection.visibility = View.GONE
            findViewById<View>(R.id.config_mode_section).visibility = View.GONE
            gridSection.visibility = View.GONE
            hideUnreleased.visibility = View.GONE 
        } else {
            header.text = "Shelf Config"
            val listsJson = prefs.getString("available_lists", "[\"watchlist\"]")
            val listsArray = JSONArray(listsJson)
            val lists = mutableListOf<String>()
            for (i in 0 until listsArray.length()) { lists.add(listsArray.getString(i)) }
            
            val adapter = object : ArrayAdapter<String>(this, android.R.layout.simple_spinner_item, lists) {
                override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val v = super.getView(position, convertView, parent) as TextView
                    v.setTextColor(Color.parseColor(textColor))
                    return v
                }
                override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val v = super.getDropDownView(position, convertView, parent) as TextView
                    v.setTextColor(Color.WHITE)
                    v.setBackgroundColor(Color.parseColor("#333333"))
                    return v
                }
            }
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            listSpinner.adapter = adapter
            val currentList = prefs.getString("shelf_list_name_$appWidgetId", "watchlist")
            val listIndex = lists.indexOf(currentList)
            if (listIndex >= 0) listSpinner.setSelection(listIndex)

            // Setup Grid Seekbar
            gridSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    val cols = progress + 2
                    gridLabel.text = "Grid Columns ($cols)"
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })

            modeGroup.setOnCheckedChangeListener { _, checkedId ->
                gridSection.visibility = if (checkedId == R.id.radio_grid) View.VISIBLE else View.GONE
            }
        }

        val currentMode = prefs.getInt("shelf_display_mode_$appWidgetId", 0)
        val currentCols = prefs.getInt("shelf_grid_columns_$appWidgetId", 3)
        val currentHide = prefs.getBoolean("shelf_hide_unreleased_$appWidgetId", false)
        
        when (currentMode) {
            0 -> modeGroup.check(R.id.radio_list)
            1 -> modeGroup.check(R.id.radio_grid)
        }
        gridSeekBar.progress = currentCols - 2
        gridLabel.text = "Grid Columns ($currentCols)"
        gridSection.visibility = if (currentMode == 1) View.VISIBLE else View.GONE
        hideUnreleased.isChecked = currentHide

        saveButton.setOnClickListener {
            val editor = prefs.edit()
            val selectedMode = if (modeGroup.checkedRadioButtonId == R.id.radio_grid) 1 else 0

            if (!isWatchNext) {
                val selectedList = listSpinner.selectedItem?.toString() ?: "watchlist"
                editor.putString("shelf_list_name_$appWidgetId", selectedList)
                editor.putInt("shelf_display_mode_$appWidgetId", selectedMode)
                editor.putInt("shelf_grid_columns_$appWidgetId", gridSeekBar.progress + 2)
                editor.putBoolean("shelf_hide_unreleased_$appWidgetId", hideUnreleased.isChecked)
            }
            editor.apply()

            val providerClass = if (isWatchNext) WatchNextWidgetProvider::class.java else ShelfWidgetProvider::class.java
            val updateIntent = Intent(this, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            sendBroadcast(updateIntent)

            val resultValue = Intent().apply { putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId) }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}
