class File

  def self.mime_type(path)
    `file --brief --mime-type #{path}`.strip
  end

  def self.charset(path)
    `file --brief --mime #{path}`.split(';').second.split('=').second.strip
  end

end