Grover.configure do |config|
  config.options = {
    # Render the page with a desktop-sized viewport (1920x1200 CSS px) and
    # scale the screenshot down to 640x400. This gives much sharper text than
    # rendering a small viewport at a low device scale factor.
    viewport: {
      width: 1920,
      height: 1200,
      device_scale_factor: 1.0 / 3,
    },

    # Timeout waiting for the page request to finish
    # (Might be possibly be exceeded by a very large TiddlyWiki)
    request_timeout: 40_000,

    # Timeout making the screenshot
    # (Not sure what would cause this to be exceeded)
    convert_timeout: 40_000,

    # Wait for network to be mostly idle.
    wait_until: 'networkidle2',

    # Take the screenshot after 20 seconds no matter what even if
    # networkidle2 was never reached, (I think??).
    wait_for_timeout: 20_000,
  }
end
