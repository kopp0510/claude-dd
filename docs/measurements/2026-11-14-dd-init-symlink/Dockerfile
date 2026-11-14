FROM node:22-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends python3-venv && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv /opt/pc && /opt/pc/bin/pip install --no-cache-dir pre-commit==4.6.2 \
 && ln -s /opt/pc/bin/pre-commit /usr/local/bin/pre-commit \
 && git config --system --add safe.directory '*' \
 && git config --system user.email t@example.invalid && git config --system user.name t
