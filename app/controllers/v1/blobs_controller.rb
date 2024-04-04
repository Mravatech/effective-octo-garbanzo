module V1
  require 'base64'
  

  class BlobsController < ApplicationController

    def create
      id = blob_params[:id]
      data = blob_params[:data]
      storage_option = params[:storage_option].presence || 's3'
    
      # Attempt to decode the Base64 data
      begin
        decoded_data = Base64.strict_decode64(data)
      rescue ArgumentError => e
        render json: { error: 'Failed to decode Base64 data' }, status: :unprocessable_entity
        return
      end
    
      # Save the blob data based on the storage option
      if storage_option == 'local'
        save_locally(id, data, decoded_data)
      elsif storage_option == 's3'
        save_to_s3(id, data,decoded_data)
      end
    end

    def show
      # Find the blob by ID
      blob = Blob.find_by(id: params[:id])
  
      # Check if the blob exists
      if blob.nil?
        render json: { error: 'Blob not found' }, status: :not_found
        return
      end
  
      # Calculate size of the data in bytes
      size = blob.data.bytesize
  
      # Prepare response JSON
      response_json = {
        id: blob.id,
        data: blob.data,
        size: size,
        created_at: blob.created_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      }
  
      render json: response_json
    end
    
    
    private
    
    def save_locally(id, data, decoded_data)
      storage_directory = Rails.configuration.local_storage_directory
      file_path = File.join(storage_directory, id)
    
      begin
        File.open(file_path, 'wb') do |file|
          file.write(decoded_data)
        end
      rescue StandardError => e
        Rails.logger.error "Failed to save file locally: #{e.message}"
        return render json: { error: 'Failed to save file to local storage' }, status: :unprocessable_entity
      end
    
      insert_record(id, data, 'local')
    end
    
    def save_to_s3(id, data, decoded_data)
      s3_service = S3Service.new
      response = s3_service.upload_file(id, decoded_data)
    
      if response.code.to_i == 200
        insert_record(id, data, 's3')
      else
        render json: { error: 'Failed to upload blob to S3' }, status: :unprocessable_entity
      end
    end
    
    def insert_record(id, data, storage_type)
      begin
        Blob.create!(id: id, data: data, storage_type: storage_type)
        render json: { id: id }, status: :created
      rescue ActiveRecord::RecordNotUnique => e
        render json: { error: 'Blob with the same ID already exists' }, status: :unprocessable_entity
      end
    end

    
    def blob_params
      params.require(:blob).permit(:id, :data, :storage_option)
    end
  end
end
