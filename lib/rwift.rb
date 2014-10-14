require "yaml"
require "thor"
require "fog"
require "find"
require "progressbar"
require "fileutils"

class Rwift < Thor
  VERSION = "0.0.2"

  attr_accessor :path

  desc "setup", "Setup Rwift: create a blank config file in ~/"
  def setup
    load_config
    if @new_config

    end
  end

  desc "list [CONTAINER]", "List containers or the contents of a specified container"
  def list(container = nil)
    response = service.directories
    if container.nil?
      response.each do |dir|
        message dir.key
      end
    else
      contents = response.get(container).files
      if contents.size == 0
        message "#{container} is empty"
      else
        contents.each do |f|
          message f.key
        end
      end
    end
  end

  desc "upload CONTAINER[:PATH] FILES|PATH", "Upload files to a container"
  def upload(container, *files)
    if files.size == 0
      message "Nothing specified to be uploaded."
      exit 1
    end

    container,self.path = container.split(':')
    self.path ||= ''

    dir = service.directories.get(container)
    if dir.nil?
      message "#{container} does not exist."
      exit 1
    else
      files.each do |f|
        filename = format_filename(f)
        if File.file?(f)
          unless files_match?(f, dir.files.head(filename))
            puts filename
            if File.size(f) < (1024 * 1000)
              dir.files.create(key: filename, body: File.open(f))
            else
              upload_file(container, f)
            end
          end
        elsif File.directory?(f)
          Find.find(f) do |path|
            if File.file?(path)
              path_file = format_filename(path)

              unless files_match?(path, dir.files.head(path_file))
                puts path_file
                if File.size(path) < (1024 * 1000)
                  dir.files.create(key: path_file, body: File.open(path))
                else
                  upload_file(container, path)
                end
              end
            end
          end
        end

      end
    end
  end

  desc "create CONTAINER", "Upload files to a container"
  def create(container)
    dirs = service.directories
    if dirs.get(container).nil?
      dirs.create(key: container)
    else
      message "#{container} already exists."
    end
  end

  desc "delete CONTAINER [FILES]", "Delete files from a container or the container itself."
  def delete(container, *files)
    dir = service.directories.get(container)
    if dir.nil?
      message "#{container} does not exist."
      exit 1
    end

    if files.size == 0
      if dir.files.size == 0
        message "#{container} deleted." if dir.destroy === true
      else
        message "#{container} must be empty first."
      end
    else
      files.each do |f|
        match = []
        dir.files.each do |df|
          match << df if df.key =~ /^#{f}$/
        end
        unless match.size == 0
          match.each do |m|
            message "#{container}:#{m.key} deleted." if m.destroy === true
          end
        else
          message "no file found matching #{f}"
        end
      end
    end

  end

  desc "download CONTAINER FILES", "Download files from a container"
  def download(container, *files)
    dir = service.directories.get(container)
    if dir.nil?
      message "#{container} does not exist."
      exit 1
    end

    if files.size == 0
      message "Specify at least one file to be dowloaded."
      exit 1
    else
      files.each do |f|
        match = []
        dir.files.each do |df|
          match << df if df.key =~ /^#{f}$/
        end
        unless match.size == 0
          match.each do |m|
            puts File.dirname(m.key)
          end
        else
          message "no file found matching #{f}"
        end
      end
    end


  end

  private
    def files_match?(local,remote)
      unless remote.nil?
        Digest::MD5.file(local).hexdigest == remote.etag
      else
        false
      end
    end

    def upload_file(container, path)
      begin
        filename = format_filename(path)
        f = File.open(path)
        pbar = ProgressBar.new('Uploading', f.size)
        pbar.file_transfer_mode
        service.put_object(container, filename, nil) do
          pbar.set(f.pos)
          if f.pos < f.size
            f.sysread(1024 * 4)
          else
            ""
          end
        end
      ensure
        f.close
        pbar.finish
      end
    end

    def simple_upload(container, file)
    end

    def format_filename(filename)
      filename.gsub(/^\//,'')
      if self.path
        self.path + '/' + filename
      else
        filename
      end
    end

    def message(txt)
      puts txt
    end

    def service
      fog_connect
    end

    def fog_connect
      load_config
      Fog::Storage.new({
        provider: 'Rackspace',
        rackspace_username: @config['username'],
        rackspace_api_key: @config['api_key'],
        rackspace_region: @config['region'],
        persistent: true
      })
    end

    def create_config_file
      File.open(config_file, File::RDWR|File::CREAT, 0640) {|f|
        f.flock(File::LOCK_EX)
        f.write("username:\napi_key:\nregion:")
        f.close
      }
      @new_config = true
    end

    def config_file
      config = File.join(Dir.home, '.rwift.yml')
      create_config_file unless File.exists?(config)
      config
    end

    def load_config
      @config = YAML.load_file(config_file)
    end

    def connect
      load_config
      puts @config
    end

end
