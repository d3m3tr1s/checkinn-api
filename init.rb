require 'rubygems'
require 'sinatra/base'
require 'sinatra/rabbit'
require 'sinatra/reloader'
require 'mongoid'
require 'csv'
require 'date'

require File.expand_path(File.dirname(__FILE__) + '/models/db_mongo')
Mongoid.load!("config/mongoid.yml")

class CheckinnApi < Sinatra::Base
	
	include Sinatra::Rabbit

	set :enviroment, :development

    configure :development do
        register Sinatra::Reloader
    end	

	get '/' do
		haml :index		
	end

	get '/generate' do
		allocation = RoomAllocation.find_or_create_by(
			hotelid: 1, 
			roomno: 1, 
			date: Date.today.to_s,
			type: "Bkd",
			resno: 'WEB0000001',
			ressno: 2,
			rsdsno: 2
		)
		allocation.to_csv
	end	

	get '/hotel/:id/room/:roomno/status/on/:date' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Room No' unless params[:roomno].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		if RoomAllocation.exists?(conditions: {hotelid: params[:id], roomno: params[:roomno], date: params[:date]})
			'busy'
		else
			'free'
		end
	end	

	get '/hotel/:id/room/:roomno/allocation/on/:date' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Room No' unless params[:roomno].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		allocation = RoomAllocation.first(conditions: {hotelid: params[:id], roomno: params[:roomno], date: params[:date]})
		allocation.to_csv unless allocation.nil?
	end		

	not_found do
  		'Invalid Query'
	end

end	