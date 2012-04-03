require 'rubygems'
require 'sinatra/base'
require 'sinatra/rabbit'
require 'mongoid'
require 'csv'
require 'date'
require 'logger'

require File.expand_path(File.dirname(__FILE__) + '/models/db_mongo')

#Mongoid.load!("config/mongoid.yml")
Mongoid.configure do |config|
	if ENV['MONGOHQ_URL']
	  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
	  uri = URI.parse(ENV['MONGOHQ_URL'])
	  config.master = conn.db(uri.path.gsub(/^\//, ''))
	else
	  config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('checkinn_development')
	end
 end


class CheckinnApi < Sinatra::Base
	
	include Sinatra::Rabbit

    configure :development, :test do
    	require 'sinatra/reloader'
        register Sinatra::Reloader
        enable :logging
    end	

	get '/' do
		haml :index		
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
		err_msg = []
		request.body.rewind
		case params[:format]
		when 'csv'
			csv = ''
			data = CSV.parse request.body.read
		else
			data = JSON.parse request.body.read
		end
		data.each do |row|
			booking = Booking.new(hotelid: params[:id]) do |bk|
				bk.no      = row[0] unless row[0].nil?
				bk.bkg_sno = row[1] unless row[1].nil?
				bk.rsd_sno = row[2] unless row[2].nil?
				bk.atnd_by = row[3] unless row[3].nil?
				bk.bkd_by  = row[4] unless row[4].nil?
				bk.roomno  = row[5] unless row[5].nil?
				bk.date  = row[6] unless row[6].nil?
				bk.time  = row[7] unless row[7].nil?
				bk.in_date  = row[8] unless row[8].nil?
				bk.in_time  = row[9] unless row[9].nil?
				bk.out_date  = row[10] unless row[10].nil?
				bk.out_time  = row[11] unless row[11].nil?
			end				
			if booking.save
				booking.generate_allocations
				eval "#{params[:format]} = #{params[:format]} + booking.to_#{params[:format]}" 
			else	
				err_msg.push e.message
				break
			end				
		end	
		format = params[:format] || 'json'
		if err_msg.empty?
			eval "#{params[:format]}"	
		else
			eval "error 400, err_msg.to_#{params[:format]}"			
		end	
	end	

	get '/hotel/:id/booking/from/:date/?:format?' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		bookings = Booking.all_of(:date.gte => params[:date], hotelid: params[:id])
		case params[:format]
		when 'csv'	
			csv = ''
			bookings.each {|b|	csv= csv << b.to_csv}
		else
			json = []
			bookings.each {|b|	json.push b.to_json :except => :_id }
			json = json.to_json
		end	
		format = params[:format] || 'json'
		eval "#{format}"
	end	

	not_found do
  		'Invalid Query'
	end
end	