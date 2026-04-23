class AdminCommentsViewController < AdminController
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.turbo_stream   # sucht destroy.turbo_stream.erb
      format.html { redirect_to admin_comments_list_path, notice: "Kommentar gelöscht." }
    end
  end
end
