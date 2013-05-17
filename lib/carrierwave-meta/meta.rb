module CarrierWave
  module Meta
    extend ActiveSupport::Concern

    included do
      include CarrierWave::ModelDelegateAttribute
      include CarrierWave::MimeTypes

      set_content_type(true)

      after :retrieve_from_cache, :set_content_type
      after :retrieve_from_cache, :call_store_meta
      after :retrieve_from_store, :set_content_type
      after :retrieve_from_store, :call_store_meta

      model_delegate_attribute :content_type, ''
      model_delegate_attribute :file_size, 0
      model_delegate_attribute :image_size, []
      model_delegate_attribute :width, 0
      model_delegate_attribute :height, 0
      model_delegate_attribute :density, ''
      model_delegate_attribute :md5sum, ''
    end

    def store_meta
      if self.file.present?
        dimensions = get_dimensions
        width, height = dimensions

        self.density = get_density
        self.content_type = self.file.content_type
        self.file_size = self.file.size
        self.image_size = dimensions
        self.width = width
        self.height = height
        self.md5sum = Digest::MD5.hexdigest(File.read(self.file.path))
      end
    end

    def set_content_type(file = nil)
      set_content_type(true)
    end

    def image_size_s
      image_size.join('x')
    end

    private
    def call_store_meta(file = nil)
      # Re-retrieve metadata for a file only if model is not present OR model is not saved.
      store_meta if self.model.nil? || (self.model.respond_to?(:new_record?) && self.model.new_record?)
    end

    def get_density
      density_x_and_unit, density_y_and_unit = `identify -format "%yx%y" #{self.file.path}`.split('x')
      density_x, _ = density_x_and_unit.split(' ')
      density_y, _ = density_y_and_unit.split(' ')

      density_x = 72 if density_x == 0
      density_y = 72 if density_y == 0

      return [density_x, density_y].join('x')
    end

    def get_dimensions
      [].tap do |size|
        if self.file.content_type =~ /image|postscript|pdf/
          width, height = `identify -format "%wx%h" #{self.file.path}`.split('x')
          size << width
          size << height
        end
      end
    rescue CarrierWave::ProcessingError
    end
  end
end