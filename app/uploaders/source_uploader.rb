# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class SourceUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  include CarrierWave::MiniMagick
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  #for multiple upload pdf.

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :grid_fs
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #  "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  # end
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  #process :resize_to_limit => [816, 1056]  if :multi?
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end
  # Create different versions of your uploaded files:
  #process :resize_to_fit => [800, 800]
  version :thumb do
    process :cropping=>[115,168]
   (process :convert => 'png') if :pdf?
  end

  version :bw_pdf do
    #"A4" => [595.28, 841.89],

      process cropping: [575,820]
      process :three_hundred_dpi
      process :remove_color
      process :convert_to_pdf
      process :set_content_type
      def full_filename (for_file = model.source.file)
        super.chomp(File.extname(super)) + '.pdf'
      end


  end

  version :converted_pdf ,if: :image? do
    #"A4" => [595.28, 841.89],
    process cropping:  [575,820]
    process :three_hundred_dpi
    process :convert_to_pdf
    process :set_content_type
    def full_filename (for_file = model.source.file)
      super.chomp(File.extname(super)) + '.pdf'
    end
  end





  def cropping(w,h)
    manipulate! do |image|
      w_original = image[:width].to_f
      h_original = image[:height].to_f
      if w_original < w && h_original < h
        return image
      end
      # resize
      image.resize("#{w}x#{h}")
      image
    end
  end



  def set_content_type(*args)
    self.file.instance_variable_set(:@content_type, "application/pdf")
  end


  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    asset_path("fallback/" + [version_name, "default-photo.png"].compact.join('_'))
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png pdf)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  protected
  def pdf?(new_file)
    new_file.content_type.include? 'pdf'
  end

  def image?(new_file)
    new_file.content_type.include? 'image'
  end

  def remove_color
    manipulate! do |img|
      #img.threshold('50%')
      img.monochrome
      img
    end
  end

  def three_hundred_dpi
    manipulate! do |img|
      img.density(300)
      #img.monochrome
      img
    end
  end



  def convert_to_pdf
    require 'prawn'
    cached_stored_file! if !cached?
    pdf = Prawn::Document.new(page_layout: :portrait,
                              page_size: 'A4',
                              :left_margin => 10,
                              :right_margin => 10,
                              :top_margin => 10,
                              :bottom_margin => 10
    )
    #pdf.image(current_path)
    pdf.image current_path ,position: :center
    dirname = File.dirname(current_path)
    thumb_path = "#{File.join(dirname, File.basename(path, File.extname(path)))}.pdf"
    pdf.render_file(thumb_path)
    File.rename thumb_path, current_path
  end


end
