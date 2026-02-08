package com.mediaview

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.MediaViewManagerInterface
import com.facebook.react.viewmanagers.MediaViewManagerDelegate

@ReactModule(name = MediaViewManager.NAME)
class MediaViewManager : SimpleViewManager<MediaView>(),
  MediaViewManagerInterface<MediaView> {
  private val mDelegate: ViewManagerDelegate<MediaView>

  init {
    mDelegate = MediaViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<MediaView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): MediaView {
    return MediaView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: MediaView?, color: Int?) {
    view?.setBackgroundColor(color ?: Color.TRANSPARENT)
  }

  companion object {
    const val NAME = "MediaView"
  }
}
