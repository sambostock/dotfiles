def shopify?
  ENV.key?('SHOPIFY')
end

brew "git"
brew "tree"

# TODO: Add vim? Neovim? Macvim?

cask "google-chrome" unless shopify?
cask "signal"
