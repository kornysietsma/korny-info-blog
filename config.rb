###
# Livereload
###

activate :livereload

Time.zone = "GMT"

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

set :build_dir, 'docs'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  #TODO: activate :minify_css

  # Minify Javascript on build
  #TODO: activate :minify_javascript

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  # activate :relative_assets

  # Compress PNGs after build
  # require 'middleman-smusher'
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"

end

#  activate :syntax, :line_numbers => true
 activate :syntax

set :haml, { ugly: true }

  set :markdown_engine, :kramdown
#  set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :blog do |blog|
  blog.tag_template = "tag.html"
  blog.layout = "article"
  # set options on blog
#  blog.taglink = "categories/{tag}.html"
end
page "/feed.xml", :layout => false
page "/clojure-feed.xml", :layout => false
