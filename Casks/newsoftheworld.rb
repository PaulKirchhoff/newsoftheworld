cask "newsoftheworld" do
  version "0.1.1"
  sha256 "c03f3fafd8f3803dc9f263ace62615e96df35e80706f105fe64bc08fb23b3d52"

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
