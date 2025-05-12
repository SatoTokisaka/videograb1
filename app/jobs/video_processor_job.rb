class VideoProcessorJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    video.update!(status: "processing")

    downloader = VideoDownloaderService.new(video.url)
    info = downloader.metadata

    if info
      video.update!(
        title: info["title"],
        thumbnail: info["thumbnail"]
      )

      # Prepare local download path (temporary)
      tmp_file = Rails.root.join("tmp", "video_#{video.id}.mp4")
      downloader.download(tmp_file)

      # Upload to S3
      s3_key = "videos/video_#{video.id}.mp4"
      s3_url = upload_to_s3(tmp_file, s3_key)

      # Update the video record
      video.update!(
        file_url: s3_url,
        status: "ready"
      )
    else
      video.update!(status: "error")
    end
  rescue => e
    Rails.logger.error("VideoProcessorJob failed: #{e.message}")
    video.update(status: "error") if video
  ensure
    File.delete(tmp_file) if tmp_file && File.exist?(tmp_file)
  end

  private

  def upload_to_s3(file_path, s3_key)
    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    bucket = s3.bucket(ENV["AWS_BUCKET"])

    obj = bucket.object(s3_key)
    obj.upload_file(file_path, acl: "public-read")
    obj.public_url
  end
end
