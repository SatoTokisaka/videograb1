class Video < ApplicationRecord
  validates :url, presence: true
  validate :valid_video_url

  # Returns the full S3 URL for the base or quality-specific file
  def file_url_for(quality = nil)
    return file_url if file_url.blank? || quality.blank?

    uri = URI.parse(file_url)
    base = File.basename(uri.path, ".mp4")
    ext  = File.extname(uri.path)
    dir  = File.dirname(uri.path)

    uri.path = "#{dir}/#{base}_#{quality}#{ext}"
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  # Sanitizes the video title to generate a safe downloadable filename
  def filename_from_metadata
    info = metadata
    return "video_#{id}.mp4" unless info&.dig("title")

    sanitized = info["title"].gsub(/[^0-9A-Za-z.\- ]/, "_").gsub(/\s+/, "_")
    "#{sanitized}.mp4"
  end

  # Returns a temporary presigned S3 download link
  def presigned_url_for(quality = nil, expires_in: 60)
    url = file_url_for(quality)
    return nil unless url

    s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    bucket = ENV["AWS_S3_BUCKET"]
    key = URI(url).path.sub(%r{^/}, "")

    obj = s3.bucket(bucket).object(key)
    obj.presigned_url(:get, expires_in: expires_in)
  rescue => e
    Rails.logger.error("Failed to generate presigned URL: #{e.message}")
    nil
  end

  private

  def valid_video_url
    unless url.match?(/\Ahttps:\/\/(www\.)?[\w-]+\.[\w-]+(\/.*)?\z/)
      errors.add(:url, "must be a valid HTTPS URL")
    end
  end
end
