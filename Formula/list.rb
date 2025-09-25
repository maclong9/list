class List < Formula
  desc "A CLI tool for listing items"
  homepage "https://github.com/maclong9/list"
  url "https://github.com/maclong9/list/releases/download/v1.3.0/list-darwin-arm64"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  version "1.3.0"

  def install
    bin.install "list"
  end

  test do
    system "#{bin}/list", "--version"
  end
end


