class Blob < ApplicationRecord
    validates :data, presence: true

    def decoded_data
      Base64.decode64(data)
    end
end
