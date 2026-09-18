# Pin npm packages by running ./bin/importmap

pin "application"
# Turbo is what makes data-turbo-permanent work, which is what keeps the audio
# element (and therefore the playing track) alive across navigation. Without it
# every link would be a full page load and the music would stop.
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
