def file_upload_fixture(path, mime_type = nil, binary = false)
  Rack::Test::UploadedFile.new("#{fixture_path}/#{path}", mime_type, binary)
end
