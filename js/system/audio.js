class AudioManager {
  constructor() {
    this.soundEnabled = true;
    this.music = null;
    this.tapSound = null;
    this.musicInitialized = false;
  }

  init() {
    if (this.musicInitialized) return;
    this.musicInitialized = true;

    try {
      this.music = new Audio('audio/music/ambient.mp3');
      this.music.loop = true;
      this.music.volume = 0.35;
    } catch (e) {
      this.music = null;
    }

    try {
      this.tapSound = new Audio('audio/sfx/tap.mp3');
      this.tapSound.volume = 0.45;
    } catch (e) {
      this.tapSound = null;
    }
  }

  playTap() {
    if (!this.soundEnabled || !this.tapSound) return;
    try {
      const clone = this.tapSound.cloneNode();
      clone.volume = this.tapSound.volume;
      clone.play().catch(() => {});
    } catch (e) {}
  }

  playMusic() {
    if (!this.soundEnabled || !this.music) return;
    try {
      if (this.music.paused) {
        this.music.play().catch(() => {});
      }
    } catch (e) {}
  }

  pauseMusic() {
    if (!this.music) return;
    try {
      if (!this.music.paused) {
        this.music.pause();
      }
    } catch (e) {}
  }

  setSoundEnabled(enabled) {
    this.soundEnabled = enabled;
    if (!enabled) {
      this.pauseMusic();
    } else {
      this.playMusic();
    }
  }

  updateSoundStateUI() {
    const soundBtn = document.getElementById('footerSoundBtn');
    if (soundBtn) {
      const iconSpan = soundBtn.querySelector('span');
      if (iconSpan) {
        iconSpan.textContent = this.soundEnabled
          ? I18N[window.game?.lang || 'ua']?.icon_sound_on || '🔊'
          : I18N[window.game?.lang || 'ua']?.icon_sound_off || '🔇';
      }
    }
  }
}
