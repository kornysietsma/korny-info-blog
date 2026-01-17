# Korny's blog

This is the repo for https://blog.korny.info

It's a Jekyll / Minimal Mistakes blog - moved from Middelman in 2023, still needs a lot of tweaks, this is a MVP release.

## Dev notes

really just notes for me.

Build locally with `./run-locally.sh` (this works around OpenSSL 3.x SSL certificate issues with jekyll-remote-theme)

Then open <http://localhost:4000/>

I've set up `.ruby-version` so you should be able to install `rbenv` on a new machine, then `gem install bundler` etc.

Note I fixed it to ruby 3.2.3 as 3.3.0 causes pain - see [this fun article](https://ritviknag.com/tech-tips/ruby-versioning-hell-with-jekyll-&-github-pages/)
