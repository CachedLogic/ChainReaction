Pod::Spec.new do |spec|
  spec.name = "ChainReaction"
  spec.version = "1.0.0"
  spec.summary = "Chaining events"
  spec.homepage = "https://github.com/CachedLogic/ChainReaction.git"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Maciej Stramski" => 'mstramski@gmail.com' }
  spec.social_media_url = "http://twitter.com/thoughtbot"

  spec.platform = :ios, "8.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/CachedLogic/ChainReaction.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "ChainReaction/**/*.{h,swift}"
end