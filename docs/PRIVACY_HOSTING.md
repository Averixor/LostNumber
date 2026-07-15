# Хостинг Privacy Policy

Файл **`privacy.html`** лежить у корені репозиторію — це **не** частина гри. Google Play вимагає публічний HTTPS URL.

## Швидкий пакет для хостингу

```bash
npm run privacy:package
# → privacy-host/ (index.html + privacy.html)
```

Завантажте вміст `privacy-host/` на будь-який статичний хост (Netlify Drop, Cloudflare Pages, S3 тощо).

## Варіанти URL

| Варіант | Примітка |
| ------- | -------- |
| `https://averixor.github.io/LostNumber/privacy.html` | Якщо репозиторій публічний і Pages увімкнено |
| Netlify / Vercel / Cloudflare | `npm run privacy:package` → drag-and-drop |
| Власний домен | Скопіюйте `privacy.html` або `privacy-host/` |

URL у Play Console має відкриватися в браузері **до** відправки на перевірку.

## Перевірка

```bash
curl -I https://your-privacy-url/privacy.html
# Очікується HTTP 200
```
