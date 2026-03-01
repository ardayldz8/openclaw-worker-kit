# Publish Steps (GitHub)

## 1) Create repository
- Suggested name: `openclaw-worker-kit`
- Visibility: Public

## 2) Push code
```bash
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## 3) Create tag
```bash
git tag v0.1.0
git push origin v0.1.0
```

## 4) Create GitHub Release
- Tag: `v0.1.0`
- Title: `openclaw-worker-kit v0.1.0`
- Body: copy from `docs/GITHUB_RELEASE_NOTES_V0_1_0.md`

## 5) Post-release smoke check
- Fresh Ubuntu VM
- Run bootstrap
- Run demo job
- Validate health timer and logs
