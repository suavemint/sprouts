# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( animate.min.css )
Rails.application.config.assets.precompile += %w(bootstrap-theme.min.css)
Rails.application.config.assets.precompile += %w(bootstrap-min.css)
Rails.application.config.assets.precompile += %w( effects.css )
Rails.application.config.assets.precompile += %w(font-awesome-min.css)
Rails.application.config.assets.precompile += %w( linear-fonts.css )
Rails.application.config.assets.precompile += %w(magnific-popup.css)
Rails.application.config.assets.precompile += %w( responsive.css )
Rails.application.config.assets.precompile += %w( style.css )

Rails.application.config.assets.precompile += %w( bootstrap.min.js )
Rails.application.config.assets.precompile += %w( jquery.magnific-popup.min.js )
Rails.application.config.assets.precompile += %w( jquery.min.js )
Rails.application.config.assets.precompile += %w( jquery.mixitup.js )
Rails.application.config.assets.precompile += %w( jquery.stellar.min.js )
Rails.application.config.assets.precompile += %w( npm.js )
Rails.application.config.assets.precompile += %w( owl.carousel.min.js )
Rails.application.config.assets.precompile += %w( scripts.js )
Rails.application.config.assets.precompile += %w( smoth-scroll.js )
Rails.application.config.assets.precompile += %w( wow.min.js )
