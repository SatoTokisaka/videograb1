class VideosController < ApplicationController
  before_action :set_video, only: %i[show edit update destroy]

  # GET /videos or /videos.json
  def index
    @videos = Video.all
  end

  # GET /videos/1 or /videos/1.json
  def show
    # Removed redundant line: @video = Video.find(params[:id])
  end

  # POST /videos or /videos.json
  def create
    @video = Video.new(video_params)
    @video.status = "processing"

    if @video.save
      VideoProcessorJob.perform_later(@video.id)

      DeleteVideoJob.set(wait: 5.minutes).perform_later(@video.id)

      redirect_to @video, notice: "Processing started...."
    else
      render :new
    end
  end

# videos_controller.rb
def download_video
  video = Video.find(params[:id])
  url = video.presigned_url_for

  if url
    redirect_to url
  else
    redirect_to video_path(video), alert: "Video not available."
  end
end


def status
  @video = Video.find(params[:id])
  render json: { status: @video.status, id: @video.id }
end

  # GET /videos/new
  def new
    @video = Video.new
  end

  # GET /videos/1/edit
  def edit
  end

  # PATCH/PUT /videos/1 or /videos/1.json
  def update
    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to @video, notice: "Video was successfully updated." }
        format.json { render :show, status: :ok, location: @video }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1 or /videos/1.json
  def destroy
    @video.destroy!

    respond_to do |format|
      format.html { redirect_to videos_path, status: :see_other, notice: "Video was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_video
    @video = Video.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def video_params
    params.require(:video).permit(:url)
  end
end
