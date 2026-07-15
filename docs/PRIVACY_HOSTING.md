# Хостинг Privacy Policy

Файл **`privacy.html`** лежить у корені репозиторію — це **не** частина гри. Google Play вимагає публічний HTTPS URL.

## GitHub Pages (рекомендовано)

Після push у **`main`** workflow [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) автоматично:

1. Запускає `npm run privacy:package` → `privacy-host/`
2. Публікує лише `privacy.html`, `index.html` (редirect) та `.nojekyll`

**Не** деплоїться веб-гра (`index.html` гри, `js/`, `css/`).

| URL                                                  | Призначення                          |
| ---------------------------------------------------- | ------------------------------------ |
| `https://averixor.github.io/LostNumber/privacy.html` | Privacy Policy для Play Console      |
| `https://averixor.github.io/LostNumber/`             | Редirect на `privacy.html`           |

Потрібен публічний репозиторій і увімкнений GitHub Pages (джерело: **GitHub Actions**).

## Швидкий пакет для іншого хостингу

```bash
npm run privacy:package
# → privacy-host/ (index.html + privacy.html)
```

Завантажте вміст `privacy-host/` на будь-який статичний хост (Netlify Drop, Cloudflare Pages, S3 тощо), якщо не використовуєте GitHub Pages.

## Варіанти URL

| Варіант                                              | Примітка                                     |
| ---------------------------------------------------- | -------------------------------------------- |
| `https://averixor.github.io/LostNumber/privacy.html` | Автодеплой з `main` через GitHub Actions     |
| Netlify / Vercel / Cloudflare                        | `npm run privacy:package` → drag-and-drop    |
| Власний домен                                        | Скопіюйте `privacy.html` або `privacy-host/` |

URL у Play Console має відкриватися в браузері **до** відправки на перевірку.

## Перевірка

```bash
curl -I https://your-privacy-url/privacy.html
# Очікується HTTP 200
```

Після змін у `privacy.html` — merge у `main`; деплой зазвичай завершується за кілька хвилин.
