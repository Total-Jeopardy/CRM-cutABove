#!/usr/bin/env bash
# Netlify / CI: web release. Override SUPABASE_ANON_KEY in env if needed.
set -euo pipefail
cd "$(dirname "$0")/.."

_default_anon='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtZnV1YnFiandydHJobmFkdmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MzY4MjEsImV4cCI6MjA5MTUxMjgyMX0.KKAYr_TM4f5PBLW8mCxCX3mJEuuD9ZeDiggJJPIAsfU'
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-$_default_anon}"

flutter build web --release --base-href "/" \
  --dart-define=SUPABASE_URL=https://fmfuubqbjwrtrhnadvfy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSyDHboHy5SUMn6NRgs6MdnOvEVjHRweimho
