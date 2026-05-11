version := '595.71.05'

help:
    just --list

# Fetch amd64 and arm64 NVIDIA drivers and validate their checksums.
update: clean (fetch 'x86_64' 'amd64' '36203b8960b7e49c8a42f6ba1f5863cde34a05e93d2b24b798af06dd846f6b82') (fetch 'aarch64' 'arm64' '5f32a5a12d347452937780135a44c8866f5e1bf3b347f4a29ba31ba0d6563eef')

clean:
    mkdir -p amd64 arm64
    find amd64/*.run ! -wholename '*{{ version }}.run' -exec rm {} \; || true
    find arm64/*.run ! -wholename '*{{ version }}.run' -exec rm {} \; || true
    rm -rf .pc NVIDIA-Linux* LICENSE.txt

# Construct the `target-dst` variable and then run the `pre-validate`, `download`, and `post-validate` recipes.
[private]
fetch arch target-dir shasum: (post-validate arch shasum target-dir target-dir / 'NVIDIA-Linux-' + arch + '-' + version + '.run')

# Download driver if its file does not exist.
[private]
download arch shasum target-dir target-dst: (pre-validate target-dst shasum)
    #!/bin/env bash
    set -euo pipefail
    mkdir -p {{ target-dir }}
    ARCH=$(test {{ arch }} = aarch64 && echo {{ arch }} || echo Linux-{{ arch }})
    test -e {{ target-dst }} || curl -o {{ target-dst }} "https://us.download.nvidia.com/XFree86/${ARCH}/{{ version }}/NVIDIA-Linux-{{ arch }}-{{ version }}.run"

# Remove file on checksum mismatch and continue.
[private]
pre-validate target-dst shasum:
    #!/bin/env bash
    set -euo pipefail
    test -e {{ target-dst }} && (test '{{ shasum }}' = "$(sha256sum {{ target-dst }} | cut -d' ' -f1)" || rm {{ target-dst }}) || true

# Error on checksum mismatch or missing file.
[private]
post-validate arch shasum target-dir target-dst: (download arch shasum target-dir target-dst)
    #!/bin/env bash
    set -euo pipefail
    test -e {{ target-dst }} && test '{{ shasum }}' = "$(sha256sum {{ target-dst }} | cut -d' ' -f1)"
