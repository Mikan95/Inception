#!/bin/sh

# Immediate exit if a command fails
set -e

# ── Install WP if not installed ──────────────────────────────────────────────────────────────
if [ ! wp core is-installed --alow-root 2>/dev/null ]; then
	echo ">>> Installing Wordpress..."

	wp core install

fi