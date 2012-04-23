class Access
	include Mongoid::Document

	field :key, type: String
	field :secret, type: String
	field :hotelid, type: String
	field :root, type: Boolean

	index :key, unique: true

	def to_csv
		[key, secret, hotelid, root].to_csv
	end	
end	

class Checkin
	include Mongoid::Document

	field :hotelid, type: String
	field :lfno, type: String
	field :in_date, type: Date
	field :in_time, type: String
	field :out_date, type: Date
	field :out_time, type: String
	field :roomno, type: String

	index( 
			[
				[ :hotelid, Mongo::ASCENDING],
				[ :lfno, Mongo::ASCENDING]
			], 
			unique: true
	)

	def to_csv
		[hotelid, lfno, in_date, in_time, out_date, out_time, roomno].to_csv
	end	

	def generate_allocations
		indt = Date.strptime(in_date, "%Y-%m-%d")
		oudt = Date.strptime(out_date, "%Y-%m-%d")
		indt.upto oudt do |day|
			RoomAllocation.create(hotelid: hotelid) do |ra|
				ra.roomno = roomno
				ra.resno = lfno
				ra.date = day
				ra.type = "Ckd"
				ra.intime = in_time
				ra.outtime = out_time
			end	
		end
	end		
end	

class RoomBlocked 
	include Mongoid::Document

	field :hotelid, type: String
	field :roomno, type: String
	field :date, type: Date

	index(
		[
			[ :hotelid, Mongo::ASCENDING],
			[ :roomno, Mongo::ASCENDING],
			[ :date, Mongo::ASCENDING]
		],
		unique: true
	)

	def to_csv
		[hotelid, roomno, date].to_csv
	end	

	def generate_allocations
		RoomAllocation.create(hotelid: hotelid) do |ra|
			ra.roomno = roomno
			ra.date = date
			ra.type = "Blk"
			ra.resno = roomno + 'BLK'
		end			
	end	
end	

class RoomAllocation
	include Mongoid::Document
	field :hotelid, type: String

	field :roomno, type: String
	field :date, type: Date
	field :type, type: String
	field :resno, type: String
	field :ressno, type: Integer
	field :intime, type: String
	field :outtime, type: String
	field :status, type: String
	field :local, type: Boolean


	index(
		[
			[ :hotelid, Mongo::ASCENDING],
			[ :roomno, Mongo::ASCENDING],
			[ :date, Mongo::ASCENDING]
		],
		unique: true
	)

	def to_csv
		[
			hotelid, roomno, date, type, resno, 
			ressno, intime,	outtime, status
		].to_csv
	end
end

class Booking
	include Mongoid::Document

	field :hotelid, type: String	
	field :no, type: String
	field :bkg_sno, type: String
	field :roomno, type: String
	field :cu_name, type: String	
	field :cont_no, type: String	
	field :email, type: String
	field :date, type: Date
	field :time, type: String
	field :in_date, type: String
	field :in_time, type: String
	field :out_date, type: String
	field :out_time, type: String
	field :status, type: String
	field :adult, type: Integer
	field :child, type: Integer
	field :tariff, type: Float
	field :plan, type: String
	field :incl_ind, type: String

	index(
		[
			[ :hotelid, Mongo::ASCENDING],			
			[ :no, Mongo::ASCENDING],
			[ :bkg_sno, Mongo::ASCENDING],
			[ :roomno, Mongo::ASCENDING]
		],
		unique: true	
	)

	def to_csv
		[
			hotelid, no, bkg_sno, roomno, cu_name,
			cont_no, email,	date, time, 
			in_date, in_time, out_date, out_time,
			status, adult, child, tariff, plan, incl_ind 
		].to_csv
	end	

	def generate_allocations(local = nil)
		indt = Date.strptime(in_date, "%Y-%m-%d")
		oudt = Date.strptime(out_date, "%Y-%m-%d")
		indt.upto oudt do |day|
			RoomAllocation.create(hotelid: hotelid) do |ra|
				ra.roomno = roomno
				ra.date = day
				ra.type = "Bkd"
				ra.resno = no
				ra.ressno = bkg_sno || 1
				ra.intime = in_time
				ra.outtime = out_time
				ra.status = status
				ra.local = local unless local.nil?
			end	
		end
	end	
end	