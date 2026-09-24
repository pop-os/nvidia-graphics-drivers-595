version := '595.104.02'

help:
    just --list

# Fetch amd64 and arm64 NVIDIA drivers and validate their checksums.
update: clean \
    (fetch 'aarch64' 'arm64' '3da7d2b66c0d32e7de0e9dd5b694c6182a16fb9dc6a2bfe689e3b59b5a48ee02') \
    (fetch 'x86_64' 'amd64' 'e421c202e4c79f58c3c7f3161bbe71454ebb3d88936f88205a0e327cd04c59ca')

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
