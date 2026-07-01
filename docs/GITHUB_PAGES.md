# GitHub Pages — увімкнення та деплой

Workflow: `.github/workflows/pages.yml` (деплой, лише якщо Pages увімкнено)  
Перевірки якості: `.github/workflows/ci.yml` (`npm run release:check` на кожному push/PR)  
Сайт після деплою: `https://averixor.github.io/LostNumber/`

## Чому «не працює» (LostNumber зараз)

Перевірка API (стан репозиторію):

```bash
gh api repos/Averixor/LostNumber --jq '{private: .private, has_pages: .has_pages}'
curl -sI https://averixor.github.io/LostNumber/privacy.html | head -1
```

Типовий результат:

| Перевірка   | Значення      | Наслідок                                            |
| ----------- | ------------- | --------------------------------------------------- |
| `private`   | `true`        | GitHub Pages **заблоковано** на безкоштовному плані |
| API Pages   | `422` / `404` | Workflow не може увімкнути сайт автоматично         |
| privacy URL | `HTTP/2 404`  | Play Console URL **не відкривається**               |

**Зміна `pages.yml` у коді це не виправляє** — потрібна дія в GitHub (public repo / Pro) або інший хостинг.

## Очікувана поведінка (private repo без Pages)

Якщо Pages **не увімкнено**, workflow `pages.yml` на push у `main`:

- **не падає** — job `build` / `deploy` пропускаються (`if: enabled == true`);
- у summary run з’являється **одне повідомлення** (notice), не помилка;
- **`ci.yml` працює як завжди** — `npm run release:check`.

Це нормально, поки репозиторій private на безкоштовному плані GitHub.

## Помилка `Get Pages site failed` / `Not Found`

REST API Pages для репозиторію повертає **404**, бо сайт не створено.

### Головна причина (LostNumber)

Репозиторій **private**, а на поточному плані GitHub **немає Pages для приватних репо**:

```text
HTTP 422: Your current plan does not support GitHub Pages for this repository.
```

`actions/configure-pages` не зможе увімкнути Pages, поки не зміниться план або видимість репо. Workflow **не падає**: крок деплою пропускається, а **`ci.yml` продовжує запускати `release:check`**.

**Варіанти:**

| Варіант                    | Дія                                                                      |
| -------------------------- | ------------------------------------------------------------------------ |
| **A. Public repo**         | Settings → General → Change visibility → **Public** (безкоштовний Pages) |
| **B. GitHub Pro / Team**   | Платний план з Pages для private repos                                   |
| **C. Окремий public repo** | Напр. `LostNumber-pages` лише для `_site/`                               |
| **D. Інший хост privacy**  | Netlify / Cloudflare Pages — для URL у Play Console                      |

### Після A або B

1. **Settings → General → Change visibility → Public** (якщо обрали A)
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**
3. **Settings → Actions → General → Workflow permissions: Read and write**
4. Перезапустити workflow:

```bash
gh workflow run pages.yml
```

У workflow Pages використовується **Node 24** (замість застарілого Node 20 на раннерах). `enablement: true` прибрано — автостворення Pages через `GITHUB_TOKEN` на private/free плані дає `Resource not accessible by integration`.

## Перевірка статусу

```bash
gh api repos/Averixor/LostNumber --jq '.private, .has_pages'
gh api repos/Averixor/LostNumber/pages 2>&1 | head -5
```

## Що деплоїться

`npm run build:pages` → `_site/` (гра + `privacy.html` для Play Store).

## Якщо Pages недоступний — швидкий обхід для Play Store

Потрібен **будь-який публічний HTTPS URL** на `privacy.html`. Без public repo на GitHub:

```bash
npm run privacy:package
```

Папка **`privacy-host/`** → перетягніть на [Netlify Drop](https://app.netlify.com/drop) → отримаєте URL на кшталт  
`https://random-name.netlify.app/privacy.html` — вкажіть його в Play Console замість `averixor.github.io`.

Після появи GitHub Pages можна повернути URL на  
`https://averixor.github.io/LostNumber/privacy.html`.

## Якщо Pages недоступний (довгостроково)
