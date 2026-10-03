package org.godotengine.godot.plugin;

import android.app.Activity;
import java.util.Collections;
import java.util.Set;
import org.godotengine.godot.Godot;

/** Мінімальний stub для CodeQL / CI без godot-lib.aar. */
public abstract class GodotPlugin {
	public GodotPlugin(Godot godot) {}

	public abstract String getPluginName();

	public Set<SignalInfo> getPluginSignals() {
		return Collections.emptySet();
	}

	public Activity getActivity() {
		return null;
	}

	public void onGodotSetupCompleted() {}

	/** No-op stub: реальний GodotPlugin емітить сигнал у engine. */
	protected void emitSignal(String signalName, Object... signalArgs) {}
}
