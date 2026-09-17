# Hermes Agent with the two tools the shared data store expects an agent to have.
#
# The upstream image is complete for its own purposes: it ships Chromium, curl, git, node
# and a Python venv. What it does not ship is a way to READ the files an agent is handed,
# and the data store's rules put that squarely on the agent: register the document, then
# publish what it SAYS, keeping the source's own section numbers. An agent with no text
# extractor reaches for the only thing it can think of. Measured 2026-09-16: given a
# 159 KB quality manual, an agent started OCR, spent minutes on it, and was interrupted --
# for a born-digital PDF that pdftotext reads in about fifty milliseconds.
#
#   poppler-utils  pdftotext, pdfinfo, pdftoppm. Born-digital PDFs -- which is nearly all
#                  of them -- become text without a model, a GPU or a round trip.
#   openpyxl       xlsx into the venv Hermes' own tools use. The store's loader takes CSV
#                  (skillhub_load_file), so a spreadsheet has to be converted before it can
#                  be handed over, and this is what converts it.
#
# Deliberately NOT here: tesseract. It is the right tool for a SCANNED page and the wrong
# first instinct for everything else, it costs about 100 MB with its language data, and
# having it available is how an agent ends up using it on a PDF that already holds text.
# Add it the day a scanned document actually turns up.
#
# apt is used at BUILD time on purpose. Packages installed at runtime live in the container
# layer, which Easypanel replaces on every Deploy -- the same lesson openclaw-easy learned.
# Anything durable belongs here; anything an agent installs for itself belongs on the volume.
#
# Bump the base by setting HERMES_TAG in the Easypanel env panel and redeploying. Easypanel
# rebuilds this image and pulls the new base.

ARG HERMES_TAG=latest
FROM nousresearch/hermes-agent:${HERMES_TAG}

# The base image already runs as root (Hermes drops to its own user itself where it needs
# to). Stated anyway, so a later base that changes this does not silently change what apt
# can do here.
USER root

# Debian 13 (trixie) base. --no-install-recommends keeps this at about 2 MB of the 20 the
# recommends would drag in.
RUN apt-get update \
    && apt-get install -y --no-install-recommends poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# /opt/hermes/.venv is the interpreter Hermes' own tools run in, and it was built with uv,
# so it has no pip: ensurepip puts one there first. Installing anywhere else would put
# openpyxl on a path the agent's Python never looks at.
RUN /opt/hermes/.venv/bin/python3 -m ensurepip --upgrade \
    && /opt/hermes/.venv/bin/python3 -m pip install --no-cache-dir openpyxl

# Fail the build rather than the agent: a missing tool discovered at build time is a red
# deploy, and discovered at runtime it is an agent improvising for twenty minutes.
RUN pdftotext -v 2>&1 | head -1 \
    && /opt/hermes/.venv/bin/python3 -c "import openpyxl; print('openpyxl', openpyxl.__version__)"

# Nothing else changes: the base image's entrypoint, workdir and environment stand as they
# are, including PLAYWRIGHT_BROWSERS_PATH=/opt/hermes/.playwright.
