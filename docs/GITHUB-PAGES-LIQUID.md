<!-- {% raw %} -->

# 🌐 GitHub Pages + Liquid: Avoiding Template Collisions

GitHub Pages builds your repository with **Jekyll**, which uses the **Liquid** templating language.
Oh My Posh themes and documentation often include **Go template** snippets like:

```text
{{ .Path }}
{{ if .Error }}...{{ end }}
```

Unfortunately, Liquid also treats `{{ ... }}` as templates, which can break the Pages build.

## ✅ The Fix We Use

For any Markdown file that contains Oh My Posh template snippets (`{{ ... }}`), we wrap the file in Liquid “raw” guards so Jekyll renders the text _literally_:

```html
<!-- {% raw %} -->
...markdown that contains {{ ... }}...
<!-- {% endraw %} -->
```

### Why the HTML comments?

- GitHub Pages/Jekyll still sees `{% raw %}` / `{% endraw %}` even inside HTML comments.
- GitHub’s normal README renderer won’t show those lines.

## 🧾 Which files need this?

Any `.md` file that includes Oh My Posh templates (especially `{{ ... }}`) should use the wrapper.

Common examples:

- Theme docs with template examples
- Guides that show segment `template` strings
- CHANGELOG entries containing prompt templates

## 🧰 git-cliff (CHANGELOG) note

`git-cliff` regenerates `CHANGELOG.md`. To avoid re-breaking Pages, our `cliff.toml` adds the same raw guards in the generated header/footer.

If you create a new changelog template/config, keep the raw guards.

---

If Pages fails again with a Liquid error, search for `{{` in `.md` files and add the wrapper.

<!-- {% endraw %} -->
