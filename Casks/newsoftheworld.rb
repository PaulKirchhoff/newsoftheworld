cask "newsoftheworld" do
  version "0.1.0"
  sha256 "0db37828f3470e8daa38e6e6e64b5e43469d717a2d3ffa04d77185e7a8f423ee"

  url "https://github.com/PaulKirchhoff/newsoftheworld/releases/download/v#{version}/NewsOfTheWorld-#{version}.dmg"
  name "News of the World"
  desc "Menu-bar news ticker for macOS"
  homepage "https://github.com/PaulKirchhoff/newsoftheworld"

  depends_on macos: ">= :sonoma"

  app "newsoftheworld.app"

  zap trash: [
    "~/Library/Containers/de.paulkirchhoff.newsoftheworld",
    "~/Library/Preferences/de.paulkirchhoff.newsoftheworld.plist",
  ]
end
