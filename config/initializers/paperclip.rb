module Paperclip
  class Attachment
    def clear_processed!
      return unless file?
      @queued_for_delete += [*styles.keys].uniq.map do |style|
        path(style) if exists?(style)
      end.compact
      instance_write(:processing, true)
      instance_write(:updated_at, Time.now)
      save
      instance.save!
    end

    unless Rails.env.production? || ENV["PAPERCLIP_USE_ENV"]
      def url_with_production style_name = default_style, include_updated_timestamp = true
        src = url_without_production(style_name, include_updated_timestamp)
        return gsub_production(src)
      end
      alias_method_chain :url, :production

      def url_without_processed_with_production style_name = default_style, include_updated_timestamp = true
        src = url_without_processed_without_production(style_name, include_updated_timestamp)
        return gsub_production(src)
      end
      alias_method_chain :url_without_processed, :production
    end

    def gsub_production(src)
      if src.match(/photos\./)
        src.gsub!(/#{Rails.env}/, 'production')
      end
      src
    end
  end

  # Handles thumbnailing images that are uploaded.
  class Jcropper < Thumbnail

    def transformation_command
      if crop_command
        crop_command + super
      else
        super
      end
    end

    def crop_command
      target = @attachment.instance
      if target.cropping?
        commands = []
        if target.crop.x.present?
          geometry = Paperclip::Geometry.from_file(@file)
          scale = [geometry.height, geometry.width].max / 300
          commands << ["-crop",
          "#{target.crop.w.to_i * scale}x#{target.crop.h.to_i * scale}+#{target.crop.x.to_i * scale}+#{target.crop.y.to_i * scale}"
          ]
        end

        if target.crop.rotation != 0
          commands << ["-rotate", target.crop.rotation.to_s]
        end
        commands
      end
    end

  end

end
