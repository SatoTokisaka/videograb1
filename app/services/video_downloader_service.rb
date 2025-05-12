def download(output_path, quality: "best")
  format = case quality
  when "720p" then "bestvideo[height<=720]+bestaudio/best[height<=720]"
  when "480p" then "bestvideo[height<=480]+bestaudio/best[height<=480]"
  else             "bestvideo+bestaudio/best"
  end

  command = [
    "yt-dlp", "-f", format,
    "-o", output_path.to_s,
    @url
  ]

  success = system(*command)
  raise "yt-dlp failed to download video" unless success
end
