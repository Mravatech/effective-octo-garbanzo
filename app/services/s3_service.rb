require 'net/http'
require 'uri'
require 'base64'
require 'digest'
require 'openssl'
require 'dotenv/load'



class S3Service
  def initialize
    @bucket_name = ENV['S3_BUCKET_NAME']
    @access_key_id = ENV['S3_ACCESS_KEY_ID']
    @secret_key = ENV['S3_SECRET_KEY']
    @region = ENV['S3_REGION']
    @endpoint = ENV['S3_ENDPOINT']
  end

  def upload_file(file_name, file_content)
    headers = get_headers(file_name, file_content)
    do_upload(file_name, file_content, headers)
  end

  private

  def get_headers(file_name, file_content)
    filesize = file_content.length
    long_date = Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
    short_date = Time.now.utc.strftime('%Y%m%d')

    headers = {
      'Content-Length' => filesize.to_s,
      'Host' => @endpoint,
      'x-amz-date' => long_date,
      'x-amz-content-sha256' => Digest::SHA256.hexdigest(file_content)
    }

    headers['Authorization'] = generate_signature(file_name, file_content, long_date, short_date)

    headers
  end

  def generate_signature(file_name, file_content, long_date, short_date)
    canonical_request = generate_canonical_request(file_name, file_content, long_date)
    string_to_sign = generate_string_to_sign(canonical_request, long_date, short_date)
    signing_key = generate_signing_key(short_date)
    signature = OpenSSL::HMAC.hexdigest('sha256', signing_key, string_to_sign)

    "AWS4-HMAC-SHA256 Credential=#{@access_key_id}/#{short_date}/#{@region}/s3/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature=#{signature}"
  end

  def generate_canonical_request(file_name, file_content, long_date)
    filesize = file_content.length
    canonical_request = "PUT\n/#{file_name}\n\ncontent-length:#{filesize}\nhost:#{@endpoint}\nx-amz-content-sha256:#{Digest::SHA256.hexdigest(file_content)}\nx-amz-date:#{long_date}\n\ncontent-length;host;x-amz-content-sha256;x-amz-date\n#{Digest::SHA256.hexdigest(file_content)}"
  end

  def generate_string_to_sign(canonical_request, long_date, short_date)
    "AWS4-HMAC-SHA256\n#{long_date}\n#{short_date}/#{@region}/s3/aws4_request\n#{Digest::SHA256.hexdigest(canonical_request)}"
  end

  def generate_signing_key(short_date)
    signing_key = OpenSSL::HMAC.digest('sha256', "AWS4#{@secret_key}", short_date)
    signing_key = OpenSSL::HMAC.digest('sha256', signing_key, @region)
    signing_key = OpenSSL::HMAC.digest('sha256', signing_key, 's3')
    OpenSSL::HMAC.digest('sha256', signing_key, 'aws4_request')
  end

  def do_upload(file_name, file_content, headers)
    newfile = URI.encode_www_form_component(file_name)
    url = URI("https://#{@endpoint}/#{newfile}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(url.request_uri, headers)
    request.body = file_content

    response = http.request(request)

    puts "File uploaded successfully"
    response
  end
end
