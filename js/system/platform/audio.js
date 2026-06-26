const LN_SFX_FILES = {
  connect: 'audio/sfx/connect.mp3',
  chainComplete: 'audio/sfx/chain-complete.mp3',
  button: 'audio/sfx/button.mp3',
  bonus: 'audio/sfx/bonus.mp3',
  xp: 'audio/sfx/xp.mp3',
  error: 'audio/sfx/error.mp3',
  questComplete: 'audio/sfx/quest-complete.mp3',
  victory: 'audio/sfx/victory.mp3',
};

const LN_MUSIC_FILES = {
  ambient: 'audio/music/ambient.mp3',
  crystalFlow: 'audio/music/Crystal Flow.mp3',
  digitalHorizon: 'audio/music/Digital Horizon.mp3',
  neonDrift: 'audio/music/Neon Drift.mp3',
  stellarLogic: 'audio/music/Stellar Logic.mp3',
};

const LN_VALID_MUSIC_TRACKS = Object.keys(LN_MUSIC_FILES);

function lnAudioUrl(relativePath) {
  const parts = String(relativePath).split('/');
  const file = parts.pop();
  return `${parts.join('/')}/${encodeURIComponent(file)}`;
}

function lnNormalizeVolume(value, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  if (number > 1) return Math.max(0, Math.min(1, number / 100));
  return Math.max(0, Math.min(1, number));
}

class AudioManager {
  constructor() {
    this.soundEnabled = true;
    this.musicEnabled = true;
    this.sfxVolume = 0.5;
    this.musicVolume = 0.3;
    this.musicTrack = 'ambient';

    this.sfx = {};
    this.music = {};
    this._assetsReady = false;
    this._unlocked = false;
    this._currentMusic = null;
    this._currentMusicKey = null;
  }

  init() {
    if (this._assetsReady) return;
    this._assetsReady = true;

    Object.entries(LN_SFX_FILES).forEach(([key, path]) => {
      try {
        const clip = new Audio(lnAudioUrl(path));
        clip.preload = 'auto';
        this.sfx[key] = clip;
      } catch (_) {
        this.sfx[key] = null;
      }
    });

    Object.entries(LN_MUSIC_FILES).forEach(([key, path]) => {
      try {
        const track = new Audio(lnAudioUrl(path));
        track.preload = 'auto';
        track.loop = true;
        this.music[key] = track;
      } catch (_) {
        this.music[key] = null;
      }
    });
  }

  applySettings(settings = {}) {
    if (settings.soundEnabled !== undefined) {
      this.soundEnabled = settings.soundEnabled !== false;
    }
    if (settings.musicEnabled !== undefined) {
      this.musicEnabled = settings.musicEnabled !== false;
    }
    if (settings.sfxVolume !== undefined) {
      this.sfxVolume = lnNormalizeVolume(settings.sfxVolume, this.sfxVolume);
    }
    if (settings.musicVolume !== undefined) {
      this.musicVolume = lnNormalizeVolume(settings.musicVolume, this.musicVolume);
    }
    if (settings.musicTrack !== undefined) {
      const track = String(settings.musicTrack || '');
      this.musicTrack = LN_VALID_MUSIC_TRACKS.includes(track) ? track : 'ambient';
    }

    this._applyMusicVolume();

    if (this.musicEnabled && this._unlocked) {
      this.playMusic(this.musicTrack, true);
    } else {
      this.stopMusic();
    }
  }

  unlock() {
    if (this._unlocked) return;
    this._unlocked = true;
    this.init();
    if (this.musicEnabled) {
      this.playMusic(this.musicTrack, false);
    }
  }

  _ensureUnlocked() {
    if (!this._unlocked) {
      this.unlock();
    } else {
      this.init();
    }
  }

  _getSfxVolume(name) {
    const base = name === 'victory' ? 0.7 : name === 'button' ? 0.45 : 0.55;
    return Math.max(0, Math.min(1, base * this.sfxVolume));
  }

  _applyMusicVolume() {
    const volume = Math.max(0, Math.min(1, this.musicVolume));
    Object.values(this.music).forEach((track) => {
      if (track) track.volume = volume;
    });
  }

  playSound(name) {
    if (!this.soundEnabled) return;
    this._ensureUnlocked();

    const src = this.sfx[name];
    if (!src) return;

    try {
      const clip = src.cloneNode();
      clip.volume = this._getSfxVolume(name);
      clip.currentTime = 0;
      clip.play().catch(() => {});
    } catch (_) {}
  }

  playTap() {
    this.playSound('button');
  }

  playError() {
    this.playSound('error');
  }

  playChainLink() {
    this.playSound('connect');
  }

  playChainComplete() {
    this.playSound('chainComplete');
  }

  playXp() {
    this.playSound('xp');
  }

  playBonus() {
    this.playSound('bonus');
  }

  playQuestComplete() {
    this.playSound('questComplete');
  }

  playVictory() {
    this.playSound('victory');
  }

  playMusic(trackKey, forceRestart = false) {
    if (!this.musicEnabled) return;
    this.init();

    const key = LN_VALID_MUSIC_TRACKS.includes(trackKey) ? trackKey : this.musicTrack || 'ambient';
    const track = this.music[key];
    if (!track) return;

    if (
      !forceRestart &&
      this._currentMusicKey === key &&
      this._currentMusic === track &&
      !track.paused
    ) {
      track.volume = Math.max(0, Math.min(1, this.musicVolume));
      return;
    }

    this.stopMusic();

    this._currentMusic = track;
    this._currentMusicKey = key;
    track.loop = true;
    track.volume = Math.max(0, Math.min(1, this.musicVolume));
    track.currentTime = 0;

    try {
      track.play().catch(() => {});
    } catch (_) {}
  }

  stopMusic() {
    if (this._currentMusic) {
      try {
        this._currentMusic.pause();
        this._currentMusic.currentTime = 0;
      } catch (_) {}
    }
    this._currentMusic = null;
    this._currentMusicKey = null;
  }

  setSoundEnabled(enabled) {
    this.soundEnabled = enabled === true;
  }

  updateSoundStateUI() {
    const iconHost = document.getElementById('footerSoundIcon');
    if (iconHost && typeof LostNumberIcons !== 'undefined') {
      LostNumberIcons.setSlug(iconHost, this.soundEnabled ? 'sound' : 'volume', {
        muted: !this.soundEnabled,
      });
      return;
    }

    const soundBtn = document.getElementById('footerSoundBtn');
    if (soundBtn && typeof LostNumberIcons !== 'undefined') {
      const slot = soundBtn.querySelector('[data-ln-icon]');
      if (slot) {
        LostNumberIcons.setSlug(slot, this.soundEnabled ? 'sound' : 'volume', {
          muted: !this.soundEnabled,
        });
      }
    }
  }
}
