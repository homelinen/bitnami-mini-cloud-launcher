require 'sinatra/base'
require 'haml'
require 'aws-sdk'
require 'dotenv'

require './db.rb'

class SinatraBootstrap < Sinatra::Base
    set :template, :layout
    set :dotenv, Dotenv.load

    use Rack::Session::Cookie, 
                           :path => '/',
                           :expire_after => 2592000, # In seconds
                           :secret => dotenv['SESSION_SECRET']

    # TODO: Generate a list of available AMIs
    set :ami, 'ami-54cd3b23' 

    set :aws, { access_key: dotenv['AWS_ACCESS_KEY'] }

    set :db, Database.new.connect()

    def setup_ec2(access_key, secret_key)
        ec2 = AWS::EC2.new(
            access_key_id: access_key, 
            secret_access_key: secret_key, 
            ec2_endpoint: 'ec2.us-west-1.amazonaws.com')

        # Test for Auth Failures
        begin
            ec2.instances.first
        rescue AWS::EC2::Errors::AuthFailure
            ec2 = nil
        end

        return ec2
    end

    get '/' do
        haml :index
    end

    post '/submit' do
        access_key = params['aws_access_key'].strip
        secret_key = params['aws_secret_key'].strip

        # TODO: Get key from entry
        ec2 = setup_ec2(access_key, secret_key)

        session['access_key'] = access_key
        session['secret_key'] = secret_key

        redirect to ('/') unless ec2

        instance = ec2.instances.create(
            image_id: 'ami-e4625fa1',
            count: 1,
            instance_type: 't1.micro'
        )

        #instance = { id: 'i-777777', dns_name: 'http://example.com' }

        session[:instance] = instance.id
        session[:instance_url] = instance.dns_name

        redirect to ('/summary')
    end

    get '/summary' do
        if not session[:access_key]
            redirect to ('/')
        end

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        instance = ec2.instances[session[:instance]]

        instance_url = instance.dns_name

        haml :summary, locals: { instance_id: instance.id, instance_url: instance_url, instance_status: instance.status }
    end

    get '/stop' do
        if not session[:access_key]
            redirect to ('/')
        end

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        instance_id = session[:instance]

        ec2.instances[instance_id].stop

        redirect to ('/summary')
    end

    get '/start' do
        if not session[:access_key]
            redirect to ('/')
        end

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        instance_id = session[:instance]

        ec2.instances[instance_id].start

        redirect to ('/summary')
    end

    get '/stylesheets/application.css' do

        sass :application, :content_type => 'text/css; charset=utf-8'
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
end
