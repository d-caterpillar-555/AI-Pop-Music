#!/usr/bin/env bash
# Restart the dev server cleanly and prove the Blender asset is actually served.
#
# Exists because two failures looked identical from the browser: a stale server
# keeps serving changed files through Propshaft while still handing out the
# importmap it loaded at boot. Killing by port and verifying is the only way to
# be sure the restart happened.

set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1

for pid in $(lsof -ti tcp:5000 2>/dev/null); do
  kill -9 "$pid" 2>/dev/null
done
sleep 2
echo "listeners left on 5000: $(lsof -ti tcp:5000 2>/dev/null | wc -l)"

# Subdirectories of app/assets are not added to the asset path automatically.
if ! grep -q "app/assets/models" config/initializers/assets.rb 2>/dev/null; then
  mkdir -p config/initializers
  cat >> config/initializers/assets.rb <<'RUBY'

# Blender-baked models live here.
Rails.application.config.assets.paths << Rails.root.join("app/assets/models")
RUBY
  echo "asset path added"
fi

setsid nohup mise exec -- bin/rails server -p 5000 -b 0.0.0.0 > /tmp/rails.log 2>&1 < /dev/null &
sleep 18

echo "up:         $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:5000/up)"
echo "glb:        $(curl -s -o /dev/null -w '%{http_code} %{size_download}b' http://127.0.0.1:5000/assets/exploded_guitar.glb)"
echo "addons pin: $(curl -s http://127.0.0.1:5000/lab | grep -c 'three/addons')"

echo "--- boot errors ---"
grep -iE "error|cannot|excluded" /tmp/rails.log | head -5
