source "https://rubygems.org"

gemspec

group :development do
  # Integration testing gems.
  gem "kitchen-cinc-auditor", git: "https://github.com/test-kitchen/kitchen-cinc-auditor.git"
  gem "cinc-auditor-bin", source: "https://rubygems.cinc.sh"
  gem "kitchen-cinc"
  gem "train", ">= 2.1", "< 4.0" # validate 4.x when it's released
end

group :test do
  gem "rake"
  gem "rspec", "~> 3.2"
  gem "rspec-its", "~> 2.0"
end

group :cookstyle do
  gem "cookstyle"
end
