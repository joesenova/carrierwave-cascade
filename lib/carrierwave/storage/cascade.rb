module CarrierWave
  module Storage
    class Cascade < Abstract
      attr_reader :primary_storage, :secondary_storage

      def initialize(*args)
        super(*args)

        @primary_storage    = get_storage(uploader.class.primary_storage).new(*args)
        @secondary_storage  = get_storage(uploader.class.secondary_storage).new(*args)
      end

      def store!(*args)
        primary_storage.store!(*args)
        secondary_storage.store!(*args)
      end

      def retrieve!(*args)
        primary_file = primary_storage.retrieve!(*args)
        
        # Remove secondary storage, and just return nil if file not exist
        if !primary_file.exists?
          #secondary_file = secondary_storage.retrieve!(*args)
          #if secondary_file.exists?
          #  uploader.cache! secondary_file
          #  file = CarrierWave::SanitizedFile.new(::File.expand_path(uploader.send(:cache_path), uploader.root))
          #  primary_storage.store!(file)
            # return SecondaryFileProxy.new(uploader, secondary_file)
          #else
          #  nil
          #end
          nil
        else
          return primary_file
        end
      end

      private

      def get_storage(storage = nil)
        storage.is_a?(Symbol) ? eval(uploader.storage_engines[storage]) : storage
      end

      class SecondaryFileProxy

        attr_reader :real_file

        def initialize(uploader, real_file)
          @uploader = uploader
          @real_file = real_file
        end
        
        def url
          real_file.url
        end

        def delete
          if true === @uploader.allow_secondary_file_deletion
            return real_file.delete
          else
            return true
          end
        end

        def method_missing(*args, &block)
          real_file.send(*args, &block)
        end

        def respond_to?(*args)
          @real_file.respond_to?(*args)
        end
      end

    end
  end
end
