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

	#set :enviroment, :development

    #configure :development do
    #    register Sinatra::Reloader
    #end	

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

	post '/hotel/:id/booking/?:format?' do
		request.body.rewind
		case params[:format]
		when 'csv'
			data = CSV.parse request.body.read
			data = data[0]
		else
			data = JSON.parse request.body.read
		end
		booking = Booking.new(hotelid: params[:id]) do |bk|
			bk.no      = data[0] unless data[0].nil?
			bk.bkg_sno = data[1] unless data[1].nil?
			bk.rsd_sno = data[2] unless data[2].nil?
			bk.atnd_by = data[3] unless data[3].nil?
			bk.bkd_by  = data[4] unless data[4].nil?
			bk.roomno  = data[5] unless data[5].nil?
			bk.date  = data[6] unless data[6].nil?
			bk.time  = data[7] unless data[7].nil?
		end					
		format = params[:format] || 'json'
		if booking.save
			eval "booking.to_#{format}" 
		else	
			eval "error 400, e.message.to_#{params[:format]}"
		end	
	end	

	get '/hotel/:id/bookings/from/:date/?:format?' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		bookings = Booking.all(conditions: {:date.gte => params[:date], hotelid: params[:id]})		
		format = params[:format] || 'json'
		eval "bookings.to_#{format}"
	end	

	not_found do
  		'Invalid Query'
	end
end	