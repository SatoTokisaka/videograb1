require "aws-sdk-s3"

class DeleteVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find_by(id: video_id)
    return unless video

    begin
      # Delete from S3
      if video.file_url.present?
        s3 = Aws::S3::Resource.new
        bucket = ENV["AWS_S3_BUCKET"]

        # Extract key from the file_url
        uri = URI(video.file_url)
        key = uri.path.sub(%r{^/}, "") # remove leading slash

        obj = s3.bucket(bucket).object(key)
        obj.delete
      end

      video.destroy
      Rails.logger.info "Deleted video ##{video.id} and its S3 file after 10 minutes"
    rescue => e
      Rails.logger.error "DeleteVideoJob failed for video ##{video.id}: #{e.message}"
    end
  end
end
