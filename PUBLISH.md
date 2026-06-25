# GitHub Pages — Avatar Engine

Контракт: `~/6sns-ai/6sns-design flow/.claude/agents/publish-agent.md`

```yaml
publish_type: html-file
github_owner: 6sns
pages_base_url: https://6sns.github.io
publish:
  target: github-pages
  org: 6sns
  repo: site-avatar-engine
  url: https://6sns.github.io/site-avatar-engine/
```

Тип `html-file` / `html-landing` → префикс репозитория `site-`.

Git config при deploy:

- `user.name`: 6sns
- `user.email`: 6sns@users.noreply.github.com

```bash
./build.sh
./deploy.sh --check
./deploy.sh
```
