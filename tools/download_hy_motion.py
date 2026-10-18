"""Download official HY-Motion weights and its text encoders into ignored local storage."""
import json
import os
from pathlib import Path
from huggingface_hub import HfApi, snapshot_download

root = Path(__file__).resolve().parents[1]
runtime = root / '.runtime'
models = runtime / 'models'
models.mkdir(parents=True, exist_ok=True)
os.environ.setdefault('HF_HUB_DISABLE_SYMLINKS_WARNING', '1')
api = HfApi()
manifest = {}
for repo, subdir, patterns in [
    ('tencent/HY-Motion-1.0', 'tencent', ['HY-Motion-1.0/*', 'LICENSE*', 'License*', 'README.md']),
    ('Qwen/Qwen3-8B', 'Qwen3-8B', ['*.json', '*.safetensors', 'merges.txt', 'vocab.json', '*.jinja', 'LICENSE*']),
    ('openai/clip-vit-large-patch14', 'clip-vit-large-patch14', ['config.json', 'tokenizer*', 'special_tokens_map.json', 'vocab.json', 'merges.txt', 'model.safetensors']),
]:
    revisions = {
        'tencent/HY-Motion-1.0':'620dd559f8d964aac2f82f1204fe6a35ad8ad14d',
        'Qwen/Qwen3-8B':'b968826d9c46dd6066d109eabc6255188de91218',
        'openai/clip-vit-large-patch14':'32bd64288804d66eefd0ccbe215aa642df71cc41',
    }
    info = api.model_info(repo, revision=revisions[repo], files_metadata=True)
    import fnmatch
    matched = [s for s in info.siblings if any(fnmatch.fnmatch(s.rfilename, p) for p in patterns)]
    total = sum(s.size or 0 for s in matched)
    print(f'DOWNLOAD {repo} revision={info.sha} bytes={total}', flush=True)
    destination = models / subdir
    snapshot_download(repo, revision=info.sha, allow_patterns=patterns, local_dir=destination, max_workers=4)
    manifest[repo] = {'revision': info.sha, 'bytes': total, 'local_dir': str(destination)}
    (runtime / 'model_sources.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'READY {repo}', flush=True)
print('ALL MODEL DOWNLOADS COMPLETE', flush=True)
