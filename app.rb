require 'sinatra/base'
require 'aws-sdk'
require 'dotenv'

require 'haml'
require 'redcarpet'
require 'sass'

class SinatraBootstrap < Sinatra::Base
    set :template, :layout
    set :dotenv, Dotenv.load

    use Rack::Session::Cookie, 
                           :path => '/',
                           :expire_after => 2592000, # In seconds
                           :secret => dotenv['SESSION_SECRET']

    # TODO: Generate a list of available AMIs

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

        redirect to ('/') unless ec2

        session['access_key'] = access_key
        session['secret_key'] = secret_key

        redirect to ('/summary')
    end

    get '/new' do
        redirect to ('/') unless session[:access_key]

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        sg = nil

        # Create a security group if needed
        ec2.security_groups.filter('group-name', 'cloud-launcher-wordpress').each { |security_group| sg=security_group; break }
        
        unless sg 
          sg = ec2.security_groups.create('cloud-launcher-wordpress')
          sg.authorize_ingress(:tcp, 80)
        end

        # Generate a single instance
        # TODO: Allow a dropdown for size and AMI
        instance = ec2.instances.create(
            image_id: 'ami-e4625fa1',
            count: 1,
            instance_type: 't1.micro',
            security_groups: sg.name
        )

        instance.tag('cloud-launcher')

        redirect to('/summary')
    end

    # Display the summary of instances
    # 
    # TODO: Grab instances from a database or the account itself
    get '/summary' do
        redirect to ('/') unless session[:access_key]

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        instances = ec2.instances.tagged('cloud-launcher')

        haml :summary, locals: { instances: instances }
    end

    post %r{start|stop} do |action|
        redirect to ('/') unless session[:access_key]

        ec2 = setup_ec2(session[:access_key], session[:secret_key]) 

        instance_id = params[:instance_id]
        redirect to ('/') unless ec2.instances[instance_id]

        if action == "stop"
          ec2.instances[instance_id].stop
        elsif action == "start"
          ec2.instances[instance_id].start
        end

        redirect to ('/summary')
    end

    get '/signout' do
        session.clear

        redirect to('/')
    end

    get '/stylesheets/application.css' do
        sass :application, :content_type => 'text/css; charset=utf-8'
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
end
