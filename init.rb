require 'rubygems'
require 'sinatra/base'
require 'sinatra/rabbit'
require 'mongoid'
require 'csv'
require 'date'
require 'logger'
require 'openssl'

require File.expand_path(File.dirname(__FILE__) + '/models/db_mongo')

#Mongoid.load!("config/mongoid.yml")
Mongoid.configure do |config|
	if ENV['MONGOHQ_URL']
	  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
	  uri = URI.parse(ENV['MONGOHQ_URL'])
	  config.master = conn.db(uri.path.gsub(/^\//, ''))
	  config.autocreate_indexes = true
	else
	  config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('checkinn_development')
	  config.autocreate_indexes = true
	end
 end

#$LOG = Logger.new('log_file.txt')  

class CheckinnApi < Sinatra::Base
	
	include Sinatra::Rabbit

    configure :development, :test do
    	require 'sinatra/reloader'
        register Sinatra::Reloader
        enable :logging, :dump_errors, :raise_errors
    end	

    def authenticate!
    	return false if params[:akey].nil? || params[:atoken].nil? || params[:atimestamp].nil?
		return false if params[:atimestamp].to_i < Time.now.getutc.to_i - 300 || params[:atimestamp].to_i > Time.now.getutc.to_i   		
    	return false unless access = Access.first(conditions: {key: params[:akey]})
    	digest = OpenSSL::Digest::Digest.new('sha1')
    	token = OpenSSL::HMAC.hexdigest(digest, access.secret, [access.key, params[:atimestamp]].to_csv)
    	#$LOG.debug "Token: #{token}"
    	#$LOG.debug "Atoken: #{params[:atoken]}"
    	return false unless token == params[:atoken]
    	true
    end	

	before do
		#begin	
			next if request.path_info != '/access/1234567890' 		
			halt 401, 'Auth Failed' unless authenticate!
		#rescue Exception => e
		#	$LOG.fatal e
		#end
	end	

	get '/' do
		haml :index		
	end

	collection :access do
		description "Colletion of API accesses"

		operation :index do
	      description "List of All Accesses"
	      control do
	      	csv = ''
	        accesses = Access.all 
	        accesses.each {|ac|	csv= csv << ac.to_csv}	
	        csv
	      end
	    end

		operation :create do
			description "Create new API access"
			param :key,  :string, :required
			param :secret,  :string, :required
			param :hotelid,  :string
			param :root, :boolean
			control do
				access = Access.new(key: params[:key], secret: params[:secret]) do |ac|
					ac.hotelid = params[:hotelid] unless params[:hotelid].nil?
					ac.root = params[:root] || false
				end	
				if access.save
					access.key
				else
					error 400, e.message	
				end	
			end	
		end	

		operation :show do
			description "Display details of access"
			param :id,  :integer, :required
			control do
				access = Access.first(conditions: {key: params[:id]})
				access.to_csv
			end	
		end	

		operation :destroy do
			description "Delete access"
      		param :key, :string, :required
      		control do
        		Access.destroy!(params[:key])
        		halt [410, "Access deleted"]
		    end			
		end	
	end	


	get '/hotel/:id/room/:roomno/status/:date' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Room No' unless params[:roomno].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		if RoomAllocation.exists?(conditions: {hotelid: params[:id], roomno: params[:roomno], date: params[:date]})
			'busy'
		else
			'free'
		end
	end	

	get '/hotel/:id/room/?:roomno?/allocation/:date' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Room No' unless params[:roomno].nil? || params[:roomno].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:date] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		if params[:roomno]
			allocation = RoomAllocation.first(conditions: {hotelid: params[:id], roomno: params[:roomno], date: params[:date]})
			allocation.to_csv unless allocation.nil?
		else
			csv = ''
			allocations = RoomAllocation.all_of(date: params[:date], hotelid: params[:id])
			allocations.each {|a|	csv= csv << a.to_csv}	
			csv
		end	
	end		

	post '/hotel/:id/checkin' do

		RoomAllocation.destroy_all(conditions: {hotelid: params[:id], type: "Ckd"})

		err_msg = []
		csv = ''
		request.body.rewind
		data = CSV.parse request.body.read
		data.each do |row|
			checkin = Checkin.new(hotelid: params[:id]) do |ch|
				ch.lfno = row[0] unless row[0].nil?
				ch.in_date = row[1] unless row[1].nil?
				ch.in_time = row[2] unless row[2].nil?
				ch.out_date = row[3] unless row[3].nil?
				ch.out_time = row[4] unless row[4].nil?
				ch.roomno = row[5] unless row[5].nil?
			end	
			if checkin.save
				checkin.generate_allocations
				csv = csv + checkin.to_csv
			else
				err_msg.push e.message
				break
			end	
		end		
		if err_msg.empty?
			csv
		else
			error 400, err_msg.to_csv
		end	
	end	

	post '/hotel/:id/blocked' do

		RoomAllocation.destroy_all(conditions: {hotelid: params[:id], type: "Blk"})

		err_msg = []
		csv = ''
		request.body.rewind
		data = CSV.parse request.body.read
		data.each do |row|
			roomblocked = RoomBlocked.new(hotelid: params[:id]) do |rb|
				rb.roomno = row[0] unless row[0].nil?
				rb.date = row[1] unless row[1].nil?
			end	
			if roomblocked.save
				roomblocked.generate_allocations
				csv = csv + roomblocked.to_csv
			else	
				err_msg.push e.message
				break
			end				
		end
		if err_msg.empty?
			csv
		else
			error 400, err_msg.to_csv
		end	
	end	

	post '/hotel/:id/booking/?:local?' do

		RoomAllocation.destroy_all(conditions: {hotelid: params[:id], type: "Bkd", local: true}) unless params[:local].nil?

		err_msg = []
		request.body.rewind
		csv = ''
		data = CSV.parse request.body.read
		data.each do |row|
			booking = Booking.new(hotelid: params[:id]) do |bk|
				if params[:local].nil?
					bk.no      = row[0] unless row[0].nil?
					bk.bkg_sno = row[1] unless row[1].nil?
					bk.roomno  = row[2] unless row[2].nil?
					bk.cu_name  = row[3] unless row[3].nil?
					bk.cont_no  = row[4] unless row[4].nil?
					bk.email  = row[5] unless row[5].nil?
					bk.date  = row[6] unless row[6].nil?
					bk.time  = row[7] unless row[7].nil?
					bk.in_date  = row[8] unless row[8].nil?
					bk.in_time  = row[9] unless row[9].nil?
					bk.out_date  = row[10] unless row[10].nil?
					bk.out_time  = row[11] unless row[11].nil?
					bk.status  = row[12] unless row[12].nil?
					bk.adult  = row[13] unless row[13].nil?
					bk.child  = row[14] unless row[14].nil?
					bk.tariff  = row[15] unless row[15].nil?
					bk.plan  = row[16] unless row[16].nil?
					bk.incl_ind  = row[17] unless row[17].nil?
				else
					bk.no = row[0] unless row[0].nil?
					bk.roomno = row[1] unless row[1].nil?
					bk.in_date = row[2] unless row[2].nil?
					bk.in_time = row[3] unless row[3].nil?
					bk.out_date = row[4] unless row[4].nil?
					bk.out_time = row[5] unless row[5].nil?
					bk.status = row[6] unless row[6].nil?
				end	
			end				
			if params[:local] || booking.save
				booking.generate_allocations(params[:local])
				csv = csv + booking.to_csv
			else	
				err_msg.push e.message
				break
			end				
		end	
		if err_msg.empty?
			csv	
		else
			error 400, err_msg
		end	
	end	

	get '/hotel/:id/booking/:from/?:to?' do
		halt 400, 'Invalid Hotel ID' unless params[:id].to_i > 0
		halt 400, 'Invalid Date Format' unless params[:from] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		halt 400, 'Invalid Date Format' unless params[:to].nil? || params[:to] =~ (/\d{4}-\d{1,2}-\d{1,2}/)
		if params[:to]
			bookings = Booking.all_of(:date.gte => params[:from], :date.lte => params[:to], hotelid: params[:id])
		else
			bookings = Booking.all_of(:date.gte => params[:from], hotelid: params[:id])
		end	
		csv = ''
		bookings.each {|b|	csv= csv << b.to_csv}
		csv
	end	

	not_found do
  		'Invalid Query'
	end
end	