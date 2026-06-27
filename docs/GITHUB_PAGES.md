# GitHub Pages — увімкнення та деплой

Workflow: `.github/workflows/pages.yml`  
Сайт після деплою: `https://averixor.github.io/LostNumber/`

## Помилка `Get Pages site failed` / `Not Found`

REST API Pages для репозиторію повертає **404**, бо сайт не створено.

### Головна причина (LostNumber)

Репозиторій **private**, а на поточному плані GitHub **немає Pages для приватних репо**:

```text
HTTP 422: Your current plan does not support GitHub Pages for this repository.
```

`actions/configure-pages` не зможе увімкнути Pages, поки не зміниться план або видимість репо.

**Варіанти:**

| Варіант                    | Дія                                                                      |
| -------------------------- | ------------------------------------------------------------------------ |
| **A. Public repo**         | Settings → General → Change visibility → **Public** (безкоштовний Pages) |
| **B. GitHub Pro / Team**   | Платний план з Pages для private repos                                   |
| **C. Окремий public repo** | Напр. `LostNumber-pages` лише для `_site/`                               |
| **D. Інший хост privacy**  | Netlify / Cloudflare Pages — для URL у Play Console                      |

### Після A або B

1. **Settings → Pages → Build and deployment → Source: GitHub Actions**
2. **Settings → Actions → General → Workflow permissions: Read and write**
3. Перезапустити workflow:

```bash
gh workflow run pages.yml
```

У workflow вже є `enablement: true` і **Node 24** (замість застарілого Node 20 на раннерах).

## Перевірка статусу

```bash
gh api repos/Averixor/LostNumber --jq '.private, .has_pages'
gh api repos/Averixor/LostNumber/pages 2>&1 | head -5
```

## Що деплоїться

`npm run build:pages` → `_site/` (гра + `privacy.html` для Play Store).

## Якщо Pages недоступний

Для Google Play можна тимчасово вказати privacy policy на іншому URL (див. варіант D у [PLAY_STORE.md](./PLAY_STORE.md)), поки не зʼявиться `averixor.github.io/LostNumber/privacy.html`.
