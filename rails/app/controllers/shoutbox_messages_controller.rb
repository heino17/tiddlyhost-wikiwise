class ShoutboxMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = ShoutboxMessage.new(shoutbox_message_params)
    @message.user = current_user
  
    respond_to do |format|
      if @message.save
        # created_at ist jetzt garantiert gesetzt
        format.turbo_stream
        format.html { redirect_to explore_path(anchor: "shoutbox-widget") }
      else
        format.turbo_stream
        format.html { redirect_to explore_path }
      end
    end
  end

  def destroy
    @message = ShoutboxMessage.find(params[:id])
    # authorize! :destroy, @message  # falls du CanCanCan nutzt
  
    @message.destroy
  
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to explore_path(anchor: "shoutbox-widget") }
    end
  end
  
  private

  def shoutbox_message_params
    params.require(:shoutbox_message).permit(:message).presence || { message: "" }
  end
end