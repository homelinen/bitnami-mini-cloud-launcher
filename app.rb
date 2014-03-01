require 'sinatra/base'
require 'haml'

require 'aws-sdk'

class SinatraBootstrap < Sinatra::Base
    set :template, :layout

    get '/' do
        haml :index
    end

    get '/submit' do

    end

    get '/summary' do

    end

    # start the server if ruby file executed directly
    run! if app_file == $0
end
