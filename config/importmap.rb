# Pin npm packages by running ./bin/importmap

pin "application"
# Turbo is what makes data-turbo-permanent work, which is what keeps the audio
# element (and therefore the playing track) alive across navigation. Without it
# every link would be a full page load and the music would stop.
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/scenes", under: "scenes"
pin "three" # @0.186.0

# GLTFLoader imports BufferGeometryUtils by relative path. Pinning only the
# loader leaves that sibling pointing at a vendored location that does not
# exist, the module graph 404s, and the controller silently never registers -
# the canvas simply stays at its default 300x150 and nothing renders.
#
# A trailing-slash prefix pin ("three/addons/") is not emitted here at all, so
# both files are pinned explicitly and vendored under matching paths.
pin "three/addons/loaders/GLTFLoader.js", to: "three/addons/loaders/GLTFLoader.js"
pin "three/addons/utils/BufferGeometryUtils.js", to: "three/addons/utils/BufferGeometryUtils.js"
pin "three8080", to: "three.core.js"
pin "three/addons/utils/SkeletonUtils.js", to: "three/addons/utils/SkeletonUtils.js"
