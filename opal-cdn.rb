require 'sinatra'
require 'pathname'

class Pathname
  alias to_str to_s
end

class OpalVersion < Struct.new(:version)
  def initialize *args
    super
    install_dir.mkpath
  end

  def [] name
    path = build_dir.join('build', name)
    build! unless path.exist?
    path.read
  end

  def build_dir
    install_dir.join("opal-#{version}")
  end

  def install_dir
    Pathname(__dir__).join('tmp')
  end

  def build!
    system('gem', 'unpack', 'opal', '--version', version, '--target', install_dir)
    puts 'chdir', build_dir
    Dir.chdir(build_dir) do
      system('rake', 'dist')
    end
  end

  def self.find version
    @versions ||= {}
    @versions[version] ||= new(version)
  end
end

get '/opal/:opal_version/:file_name' do
  ver = OpalVersion.find(params[:opal_version])
  stream do |out|
    # Keep heroku alive
    thread = Thread.new { out << ' ' }
    out << ver[params[:file_name]]
    thread.join
  end
end

get '/' do
  <<-HTML
  <!doctype html>
  <html>
  <head>
    <title>Opal autobuilder</title>
  </head>
  <body>
    <header>
      <h1>Opal autobuilder</h1>
    </header>

    <article>
      path template: /opal/:version/:file_name
      <br>
      E.g. <a href="/opal/0.4.4/opal.js">/opal/0.4.4/opal.js</a>
    </article>

    <footer>
      © 2013 Elia Schito - MIT License
    </footer>
  </body>
  </html>
  HTML
end
