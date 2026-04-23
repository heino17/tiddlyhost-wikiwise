class BannerController < ApplicationController
  def dismiss
    session[:banner_dismissed] = true
    head :ok
  end
end